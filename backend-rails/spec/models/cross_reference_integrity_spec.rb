# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting catalog cross references' do
  let(:installation) { SchoolInstallation.create!(identifier: 'cross-reference', name: 'Cross Reference School') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'First Election',
                     description: 'First election for cross reference testing',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.day.from_now,
                  closes_at: 2.days.from_now, grace_until: 2.days.from_now + 10.minutes)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2)
  end

  it 'rejects linking a contest from another election even when model callbacks are skipped' do
    other_election = Election.create!(school_installation: installation, title: 'Other Election',
                                      description: 'Other election for cross reference testing',
                                      start_time: 1.day.from_now, end_time: 2.days.from_now,
                                      election_day: 1.day.from_now.to_date)
    other_contest = Contest.create!(election: other_election, name: 'Other Senate', position: 1,
                                    method: 'simple_majority', seats: 2, choices_per_person: 2)

    expect do
      RoundContest.insert_all!([{ round_id: round.id, contest_id: other_contest.id, state: 'included' }])
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects a voting stage attached to a link from another round through SQL' do
    link = RoundContest.create!(round: round, contest: contest)
    other_round = Round.create!(election: election, number: 2, opens_at: 3.days.from_now,
                                closes_at: 4.days.from_now, grace_until: 4.days.from_now + 10.minutes)

    expect do
      VotingStage.insert_all!([{ round_id: other_round.id, round_contest_id: link.id,
                                 global_position: 1, choice_index: 1 }])
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects a candidacy from a contest absent from the round through SQL' do
    RoundContest.create!(round: round, contest: contest)
    other_contest = Contest.create!(election: election, name: 'Other Contest', position: 2,
                                    method: 'simple_majority', seats: 1, choices_per_person: 1)
    party = Party.create!(name: 'Cross Reference Party', abbreviation: 'CRP', party_number: 96)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '96')
    candidacy = Candidacy.create!(contest: other_contest,
                                  principal_person: CandidatePerson.create!(name: 'Other Candidate'),
                                  principal_party: party, ballot_number: '961')

    expect do
      RoundCandidacy.insert_all!([{ round_id: round.id, candidacy_id: candidacy.id, eligible: true }])
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
