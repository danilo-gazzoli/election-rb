# frozen_string_literal: true

require 'rails_helper'
require 'digest'

RSpec.describe 'API v1 voting flow', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'flow-school', name: 'Flow School') }
  let(:worker) do
    User.create!(school_installation: installation, name: 'Worker', login: 'worker',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'A school election for the voting API test',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:round_contest) { RoundContest.create!(round: round, contest: contest) }
  let!(:first_stage) do
    VotingStage.create!(round: round, round_contest: round_contest, global_position: 1, choice_index: 1)
  end
  let!(:second_stage) do
    VotingStage.create!(round: round, round_contest: round_contest, global_position: 2, choice_index: 2)
  end
  let(:party) { Party.create!(name: 'Flow Test Party', abbreviation: 'FTP', party_number: 59) }
  let(:candidate) do
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '59')
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate A'),
                      principal_party: party, ballot_number: '591')
  end
  let(:other_candidate) do
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate B'),
                      principal_party: party, ballot_number: '592')
  end
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Device A',
                         credential_digest: VotingDevice.digest_credential('device-secret'), state: 'locked')
  end

  before do
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    RoundCandidacy.create!(round: round, candidacy: candidate)
    RoundCandidacy.create!(round: round, candidacy: other_candidate)
    first_stage
    second_stage
    ballot = Voting::BallotConfiguration.call(round: round).fetch(:ballot)
    ConfigurationSnapshot.create!(round: round, version: election.configuration_version,
                                  canonical_data: ballot, digest: Digest::SHA256.hexdigest(JSON.generate(ballot)),
                                  created_at: Time.current)
    round.update!(state: 'open')
    device
  end

  it 'lets the voter correct a repeated second choice after the warning' do
    post '/api/v1/auth/login', params: { login: worker.login, password: 'long-random-password' }, as: :json
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id, command_key: 'release-command' }, as: :json
    device.update!(pairing_code_digest: VotingDevice.digest_credential('pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'pair-code' }, as: :json

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'cmd-1',
                   kind: 'nominal', candidacy_id: candidate.id }, as: :json
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'cmd-2',
                   kind: 'nominal', candidacy_id: candidate.id }, as: :json
    expect(response.parsed_body.dig('error', 'code')).to eq('choice_warning')

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'cmd-2',
                   kind: 'nominal', candidacy_id: other_candidate.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(CastVote.where(kind: 'nominal').pluck(:candidacy_id)).to match_array([candidate.id, other_candidate.id])
    expect(ConfirmationReceipt.count).to eq(2)
    expect(VotingSession.last.first_choice_fingerprint).to be_nil
  end

  it 'releases through the worker and confirms through the paired device' do
    post '/api/v1/auth/login', params: { login: 'worker', password: 'long-random-password' }, as: :json
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id, command_key: 'release-command' }, as: :json
    expect(response).to have_http_status(:ok)

    device.update!(pairing_code_digest: VotingDevice.digest_credential('pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'pair-code' }, as: :json
    expect(response).to have_http_status(:ok)

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'cmd-1',
                   kind: 'nominal', candidacy_id: candidate.id }, as: :json
    expect(response).to have_http_status(:ok)
    receipt_id = response.parsed_body.fetch('receipt_id')
    expect(receipt_id).to be_present

    get '/api/v1/voting-device/state'
    expect(response.parsed_body.fetch('last_receipt_id')).to eq(receipt_id)
    expect(response.parsed_body.to_s).not_to include('first_choice_fingerprint')

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'cmd-1',
                   kind: 'nominal', candidacy_id: candidate.id }, as: :json
    expect(response.parsed_body.fetch('receipt_id')).to eq(receipt_id)
    expect(CastVote.count).to eq(1)

    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('contests').first.fetch('nominal_votes')).to eq(1)
    expect(response.parsed_body.to_s).not_to include(device.public_label)

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'cmd-2', kind: 'nominal',
                   candidacy_id: candidate.id }, as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('choice_warning')
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'cmd-2', kind: 'nominal',
                   candidacy_id: candidate.id, warning_acknowledged: true }, as: :json
    final_receipt = response.parsed_body.fetch('receipt_id')
    expect(CastVote.order(:kind).pluck(:kind)).to eq(%w[nominal null])
    get '/api/v1/voting-device/state'
    expect(response.parsed_body.fetch('state')).to eq('locked')
    expect(response.parsed_body.fetch('last_receipt_id')).to eq(final_receipt)

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'cmd-2', kind: 'nominal',
                   candidacy_id: candidate.id, warning_acknowledged: true }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('receipt_id')).to eq(final_receipt)
    expect(CastVote.count).to eq(2)
    expect(ConfirmationReceipt.count).to eq(2)
  end

  it 'abandons only the remaining stage without exposing the first choice to the pollworker' do
    post '/api/v1/auth/login', params: { login: worker.login, password: 'long-random-password' }, as: :json
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id, command_key: 'release-command' }, as: :json
    session_id = response.parsed_body.fetch('session_id')

    device.update!(pairing_code_digest: VotingDevice.digest_credential('pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'pair-code' }, as: :json
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'cmd-1',
                   kind: 'nominal', candidacy_id: candidate.id }, as: :json
    expect(VotingSession.find(session_id).first_choice_fingerprint).to be_present

    post "/api/v1/pollworker/sessions/#{session_id}/abandon", params: { reason: 'voter left' }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('session_id' => session_id, 'state' => 'abandoned')
    expect(VotingSession.find(session_id).first_choice_fingerprint).to be_nil
    expect(CastVote.order(:voting_stage_id).pluck(:kind, :origin)).to eq(
      [['nominal', 'confirmation'], ['null', 'abandonment']]
    )
  end
end
