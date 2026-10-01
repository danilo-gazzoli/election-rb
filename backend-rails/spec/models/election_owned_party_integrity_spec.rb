# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Election-owned party integrity' do
  let(:installation) { SchoolInstallation.create!(identifier: 'party-integrity', name: 'Party Integrity School') }
  let(:election) { create_election('School Election') }
  let(:other_election) { create_election('Other Election') }
  let(:party) do
    Party.create!(election: election, name: 'School Example Party', abbreviation: 'SEP', ballot_number: '31')
  end

  def create_election(title)
    Election.create!(school_installation: installation, title: title,
                     description: 'An election for party integrity', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end

  def open_round
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end

  it 'prevents direct party mutation after a round opens' do
    party
    open_round
    expect do
      Party.transaction(requires_new: true) { party.update_columns(name: 'Changed School Party') }
    end.to raise_error(ActiveRecord::StatementInvalid, /immutable/)
    expect(party.reload.name).to eq('School Example Party')
  end

  it 'prevents direct owned-party insertion after a round opens' do
    open_round
    expect do
      Party.transaction(requires_new: true) do
        Party.create!(election: election, name: 'School Example Party', abbreviation: 'SEP', ballot_number: '31')
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /immutable/)
    expect(Party.count).to eq(0)
  end

  it 'validates that an owned party cannot register in another election' do
    registration = ElectionPartyRegistration.new(election: other_election, party: party, ballot_number: '31')
    expect(registration).not_to be_valid
    expect(registration.errors[:party]).not_to be_empty
  end

  it 'enforces ownership even when registration validations are skipped' do
    registration = ElectionPartyRegistration.new(election: other_election, party: party, ballot_number: '31')
    expect do
      ElectionPartyRegistration.transaction(requires_new: true) { registration.save!(validate: false) }
    end.to raise_error(ActiveRecord::StatementInvalid, /party.*election/)
    expect(ElectionPartyRegistration.count).to eq(0)
  end

  it 'enforces scoped abbreviation uniqueness even when validations are skipped' do
    party
    duplicate = Party.new(election: election, name: 'Another School Party', abbreviation: 'SEP',
                          ballot_number: '32', party_number: 32)
    expect do
      Party.transaction(requires_new: true) { duplicate.save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
    expect(Party.count).to eq(1)
  end

  it 'enforces canonical number consistency even when validations are skipped' do
    party
    expect do
      Party.transaction(requires_new: true) { party.update_columns(ballot_number: '32', party_number: 31) }
    end.to raise_error(ActiveRecord::StatementInvalid, /owned_party_canonical_number/)
    expect(party.reload.ballot_number).to eq('31')
  end
end
