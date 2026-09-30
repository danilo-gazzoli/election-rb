# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::OpenRound do
  let(:installation) { SchoolInstallation.create!(identifier: 'open-school', name: 'Open School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, creator: creator, title: 'School Election',
                     description: 'A school election for the opening test',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft',
                  opens_at: 1.minute.ago, closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    party = Party.create!(name: 'Open Test Party', abbreviation: 'OTP', party_number: 47)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '47')
    2.times do |index|
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Person #{index}"),
                        principal_party: party, ballot_number: "47#{index}")
    end
  end

  it 'opens a two-choice round with consecutive stages and an immutable snapshot' do
    described_class.call(round: round, actor: creator)

    expect(round.reload.state).to eq('open')
    expect(VotingStage.where(round: round).order(:global_position).pluck(:choice_index)).to eq([1, 2])
    expect(RoundCandidacy.where(round: round).count).to eq(2)
    snapshot = ConfigurationSnapshot.find_by!(round: round)
    expect(snapshot.digest).to match(/\A[0-9a-f]{64}\z/)
    expect(snapshot.canonical_data.fetch('contests').first.fetch('method')).to eq('simple_majority')
    expect { described_class.call(round: round, actor: creator) }.to raise_error(Voting::OpenRound::NotAllowed)
  end

  it 'refuses to open an unsupported two-seat profile even if draft SQL bypassed validations' do
    contest.update_columns(choices_per_person: 1)

    expect { described_class.call(round: round, actor: creator) }
      .to raise_error(Voting::OpenRound::InvalidConfiguration, /profile/)
    expect(round.reload.state).to eq('draft')
    expect(VotingStage.where(round: round)).to be_empty
  end

  it 'includes the election party ballot identity in the frozen snapshot' do
    snapshot = described_class.call(round: round, actor: creator)
    registration = ElectionPartyRegistration.find_by!(election: election)
    party = registration.party

    expect(snapshot.canonical_data.fetch('parties')).to eq([
      {
        'id' => party.id,
        'number' => registration.ballot_number,
        'name' => party.name,
        'abbreviation' => party.abbreviation
      }
    ])
  end

  it 'includes the contest identity and rule version in the frozen snapshot' do
    snapshot = described_class.call(round: round, actor: creator)
    contest_data = snapshot.canonical_data.fetch('contests').first

    expect(contest_data.slice('name', 'rule_version', 'has_vice')).to eq(
      'name' => contest.name,
      'rule_version' => contest.rule_version,
      'has_vice' => false
    )
  end

  it 'includes the principal candidate identity in the frozen snapshot' do
    snapshot = described_class.call(round: round, actor: creator)
    candidate = contest.candidacies.order(:id).first
    candidate_data = snapshot.canonical_data.fetch('contests').first.fetch('candidacies').first

    expect(candidate_data.fetch('principal_person')).to eq(
      'id' => candidate.principal_person_id,
      'name' => candidate.principal_person.name
    )
  end

  it 'includes the vice identity and distinct party in a slate snapshot' do
    principal_party = Party.find_by!(abbreviation: 'OTP')
    vice_party = Party.create!(name: 'Vice Party', abbreviation: 'VP', party_number: 48)
    ElectionPartyRegistration.create!(election: election, party: vice_party, ballot_number: '48')
    mayor = Contest.create!(election: election, name: 'Mayor', position: 2,
                            method: 'simple_majority', seats: 1, choices_per_person: 1,
                            has_vice: true)
    2.times do |index|
      Candidacy.create!(contest: mayor,
                        principal_person: CandidatePerson.create!(name: "Mayor #{index}"),
                        principal_party: principal_party,
                        vice_person: CandidatePerson.create!(name: "Vice #{index}"),
                        vice_party: vice_party, ballot_number: "47#{index}")
    end

    snapshot = described_class.call(round: round, actor: creator)
    candidate = mayor.candidacies.order(:id).first
    candidate_data = snapshot.canonical_data.fetch('contests').last.fetch('candidacies').first

    expect(candidate_data.fetch('vice_person')).to eq(
      'id' => candidate.vice_person_id,
      'name' => candidate.vice_person.name
    )
    expect(candidate_data.fetch('vice_party_id')).to eq(vice_party.id)
  end

  it 'rejects an ambiguous proportional number shared by a candidacy and party legend' do
    party = Party.find_by!(abbreviation: 'OTP')
    proportional = Contest.create!(election: election, name: 'Council', position: 2,
                                   method: 'proportional', seats: 3, choices_per_person: 1,
                                   has_vice: false)
    Candidacy.create!(contest: proportional,
                      principal_person: CandidatePerson.create!(name: 'Council Candidate'),
                      principal_party: party, ballot_number: '47')

    expect { described_class.call(round: round, actor: creator) }
      .to raise_error(Voting::OpenRound::InvalidConfiguration, /ambiguous/)
    expect(round.reload.state).to eq('draft')
    expect(ConfigurationSnapshot.where(round: round)).to be_empty
  end

  it 'freezes the round schedule and timezone for reproducible reporting' do
    snapshot = described_class.call(round: round, actor: creator)

    expect(snapshot.canonical_data.fetch('schedule')).to eq(
      'opens_at' => round.opens_at.utc.iso8601(6),
      'closes_at' => round.closes_at.utc.iso8601(6),
      'grace_until' => round.grace_until.utc.iso8601(6),
      'timezone' => installation.timezone
    )
  end

  it 'rejects a candidacy whose party is no longer registered for the election' do
    ElectionPartyRegistration.find_by!(election: election).destroy!

    expect { described_class.call(round: round, actor: creator) }
      .to raise_error(Voting::OpenRound::InvalidConfiguration, /party/)
    expect(round.reload.state).to eq('draft')
    expect(ConfigurationSnapshot.where(round: round)).to be_empty
  end

  it 'rejects candidacies without a vice when the contest now requires a slate' do
    contest.update!(has_vice: true)
    expect(contest.reload.has_vice?).to be(true)
    expect(election.contests.find(contest.id).has_vice?).to be(true)
    expect(contest.candidacies.first.reload.vice_person_id).to be_nil

    expect { described_class.call(round: round, actor: creator) }
      .to raise_error(Voting::OpenRound::InvalidConfiguration, /vice/)
    expect(round.reload.state).to eq('draft')
    expect(ConfigurationSnapshot.where(round: round)).to be_empty
  end

  it 'rejects an unauthorized creator before creating any stages' do
    outsider = User.create!(school_installation: installation, name: 'Other', login: 'other',
                            password: 'long-random-password')
    expect { described_class.call(round: round, actor: outsider) }
      .to raise_error(Voting::OpenRound::NotAllowed)
    expect(VotingStage.count).to eq(0)
    expect(ConfigurationSnapshot.count).to eq(0)
  end

  it 'freezes contest and candidacy data after opening even for direct SQL updates' do
    described_class.call(round: round, actor: creator)
    candidate = contest.candidacies.first

    expect { contest.update_columns(name: 'Changed Office') }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { candidate.update_columns(ballot_number: '999') }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { VotingStage.where(round: round).delete_all }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'keeps party registration and candidate identity frozen after opening' do
    described_class.call(round: round, actor: creator)
    candidate = contest.candidacies.first
    registration = ElectionPartyRegistration.find_by!(election: election)

    expect { registration.update_columns(ballot_number: '99') }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { candidate.principal_person.update_columns(name: 'Changed Name') }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'prevents changing the enabled candidates and contests after opening' do
    described_class.call(round: round, actor: creator)
    expect { RoundCandidacy.where(round: round).update_all(eligible: false) }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { RoundContest.where(round: round).delete_all }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'prevents adding a new candidate to an already opened contest' do
    described_class.call(round: round, actor: creator)
    party = contest.candidacies.first.principal_party
    expect do
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Late Candidate'),
                        principal_party: party, ballot_number: '479')
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
