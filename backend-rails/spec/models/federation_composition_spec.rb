# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Federation composition integrity', type: :model do
  let(:school) { SchoolInstallation.create!(identifier: 'federation-school', name: 'Federation School') }
  let(:election) { create_election('First Federation Election') }
  let(:other_election) { create_election('Other Federation Election') }
  let(:party) { Party.create!(name: 'Federation Test Party', abbreviation: 'FTP', party_number: 41) }
  let(:federation) { Federation.create!(election: election, name: 'School Federation', state: 'active') }

  before { ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '41') }

  def create_election(title)
    Election.create!(school_installation: school, title: title, description: 'Election for federation configuration',
                     start_time: 1.day.from_now, end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end

  def raw_membership(federation_id:, election_id:, party_id:)
    FederationMembership.insert_all!([
      { federation_id: federation_id, election_id: election_id, party_id: party_id,
        created_at: Time.current, updated_at: Time.current }
    ])
  end

  it 'stores an election federation with an optional abbreviation and active state' do
    expect(federation).to have_attributes(election_id: election.id, name: 'School Federation',
                                          abbreviation: nil, state: 'active')
    expect(election.federations).to include(federation)
  end

  it 'requires an election, name and supported state' do
    expect(Federation.new(name: 'Unowned Federation', state: 'active')).not_to be_valid
    expect(Federation.new(election: election, name: '', state: 'active')).not_to be_valid
    expect(Federation.new(election: election, name: 'School Federation', state: 'unknown')).not_to be_valid
  end

  it 'links a registered party while keeping its election explicit' do
    membership = FederationMembership.create!(federation: federation, party: party)
    expect(membership.election_id).to eq(election.id)
    expect(federation.parties).to include(party)
    expect(membership.party_id).to eq(party.id)
  end

  it 'rejects a party not registered in the federation election' do
    foreign_party = Party.create!(name: 'Foreign Federation Party', abbreviation: 'FFP', party_number: 42)
    ElectionPartyRegistration.create!(election: other_election, party: foreign_party, ballot_number: '42')
    expect(FederationMembership.new(federation: federation, party: foreign_party)).not_to be_valid
  end

  it 'prevents the same party from joining two federations in one election' do
    FederationMembership.create!(federation: federation, party: party)
    other = Federation.create!(election: election, name: 'Second Federation', state: 'active')
    expect(FederationMembership.new(federation: other, party: party)).not_to be_valid
  end

  it 'permits independent membership when a legacy party is registered in another election' do
    FederationMembership.create!(federation: federation, party: party)
    ElectionPartyRegistration.create!(election: other_election, party: party, ballot_number: '41')
    other = Federation.create!(election: other_election, name: 'Independent Federation', state: 'active')
    expect(FederationMembership.create!(federation: other, party: party).election_id).to eq(other_election.id)
  end

  it 'protects duplicate party membership even when model validation is bypassed' do
    FederationMembership.create!(federation: federation, party: party)
    other = Federation.create!(election: election, name: 'Second Federation', state: 'active')
    expect do
      raw_membership(federation_id: other.id, election_id: election.id, party_id: party.id)
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'protects party registration in the database when validation is bypassed' do
    foreign_party = Party.create!(name: 'Foreign Federation Party', abbreviation: 'FFP', party_number: 42)
    expect do
      raw_membership(federation_id: federation.id, election_id: election.id, party_id: foreign_party.id)
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it 'protects the federation election reference in the database' do
    ElectionPartyRegistration.create!(election: other_election, party: party, ballot_number: '41')
    expect do
      raw_membership(federation_id: federation.id, election_id: other_election.id, party_id: party.id)
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
