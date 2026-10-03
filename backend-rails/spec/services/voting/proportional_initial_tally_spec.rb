# frozen_string_literal: true

require 'rails_helper'
require 'digest'

# Isolated proportional fixture: production opening stays unavailable until F10b.
RSpec.describe Voting::ProportionalInitialTally do
  include_context 'an absolute majority tally round'

  let(:with_snapshot) { true }
  let(:with_federation) { false }
  let(:contest) do
    Contest.create!(election: election, name: 'Council', position: 1, method: 'proportional',
                    seats: 2, choices_per_person: 1, has_vice: false,
                    rule_version: 'proporcional_br_2026_v1')
  end
  let(:candidates) do
    if with_federation
      federation = Federation.create!(election: election, name: 'School Federation')
      [principal_party, vice_party].each do |party|
        FederationMembership.create!(election: election, federation: federation, party: party)
      end
    end
    [principal_party, vice_party, principal_party].each_with_index.map do |party, index|
      Candidacy.create!(contest: contest, ballot_number: "#{party.party_number}#{index}",
                        principal_party: party,
                        principal_person: CandidatePerson.create!(name: "Council #{index}"))
    end
  end

  before do
    if with_snapshot
      data = {
        'parties' => [principal_party, vice_party].map { |party| { 'id' => party.id } },
        'federations' => election.federations.order(:id).map do |federation|
          { 'id' => federation.id, 'state' => federation.state,
            'party_ids' => federation.parties.order(:id).pluck(:id) }
        end,
        'contests' => [{ 'id' => contest.id, 'method' => 'proportional', 'seats' => 2,
                         'rule_version' => 'proporcional_br_2026_v1',
                         'candidacies' => candidates.map do |candidate|
                           { 'id' => candidate.id, 'party_id' => candidate.principal_party_id }
                         end }]
      }
      ConfigurationSnapshot.create!(round: round, version: 1, canonical_data: data,
                                    digest: Digest::SHA256.hexdigest(JSON.generate(data)))
    end
  end

  def initial_tally
    described_class.call(round_contest: round_contest)
  end

  def cast_legend
    session = Voting::Release.call(round: round, device: device, actor: operator, now: now)
    Voting::Confirm.call(session: session, stage_id: stage.id, command_key: 'legend', kind: 'legend',
                         party_id: principal_party.id, now: now)
  end

  it 'does not apportion an open round' do
    expect { initial_tally }.to raise_error(ArgumentError, /not closed/)
  end

  it 'uses confirmed nominal and legend votes, excluding blanks and nulls, without publishing final winners' do
    counts_for(3, 1, 0)
    cast_legend
    cast('blank')
    cast('null')
    round.update!(state: 'closed')
    result = initial_tally
    expect(result).to include(status: 'pending', valid_votes: 5, nominal_votes: 4, legend_votes: 1,
                              blank_votes: 1, null_votes: 1, qe: 2,
                              algorithm_version: 'proporcional_br_2026_v1')
    expect(result.keys).not_to include(:elected_ids)
    expect(result.fetch(:units).sum { |unit| unit.fetch(:votes) }).to eq(5)
  end

  context 'with a frozen federation' do
    let(:with_federation) { true }

    it 'takes seats and composition from the snapshot instead of the live configuration' do
      counts_for(3, 1, 0)
      round.update!(state: 'closed')
      allow(contest).to receive(:seats).and_return(99)
      allow(election).to receive(:federations).and_return([])
      result = initial_tally
      expect(result.fetch(:seats)).to eq(2)
      expect(result.fetch(:units).size).to eq(1)
      expect(result.fetch(:units).first).to include(kind: 'federation', votes: 4, qp: 2,
                                                   initial_ids: candidates.first(2).map(&:id))
    end
  end

  context 'without a snapshot' do
    let(:with_snapshot) { false }

    it 'reports pending instead of deriving an authoritative result from live configuration' do
      round.update!(state: 'closed')
      expect(initial_tally).to include(status: 'pending', reason: 'configuration snapshot is missing')
    end
  end

  it 'reports pending when vote and receipt counts differ' do
    CastVote.create!(round: round, contest: contest, voting_stage: stage, kind: 'nominal',
                     origin: 'confirmation', candidacy: candidates.first)
    round.update!(state: 'closed')
    expect(initial_tally).to include(status: 'pending', reason: 'reconciliation differs by stage')
  end

  it 'does not borrow votes from another round' do
    counts_for(3, 1, 0)
    other = Round.create!(election: election, number: 2, state: 'draft', opens_at: now + 2.days,
                          closes_at: now + 2.days + 1.hour, grace_until: now + 2.days + 70.minutes)
    other_contest = RoundContest.create!(round: other, contest: contest)
    other_stage = VotingStage.create!(round: other, round_contest: other_contest,
                                     global_position: 1, choice_index: 1)
    RoundCandidacy.create!(round: other, candidacy: candidates.first)
    other.update!(state: 'open')
    CastVote.create!(round: other, contest: contest, voting_stage: other_stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: candidates.first)
    round.update!(state: 'closed')
    expect(initial_tally.fetch(:valid_votes)).to eq(4)
  end

  it 'records initial calculation and algorithm version through the existing round closing flow' do
    counts_for(3, 1, 0)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    recorded = TallyRun.find_by!(round_contest: round_contest)
    expect(recorded).to have_attributes(state: 'pending', algorithm_version: 'proporcional_br_2026_v1')
    expect(recorded.totals).to include('qe' => 2, 'valid_votes' => 4)
    expect(recorded.input_digest).to match(/\A[0-9a-f]{64}\z/)
  end

  it 'can be consulted repeatedly without changing votes, tally runs or audit' do
    counts_for(3, 1, 0)
    round.update!(state: 'closed')
    first = initial_tally
    before_counts = [CastVote.count, TallyRun.count, AuditEvent.count]
    expect(initial_tally).to eq(first)
    expect([CastVote.count, TallyRun.count, AuditEvent.count]).to eq(before_counts)
  end
end
