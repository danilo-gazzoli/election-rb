# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Federations in ballot preview and opening' do
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

  def configure_federation(member_count, state: 'active')
    federation = Federation.create!(election: election, name: 'School Alliance',
                                     abbreviation: 'SA', state: state)
    if member_count.positive?
      FederationMembership.create!(federation: federation, party: Party.find_by!(abbreviation: 'OTP'))
    end
    if member_count > 1
      party = Party.create!(name: 'Second Alliance Party', abbreviation: 'SAP', party_number: 48)
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '48')
      FederationMembership.create!(federation: federation, party: party)
    end
    federation
  end

  [0, 1].each do |member_count|
    it "rejects an active federation with #{member_count} parties in preview and opening" do
      federation = configure_federation(member_count)
      version = election.configuration_version
      preview = Configuration::PreviewElection.call(election: election, actor: creator)
      expect(preview.fetch(:valid)).to be(false)
      expect(preview.fetch(:issues)).to include(
        a_hash_including(code: 'invalid_federation', federation_id: federation.id)
      )
      expect(preview.fetch(:ballot)).to be_nil
      expect(preview.fetch(:stages)).to be_empty
      expect { Voting::OpenRound.call(round: round, actor: creator) }
        .to raise_error(Voting::OpenRound::InvalidConfiguration, /federation/)
      expect(round.reload.state).to eq('draft')
      expect(ConfigurationSnapshot.where(round: round)).to be_empty
      expect(VotingStage.where(round: round)).to be_empty
      expect(AuditEvent.count).to eq(0)
      expect(election.reload.configuration_version).to eq(version)
    end
  end

  it 'preserves the complete federation composition in preview and the frozen snapshot' do
    federation = configure_federation(2)
    ids = federation.parties.order(:id).pluck(:id)
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expected = [{ 'id' => federation.id, 'name' => 'School Alliance', 'abbreviation' => 'SA',
                  'state' => 'active', 'party_ids' => ids }]
    expect(preview.fetch(:valid)).to be(true)
    expect(preview.fetch(:ballot).fetch('federations')).to eq(expected)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(snapshot.canonical_data.fetch('federations')).to eq(expected)
    expect(snapshot.canonical_data).to eq(preview.fetch(:ballot))
    principal_party = Party.find_by!(abbreviation: 'OTP')
    snapshot.canonical_data.fetch('contests').first.fetch('candidacies').each do |candidate|
      expect(candidate.fetch('party_id')).to eq(principal_party.id)
    end
  end

  it 'keeps elections without federations valid and freezes an empty composition' do
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    expect(preview.fetch(:ballot).fetch('federations')).to eq([])
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(snapshot.canonical_data.fetch('federations')).to eq([])
  end

  it 'preserves an inactive federation without applying the active minimum membership rule' do
    federation = configure_federation(1, state: 'inactive')
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(snapshot.canonical_data.fetch('federations')).to eq([
      { 'id' => federation.id, 'name' => federation.name, 'abbreviation' => federation.abbreviation,
        'state' => 'inactive', 'party_ids' => federation.parties.order(:id).pluck(:id) }
    ])
  end
end
