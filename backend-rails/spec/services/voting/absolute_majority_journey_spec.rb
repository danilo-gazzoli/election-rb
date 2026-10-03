# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Absolute majority availability and mixed round journey' do
  include_context 'a mixed majority election'

  it 'previews valid absolute and simple majority contests without changing draft configuration' do
    original = [election.configuration_version, AuditEvent.count, ConfigurationSnapshot.count,
                VotingStage.count, RoundContest.count, RoundCandidacy.count]
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    expect(preview.fetch(:ballot).fetch('contests').map { |item| item.fetch('method') })
      .to eq(%w[absolute_majority simple_majority absolute_majority])
    expect(preview.fetch(:stages).map { |item| item.fetch(:global_position) }).to eq([1, 2, 3])
    expect([election.reload.configuration_version, AuditEvent.count, ConfigurationSnapshot.count,
            VotingStage.count, RoundContest.count, RoundCandidacy.count]).to eq(original)
  end

  it 'opens the complete first round with one stage per contest and affiliated vice identities' do
    snapshot = open_first
    expect(round.reload.state).to eq('open')
    expect(round.voting_stages.order(:global_position).map { |stage| stage.round_contest.contest_id })
      .to eq([decided.id, simple.id, contested.id])
    expect(RoundCandidacy.where(round: round, eligible: true).count).to eq(8)
    ballot_contest = snapshot.canonical_data.fetch('contests').last
    slate = ballot_contest.fetch('candidacies').first
    expect(slate).to include('party_id' => principal_party.id, 'vice_party_id' => vice_party.id,
                            'vice_person' => { 'id' => slates.fetch(contested.id).first.vice_person_id,
                                               'name' => slates.fetch(contested.id).first.vice_person.name })
    expect(ballot_contest).to include('has_vice' => true, 'choices_per_person' => 1)
    expect(VotingSession.where(round: round)).not_to exist
  end

  it 'carries only the unresolved absolute contest to another day and preserves both first-round winners' do
    finish_mixed_first
    first_tallies = TallyRun.joins(:round_contest).where(round_contests: { round_id: round.id })
                           .index_by { |tally| tally.round_contest.contest_id }
    expect(first_tallies.fetch(decided.id).state).to eq('final')
    expect(first_tallies.fetch(simple.id).state).to eq('final')
    expect(first_tallies.fetch(contested.id).totals.fetch('reason')).to eq('second round required')
    historical = [ConfigurationSnapshot.find_by!(round: round).attributes,
                  first_tallies.transform_values(&:attributes), CastVote.where(round: round).order(:id).map(&:attributes)]

    second = prepare_mixed_second
    expect(second.round_contests.pluck(:contest_id)).to eq([contested.id])
    snapshot = Voting::OpenRound.call(round: second, actor: creator, now: second.opens_at)
    expect(snapshot.canonical_data.fetch('contests').map { |item| item.fetch('id') }).to eq([contested.id])
    expect(second.voting_stages.pluck(:global_position, :choice_index)).to eq([[1, 1]])
    pair = slates.fetch(contested.id).first(2)
    [pair.first, pair.first, pair.last].each { |candidate| mixed_vote(second, contested.id => candidate) }
    Voting::CloseRound.call(round: second, actor: creator, now: second.grace_until + 1.second)
    result = TallyRun.find_by!(round_contest: second.round_contests.first)
    expect(result.totals).to include('status' => 'final', 'elected_ids' => [pair.first.id], 'valid_votes' => 3)
    expect(CastVote.where(round: second).count).to eq(3)
    expect(VotingSession.where(round: second, state: 'completed').count).to eq(3)
    expect([ConfigurationSnapshot.find_by!(round: round).attributes,
            first_tallies.transform_values { |tally| tally.reload.attributes },
            CastVote.where(round: round).order(:id).map(&:attributes)]).to eq(historical)
  end

  it 'does not borrow first-round votes when no voter starts the second round' do
    finish_mixed_first
    second = prepare_mixed_second
    Voting::OpenRound.call(round: second, actor: creator, now: second.opens_at)
    Voting::CloseRound.call(round: second, actor: creator, now: second.grace_until + 1.second)
    tally = TallyRun.find_by!(round_contest: second.round_contests.first)
    expect(tally.state).to eq('pending')
    expect(tally.totals).to eq('status' => 'pending', 'reason' => 'no valid nominal votes')
    expect(CastVote.where(round: second)).not_to exist
    expect(VotingSession.where(round: second)).not_to exist
    expect(CastVote.where(round: round).count).to eq(18)
  end

  it 'does not create a second round when every absolute contest already has a winner' do
    finish_mixed_first(all_decided: true)
    historical = [Round.count, RoundContest.count, RoundCandidacy.count, AuditEvent.count]
    expect { prepare_mixed_second }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect([Round.count, RoundContest.count, RoundCandidacy.count, AuditEvent.count]).to eq(historical)
    expect(TallyRun.joins(:round_contest).where(round_contests: { round_id: round.id }).pluck(:state))
      .to eq(%w[final final final])
  end

  it 'keeps insufficient absolute candidacies invalid before any opening data is written' do
    slates.fetch(contested.id).last(2).each { |candidate| candidate.update!(state: 'withdrawn') }
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(false)
    expect(preview.fetch(:issues)).to include(a_hash_including(code: 'insufficient_candidacies', contest_id: contested.id))
    historical = [ConfigurationSnapshot.count, VotingStage.count, RoundContest.count, RoundCandidacy.count, AuditEvent.count]
    expect { open_first }.to raise_error(Voting::OpenRound::InvalidConfiguration)
    expect(round.reload.state).to eq('scheduled')
    expect([ConfigurationSnapshot.count, VotingStage.count, RoundContest.count, RoundCandidacy.count, AuditEvent.count])
      .to eq(historical)
  end
end
