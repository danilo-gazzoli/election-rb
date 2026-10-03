# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting method availability' do
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
  let!(:round) do
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

  %w[proportional].each do |method|
    it "reports #{method} as unavailable in preview without altering the draft" do
      contest.update!(method: method, seats: 1, choices_per_person: 1)
      version = election.configuration_version
      result = Configuration::PreviewElection.call(election: election, actor: creator)
      expect(result.fetch(:valid)).to be(false)
      expect(result.fetch(:issues)).to include(
        a_hash_including(code: 'unavailable_method', contest_id: contest.id)
      )
      expect(result.fetch(:ballot)).to be_nil
      expect(result.fetch(:stages)).to be_empty
      expect(contest.reload.method).to eq(method)
      expect(round.reload.state).to eq('draft')
      expect(election.reload.configuration_version).to eq(version)
      expect(AuditEvent.count).to eq(0)
    end

    it "rejects opening #{method} before creating any snapshot or voting records" do
      contest.update!(method: method, seats: 1, choices_per_person: 1)
      version = election.configuration_version
      expect { Voting::OpenRound.call(round: round, actor: creator) }
        .to raise_error(Voting::OpenRound::InvalidConfiguration, /not available/)
      expect(round.reload.state).to eq('draft')
      expect(election.reload.configuration_version).to eq(version)
      expect(ConfigurationSnapshot.where(round: round)).to be_empty
      expect(VotingStage.where(round: round)).to be_empty
      expect(RoundContest.where(round: round)).to be_empty
      expect(RoundCandidacy.where(round: round)).to be_empty
      expect(AuditEvent.count).to eq(0)
    end
  end

  it 'makes an absolute-majority profile without a vice available with one choice stage' do
    contest.update!(method: 'absolute_majority', seats: 1, choices_per_person: 1, has_vice: false)
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(round.reload.state).to eq('open')
    expect(snapshot.canonical_data.fetch('contests').first)
      .to include('method' => 'absolute_majority', 'has_vice' => false, 'choices_per_person' => 1)
    expect(VotingStage.where(round: round).count).to eq(1)
    expect(snapshot.canonical_data.fetch('contests').first.fetch('candidacies'))
      .to all(satisfy { |candidate| !candidate.key?('vice_person') && !candidate.key?('vice_party_id') })
  end

  it 'keeps the implemented simple-majority profile available irrespective of the office name' do
    contest.update!(name: 'Custom School Office')
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(round.reload.state).to eq('open')
    expect(snapshot.canonical_data.fetch('contests').first.fetch('method')).to eq('simple_majority')
    expect(VotingStage.where(round: round).count).to eq(2)
  end
end
