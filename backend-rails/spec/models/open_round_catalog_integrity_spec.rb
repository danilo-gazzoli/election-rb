# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Opened round catalog integrity' do
  let(:installation) { SchoolInstallation.create!(identifier: 'frozen-catalog', name: 'Frozen Catalog School') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'Frozen Catalog Election',
                     description: 'Election used to verify catalog immutability',
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

  def open_round!
    RoundContest.create!(round: round, contest: contest)
    round.update!(state: 'open')
  end

  it 'persists catalog changes while the round is still in draft' do
    person = CandidatePerson.create!(name: 'Candidate Person')
    party = Party.create!(name: 'Example Party', abbreviation: 'EX', party_number: 98)
    registration = ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '98')
    candidacy = Candidacy.create!(contest: contest, principal_person: person,
                                  principal_party: party, ballot_number: '981')

    contest.update!(name: 'Updated Senate')
    candidacy.update!(ballot_number: '982')
    person.update!(name: 'Updated Candidate')
    registration.update!(ballot_number: '99')

    expect(contest.reload.name).to eq('Updated Senate')
    expect(candidacy.reload.ballot_number).to eq('982')
    expect(person.reload.name).to eq('Updated Candidate')
    expect(registration.reload.ballot_number).to eq('99')
  end

  it 'persists eligibility changes to round links before opening' do
    party = Party.create!(name: 'Example Party', abbreviation: 'EX', party_number: 98)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '98')
    candidacy = Candidacy.create!(contest: contest,
                                  principal_person: CandidatePerson.create!(name: 'Candidate Person'),
                                  principal_party: party, ballot_number: '981')
    RoundContest.create!(round: round, contest: contest)
    eligibility = RoundCandidacy.create!(round: round, candidacy: candidacy)

    eligibility.update!(eligible: false)

    expect(eligibility.reload.eligible).to be(false)
  end

  it 'rejects adding a contest to an opened round through SQL' do
    open_round!
    other_contest = Contest.create!(election: election, name: 'Second contest', position: 2,
                                    method: 'simple_majority', seats: 1, choices_per_person: 1)

    expect { RoundContest.create!(round: round, contest: other_contest) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects adding an eligible candidacy to an opened round through SQL' do
    person = CandidatePerson.create!(name: 'Candidate Person')
    party = Party.create!(name: 'Example Party', abbreviation: 'EX', party_number: 98)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '98')
    candidacy = Candidacy.create!(contest: contest, principal_person: person,
                                  principal_party: party, ballot_number: '981')
    open_round!

    expect { RoundCandidacy.create!(round: round, candidacy: candidacy) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects adding a voting stage to an opened round through SQL' do
    link = RoundContest.create!(round: round, contest: contest)
    round.update!(state: 'open')

    expect do
      VotingStage.create!(round: round, round_contest: link,
                          global_position: 1, choice_index: 1)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects adding a party registration after an election round opens' do
    open_round!
    party = Party.create!(name: 'Another Party', abbreviation: 'AN', party_number: 97)

    expect do
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '97')
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
