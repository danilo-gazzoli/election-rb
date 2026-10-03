# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 frozen slate identities', type: :request do
  include_context 'a mixed majority election'

  def pair_slate_device
    device.update!(pairing_code_digest: VotingDevice.digest_credential('slate-pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'slate-pair-code' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def identity_for(candidate)
    person = candidate.principal_person
    party = candidate.principal_party
    result = {
      'principal_person' => { 'id' => person.id, 'name' => person.name },
      'principal_party' => { 'id' => party.id, 'number' => party.party_number.to_s,
                             'name' => party.name, 'abbreviation' => party.abbreviation }
    }
    if candidate.vice_person
      vice = candidate.vice_person
      vice_party = candidate.vice_party
      result.merge!(
        'vice_person' => { 'id' => vice.id, 'name' => vice.name },
        'vice_party' => { 'id' => vice_party.id, 'number' => vice_party.party_number.to_s,
                          'name' => vice_party.name, 'abbreviation' => vice_party.abbreviation }
      )
    end
    result
  end

  def release_slate_device(target_round = round)
    Voting::Release.call(round: target_round, device: device, actor: operator, now: target_round.opens_at)
  end

  def public_contest(contest)
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:ok)
    response.parsed_body.fetch('contests').find { |item| item.fetch('contest_id') == contest.id }
  end

  it 'returns principal, vice and their distinct frozen parties in the first-round device catalog' do
    open_first
    pair_slate_device
    release_slate_device
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    stage = response.parsed_body.fetch('stage')
    expect(stage.fetch('choice_index')).to eq(1)
    expect(stage.fetch('candidates').map { |item| item.fetch('id') }).to eq(slates.fetch(decided.id).map(&:id))
    expect(stage.fetch('candidates').first).to include(identity_for(slates.fetch(decided.id).first))
    expect(VotingStage.where(round: round, round_contest: RoundContest.find_by!(round: round, contest: decided)).count)
      .to eq(1)
  end

  it 'returns only the two qualified slate identities in the second-round device catalog' do
    finish_mixed_first
    second = prepare_mixed_second
    Voting::OpenRound.call(round: second, actor: creator, now: second.opens_at)
    pair_slate_device
    release_slate_device(second)
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    rows = response.parsed_body.fetch('stage').fetch('candidates')
    expect(rows.map { |item| item.fetch('id') }).to eq(slates.fetch(contested.id).first(2).map(&:id))
    expect(rows.first).to include(identity_for(slates.fetch(contested.id).first))
    expect(rows.map { |item| item.fetch('id') }).not_to include(slates.fetch(contested.id).last.id)
  end

  it 'shows each public slate and its vice under one nominal aggregate without operational identities' do
    open_first
    mixed_vote(round, decided.id => slates.fetch(decided.id).first,
                      simple.id => slates.fetch(simple.id).first,
                      contested.id => slates.fetch(contested.id).first)
    projection = public_contest(decided)
    rows = projection.fetch('candidates')
    expect(rows.size).to eq(3)
    expect(rows.first).to include(identity_for(slates.fetch(decided.id).first))
    expect(rows.first.fetch('votes')).to eq(1)
    expect(projection.fetch('nominal_votes')).to eq(1)
    expect(projection.fetch('stages').size).to eq(1)
    expect(response.body).not_to match(/session_id|voting_device|receipt_id|credential|command_key|released_at/)
  end

  it 'returns a frozen slate catalog alongside the recorded private result without recalculation' do
    finish_mixed_first
    post '/api/v1/auth/login', params: { login: creator.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
    original = [TallyRun.order(:id).map(&:attributes), CastVote.count, AuditEvent.count]
    2.times do
      get "/api/v1/admin/rounds/#{round.id}/results"
      expect(response).to have_http_status(:ok)
      item = response.parsed_body.fetch('contests').find { |row| row.fetch('contest_id') == decided.id }
      expect(item.fetch('candidates').map { |row| row.fetch('id') }).to eq(slates.fetch(decided.id).map(&:id))
      expect(item.fetch('candidates').first).to include(identity_for(slates.fetch(decided.id).first))
      expect(item.fetch('result').fetch('elected_ids')).to eq([slates.fetch(decided.id).first.id])
    end
    expect([TallyRun.order(:id).map(&:attributes), CastVote.count, AuditEvent.count]).to eq(original)
  end

  it 'omits vice identity for a contest without vice while preserving principal and party identity' do
    open_first
    pair_slate_device
    session = release_slate_device
    first_stage = round.voting_stages.order(:global_position).first
    Voting::Confirm.call(session: session, stage_id: first_stage.id, command_key: 'first-slate', kind: 'nominal',
                         candidacy_id: slates.fetch(decided.id).first.id, now: round.opens_at)
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    rows = response.parsed_body.fetch('stage').fetch('candidates')
    expect(rows.first).to include(identity_for(slates.fetch(simple.id).first))
    expect(rows).to all(satisfy { |row| !row.key?('vice_person') && !row.key?('vice_party') })
    public_rows = public_contest(simple).fetch('candidates')
    expect(public_rows.first).to include(identity_for(slates.fetch(simple.id).first))
    expect(public_rows).to all(satisfy { |row| !row.key?('vice_person') && !row.key?('vice_party') })
  end

  it 'reads identities from the frozen ballot even if live person and party names differ' do
    open_first
    expected = identity_for(slates.fetch(decided.id).first)
    pair_slate_device
    release_slate_device
    allow_any_instance_of(CandidatePerson).to receive(:name).and_return('Changed live person')
    allow_any_instance_of(Party).to receive(:name).and_return('Changed live party')
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('stage').fetch('candidates').first).to include(expected)
    expect(public_contest(decided).fetch('candidates').first).to include(expected)
  end

  it 'shows only qualified slates in public second-round aggregates with their own counts' do
    finish_mixed_first
    second = prepare_mixed_second
    Voting::OpenRound.call(round: second, actor: creator, now: second.opens_at)
    mixed_vote(second, contested.id => slates.fetch(contested.id).first)
    projection = public_contest(contested)
    expect(response.parsed_body.fetch('round_number')).to eq(2)
    rows = projection.fetch('candidates')
    expect(rows.map { |row| row.fetch('candidacy_id') }).to eq(slates.fetch(contested.id).first(2).map(&:id))
    expect(rows.first).to include(identity_for(slates.fetch(contested.id).first))
    expect(rows.first.fetch('votes')).to eq(1)
    expect(projection.fetch('nominal_votes')).to eq(1)
  end
end
