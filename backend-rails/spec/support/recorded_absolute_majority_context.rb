# frozen_string_literal: true

require 'digest'

RSpec.shared_context 'a recorded absolute majority first round' do
  include_context 'an absolute majority tally round'

  let(:now) { Time.utc(2026, 10, 2, 22, 1) }
  let(:opens_at) { now + 2.days }
  let(:closes_at) { opens_at + 1.hour }
  let(:with_snapshot) { true }

  before do
    if with_snapshot
      ballot = {
        'round_number' => round.number, 'rule_version' => election.configuration_version,
        'schedule' => { 'opens_at' => round.opens_at.utc.iso8601(6),
                        'closes_at' => round.closes_at.utc.iso8601(6),
                        'grace_until' => round.grace_until.utc.iso8601(6), 'timezone' => school.timezone },
        'parties' => [principal_party, vice_party].map do |party|
          { 'id' => party.id, 'number' => party.party_number.to_s,
            'name' => party.name, 'abbreviation' => party.abbreviation }
        end,
        'federations' => [],
        'contests' => [{ 'id' => contest.id, 'name' => contest.name, 'position' => contest.position,
                         'method' => contest.method, 'rule_version' => contest.rule_version,
                         'has_vice' => true, 'seats' => 1, 'choices_per_person' => 1,
                         'candidacies' => candidates.map do |candidate|
                           { 'id' => candidate.id, 'number' => candidate.ballot_number,
                             'party_id' => candidate.principal_party_id,
                             'principal_person' => { 'id' => candidate.principal_person_id,
                                                     'name' => candidate.principal_person.name },
                             'vice_party_id' => candidate.vice_party_id,
                             'vice_person' => { 'id' => candidate.vice_person_id,
                                                'name' => candidate.vice_person.name } }
                         end }]
      }
      ConfigurationSnapshot.create!(round: round, version: election.configuration_version,
                                     canonical_data: ballot,
                                     digest: Digest::SHA256.hexdigest(JSON.generate(ballot)))
    end
  end

  def finish_first(*counts)
    counts_for(*counts)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  def prepare(actor: creator, **calendar)
    Voting::PrepareRunoff.call(first_round: round, actor: actor, opens_at: opens_at, closes_at: closes_at,
                         now: round.grace_until + 1.second, **calendar)
  end

  def persistence
    [Round.count, RoundContest.count, RoundCandidacy.count, VotingStage.count, VotingSession.count,
     CastVote.count, ConfirmationReceipt.count, ConfigurationSnapshot.count, TallyRun.count, AuditEvent.count]
  end

end
