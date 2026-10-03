# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::SimpleMajorityTally do
  include_context 'an opened school voting round'
  let(:contest) do
    Contest.create!(election: election, name: 'School Representative', position: 1,
                    method: 'simple_majority', seats: 1, choices_per_person: 1, has_vice: false)
  end
  let(:other_candidate) { contest.candidacies.order(:id).second }

  def cast_person(*choices)
    session = Voting::Release.call(round: round, device: device, actor: pollworker, now: now)
    round.voting_stages.order(:global_position).zip(choices).each do |stage, choice|
      attributes = choice.is_a?(Candidacy) ? { kind: 'nominal', candidacy_id: choice.id } : { kind: choice }
      Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "stage-#{stage.id}",
                           now: now, **attributes)
    end
    expect(session.reload.state).to eq('completed')
  end

  def tally
    described_class.call(round_contest: round.round_contests.sole)
  end

  it 'does not calculate winners before the round closes' do
    cast_person(first_candidate)
    expect { tally }.to raise_error(ArgumentError, /not closed/)
    expect(TallyRun.count).to eq(0)
  end

  it 'elects the most voted candidacy after closure, excluding blank and null, deterministically without writes' do
    [first_candidate, first_candidate, other_candidate, 'blank', 'null'].each { |choice| cast_person(choice) }
    round.update!(state: 'closed')
    original = [CastVote.count, ConfirmationReceipt.count, AuditEvent.count, TallyRun.count]
    expected = { status: 'final', elected_ids: [first_candidate.id], valid_votes: 3,
                 counts: { first_candidate.id => 2, other_candidate.id => 1 } }
    2.times { expect(tally).to eq(expected) }
    expect([CastVote.count, ConfirmationReceipt.count, AuditEvent.count, TallyRun.count]).to eq(original)
  end

  it 'keeps a decisive tie pending instead of resolving it by database id' do
    cast_person(first_candidate)
    cast_person(other_candidate)
    round.update!(state: 'closed')
    expect(tally).to eq(status: 'pending', reason: 'decisive tie')
  end

  it 'keeps zero valid votes pending even when people confirmed blank and null ballots' do
    cast_person('blank')
    cast_person('null')
    round.update!(state: 'closed')
    expect(tally).to eq(status: 'pending', reason: 'no valid nominal votes')
  end

  context 'with two seats and two choices' do
    let(:contest) do
      Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                      seats: 2, choices_per_person: 2, has_vice: false)
    end

    it 'does not fill a second seat with an unvoted candidacy' do
      cast_person(first_candidate, 'blank')
      round.update!(state: 'closed')
      expect(tally).to eq(status: 'pending', reason: 'insufficient voted candidacies')
    end

    it 'counts both choices and fills the two seats after closure and reconciliation' do
      cast_person(first_candidate, other_candidate)
      round.update!(state: 'closed')
      expect(tally).to eq(status: 'final', elected_ids: [first_candidate.id, other_candidate.id],
                          valid_votes: 2, counts: { first_candidate.id => 1, other_candidate.id => 1 })
    end
  end
end
