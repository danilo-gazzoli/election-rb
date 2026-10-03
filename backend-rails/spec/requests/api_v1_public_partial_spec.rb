# frozen_string_literal: true

require 'rails_helper'

# ERS RF-36/RF-38 and CA-09: anonymous aggregate access, never an individual vote trail.
RSpec.describe 'API v1 public partial results', type: :request do
  include_context 'an opened school voting round'

  def consult(target = election)
    get "/api/v1/public/elections/#{target.id}/partial"
  end

  def result
    response.parsed_body.fetch('contests').first
  end

  def operational_counts
    [VotingSession.count, CastVote.count, ConfirmationReceipt.count, Incident.count,
     AuditEvent.count, TallyRun.count]
  end

  it 'allows anonymous access and returns null percentages instead of zero percent without valid votes' do
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('status' => 'partial', 'round_number' => 1)
    expect(result).to include('participation' => 0, 'confirmations' => 0, 'total_votes' => 0)
    expect(result.fetch('candidates').map { |candidate| candidate.fetch('percentage') }).to eq([nil, nil])
  end

  it 'identifies each candidacy using the name and ballot number preserved in the opened snapshot' do
    frozen_contest = ConfigurationSnapshot.find_by!(round: round).canonical_data.fetch('contests').first
    consult
    expect(response).to have_http_status(:ok)
    expect(result.fetch('candidates').map { |candidate| candidate.slice('candidacy_id', 'name', 'ballot_number') })
      .to eq(frozen_contest.fetch('candidacies').map do |candidate|
        { 'candidacy_id' => candidate.fetch('id'), 'name' => candidate.fetch('principal_person').fetch('name'),
          'ballot_number' => candidate.fetch('number') }
      end)
  end

  it 'returns only public aggregate fields without session, device, receipt or vote arrival information' do
    confirm_first_vote
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.keys).to match_array(%w[status round_number contests revision])
    expect(result.keys).to match_array(%w[
      status participation confirmations nominal_votes legend_votes blank_votes null_votes valid_votes
      total_votes administrative_null_votes stages candidates contest_id contest_name
    ])
    result.fetch('candidates').each do |candidate|
      expect(candidate.keys).to match_array(%w[candidacy_id name ballot_number votes percentage])
    end
    result.fetch('stages').each do |stage|
      expect(stage.keys).to match_array(%w[
        stage_id choice_index nominal_votes legend_votes blank_votes null_votes administrative_null_votes total_votes
      ])
    end
    expect(response.body).not_to include(voting_session.id, device.public_label, device.credential_digest,
                                        ConfirmationReceipt.sole.id, 'command_key', 'confirmed_at', 'created_at',
                                        'voting_device_id', 'first_choice_fingerprint', 'elected_ids', 'winner')
  end

  it 'keeps repeated consultations read-only without starting a released voter or recomputing a tally' do
    voting_session
    original = operational_counts
    2.times do
      consult
      expect(response).to have_http_status(:ok)
    end
    expect(operational_counts).to eq(original)
    expect(voting_session.reload.started_at).to be_nil
    expect(voting_session.state).to eq('released')
  end

  it 'continues to show partial aggregates during suspension without declaring a winner' do
    confirm_first_vote
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'School interruption', now: now)
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('status')).to eq('partial')
    expect(result).to include('status' => 'partial', 'nominal_votes' => 1, 'valid_votes' => 1)
    expect(result.keys).not_to include('winner', 'elected_ids')
  end

  it 'returns a stable JSON not_found error for an unknown election' do
    get '/api/v1/public/elections/0/partial'
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end

  it 'does not publish a draft election without an opened round' do
    draft = Election.create!(school_installation: school, creator: creator, title: 'Draft Election',
                             description: 'A draft without public ballot', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    consult(draft)
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
  end

  it 'does not label closed-round tallies as live partials or expose them through the partial endpoint' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'last-choice',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    consult
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
    expect(TallyRun.sole.state).to eq('final')
  end

  it 'does not expose annulled-round counts as valid live partials' do
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid election process',
                           confirmed: true, now: now)
    consult
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
  end
end
