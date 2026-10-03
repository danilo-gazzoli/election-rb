# frozen_string_literal: true

require 'rails_helper'

# ERS RF-28/RF-36 and CA-09: people, confirmations and vote totals are distinct.
RSpec.describe Voting::PartialResult do
  include_context 'an opened school voting round'
  let(:round_contest) { round.round_contests.find_by!(contest_id: contest.id) }
  let(:other_candidate) { contest.candidacies.order(:id).second }

  def partial
    described_class.call(round_contest: round_contest)
  end

  def confirm_choice(session, stage, choice)
    attributes = choice.is_a?(Candidacy) ? { kind: 'nominal', candidacy_id: choice.id } : { kind: choice }
    Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "stage-#{stage.id}",
                         now: now, **attributes)
  end

  def complete_person(first, second)
    session = Voting::Release.call(round: round, device: device, actor: pollworker, now: now)
    confirm_choice(session, first_stage, first)
    confirm_choice(session, second_stage, second)
    session
  end

  it 'does not count an unstarted release as participation and uses null percentages with no valid votes' do
    voting_session
    result = partial
    expect(result).to include(status: 'partial', participation: 0, confirmations: 0, valid_votes: 0,
                              total_votes: 0, administrative_null_votes: 0)
    expect(result.fetch(:candidates).map { |candidate| candidate.fetch(:percentage) }).to eq([nil, nil])
    expect(result.fetch(:stages).map { |stage| stage.fetch(:total_votes) }).to eq([0, 0])
  end

  it 'sums both choices while counting one person and never declares an elected candidacy' do
    session = complete_person(first_candidate, other_candidate)
    confirm_choice(session, first_stage, first_candidate)
    result = partial
    expect(result).to include(status: 'partial', participation: 1, confirmations: 2,
                              nominal_votes: 2, valid_votes: 2, total_votes: 2)
    expect(result.fetch(:candidates)).to eq([
      { candidacy_id: first_candidate.id, votes: 1, percentage: 50.0 },
      { candidacy_id: other_candidate.id, votes: 1, percentage: 50.0 }
    ])
    expect(result.keys).not_to include(:elected_ids, :winner, :ranking)
  end

  it 'separates blank, voter null and administrative null by stage without adding them to valid votes' do
    complete_person(first_candidate, 'blank')
    session = Voting::Release.call(round: round, device: device, actor: pollworker, now: now)
    confirm_choice(session, first_stage, 'null')
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Voter left', now: now)
    result = partial
    expect(result).to include(participation: 2, confirmations: 3, nominal_votes: 1,
                              legend_votes: 0, blank_votes: 1, null_votes: 2,
                              administrative_null_votes: 1, valid_votes: 1, total_votes: 4)
    expect(result.fetch(:stages)).to eq([
      { stage_id: first_stage.id, choice_index: 1, nominal_votes: 1, legend_votes: 0,
        blank_votes: 0, null_votes: 1, administrative_null_votes: 0, total_votes: 2 },
      { stage_id: second_stage.id, choice_index: 2, nominal_votes: 0, legend_votes: 0,
        blank_votes: 1, null_votes: 1, administrative_null_votes: 1, total_votes: 2 }
    ])
    expect(result.fetch(:candidates).first.fetch(:percentage)).to eq(100.0)
  end

  it 'does not count an unconfirmed second-choice warning or change a previously confirmed vote' do
    confirm_choice(voting_session, first_stage, first_candidate)
    previous = partial
    warning = confirm_choice(voting_session, second_stage, first_candidate)
    expect(warning.status).to eq(:warning_required)
    expect(partial).to eq(previous)
    expect(partial).to include(participation: 1, confirmations: 1, valid_votes: 1)
  end

  it 'calculates percentages from valid votes across both stages rather than people or all ballots' do
    complete_person(first_candidate, other_candidate)
    complete_person(first_candidate, 'null')
    result = partial
    expect(result).to include(participation: 2, confirmations: 4, valid_votes: 3, total_votes: 4)
    expect(result.fetch(:candidates).map { |candidate| candidate.fetch(:percentage) }).to eq([66.67, 33.33])
  end

  it 'keeps percentages null when people confirmed only blank and null choices' do
    complete_person('blank', 'null')
    result = partial
    expect(result).to include(participation: 1, confirmations: 2, valid_votes: 0, total_votes: 2)
    expect(result.fetch(:candidates).map { |candidate| candidate.fetch(:votes) }).to eq([0, 0])
    expect(result.fetch(:candidates).map { |candidate| candidate.fetch(:percentage) }).to eq([nil, nil])
  end
end

# Test aggregation independently; this fixture does not enable proportional opening or tally (F10).
RSpec.describe 'Proportional partial denominator' do
  let(:school) { SchoolInstallation.create!(identifier: 'partial-proportional', name: 'Partial School') }
  let(:election) do
    Election.create!(school_installation: school, title: 'Proportional Election',
                     description: 'Isolated aggregation fixture', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Council', position: 1, method: 'proportional',
                    seats: 3, choices_per_person: 1, has_vice: false)
  end
  let(:party) { Party.create!(name: 'Aggregate Party', abbreviation: 'AGP', party_number: 51) }
  let(:candidate) do
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Council Person'),
                      principal_party: party, ballot_number: '511')
  end
  let(:round_contest) { RoundContest.create!(round: round, contest: contest) }
  let(:stage) { VotingStage.create!(round: round, round_contest: round_contest, global_position: 1, choice_index: 1) }
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Aggregation Device',
                         credential_digest: 'digest', state: 'locked')
  end

  before do
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '51')
    stage
    RoundCandidacy.create!(round: round, candidacy: candidate)
    round.update!(state: 'open')
    %w[nominal legend blank null].each_with_index do |kind, index|
      session = VotingSession.create!(round: round, voting_device: device, released_at: Time.current)
      Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "proportional-#{index}",
                           kind: kind, candidacy_id: kind == 'nominal' ? candidate.id : nil,
                           party_id: kind == 'legend' ? party.id : nil)
    end
  end

  it 'includes legend in valid votes while excluding blank and null from the candidate percentage' do
    result = Voting::PartialResult.call(round_contest: round_contest)
    expect(result).to include(participation: 4, confirmations: 4, nominal_votes: 1, legend_votes: 1,
                              blank_votes: 1, null_votes: 1, valid_votes: 2, total_votes: 4)
    expect(result.fetch(:candidates)).to eq([{ candidacy_id: candidate.id, votes: 1, percentage: 50.0 }])
  end

  it 'reports the legend count and total in each proportional stage' do
    result = Voting::PartialResult.call(round_contest: round_contest)
    expect(result.fetch(:stages)).to eq([
      { stage_id: stage.id, choice_index: 1, nominal_votes: 1, legend_votes: 1, blank_votes: 1,
        null_votes: 1, administrative_null_votes: 0, total_votes: 4 }
    ])
  end
end
