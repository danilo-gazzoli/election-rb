# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Frozen federation database integrity' do
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

  let!(:federation) do
    federation = Federation.create!(election: election, name: 'Frozen Federation', state: 'active')
    party = Party.create!(name: 'Second Frozen Party', abbreviation: 'SFP', party_number: 48)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '48')
    [Party.find_by!(abbreviation: 'OTP'), party].each do |member|
      FederationMembership.create!(federation: federation, party: member)
    end
    federation
  end
  let!(:spare_party) do
    party = Party.create!(name: 'Spare Frozen Party', abbreviation: 'SXP', party_number: 49)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '49')
    party
  end
  let!(:snapshot) { Voting::OpenRound.call(round: round, actor: creator) }

  def frozen_state
    [Federation.order(:id).map(&:attributes), FederationMembership.order(:id).map(&:attributes),
     snapshot.reload.canonical_data, snapshot.digest, round.reload.state,
     election.reload.configuration_version, AuditEvent.count]
  end

  def rejects_frozen_change
    before_state = frozen_state
    expect { Federation.transaction(requires_new: true) { yield } }
      .to raise_error(ActiveRecord::StatementInvalid, /immutable/)
    expect(frozen_state).to eq(before_state)
  end

  def other_draft_federation
    other = Election.create!(school_installation: installation, creator: creator, title: 'Other Draft Election',
                             description: 'An independent election for federation ownership', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    ElectionPartyRegistration.create!(election: other, party: spare_party, ballot_number: '49')
    Federation.create!(election: other, name: 'Other Draft Federation', state: 'inactive')
  end

  it 'rejects metadata changes that bypass model validation after opening' do
    rejects_frozen_change { federation.update_columns(name: 'Changed Frozen Federation') }
  end

  it 'rejects direct federation insertion after opening' do
    rejects_frozen_change { Federation.create!(election: election, name: 'Late Federation', state: 'inactive') }
  end

  it 'rejects direct federation deletion before any foreign-key deletion can proceed' do
    rejects_frozen_change { Federation.where(id: federation.id).delete_all }
  end

  it 'rejects direct member insertion after opening' do
    rejects_frozen_change { FederationMembership.create!(federation: federation, party: spare_party) }
  end

  it 'rejects member party replacement that bypasses validations after opening' do
    member = federation.federation_memberships.order(:id).first
    rejects_frozen_change { member.update_columns(party_id: spare_party.id) }
  end

  it 'rejects direct member deletion after opening' do
    member = federation.federation_memberships.order(:id).first
    rejects_frozen_change { FederationMembership.where(id: member.id).delete_all }
  end

  it 'rejects moving a draft membership into an opened election' do
    other = other_draft_federation
    member = FederationMembership.create!(federation: other, party: spare_party)
    rejects_frozen_change { member.update_columns(federation_id: federation.id, election_id: election.id) }
  end

  it 'rejects moving an opened membership into a draft election' do
    other = other_draft_federation
    member = federation.federation_memberships.order(:id).first
    ElectionPartyRegistration.create!(election: other.election, party: member.party, ballot_number: member.party.party_number.to_s)
    rejects_frozen_change { member.update_columns(federation_id: other.id, election_id: other.election_id) }
  end

  it 'allows changes to an independent draft election while preserving the opened snapshot' do
    other = other_draft_federation
    canonical = snapshot.canonical_data
    digest = snapshot.digest
    other.update!(name: 'Updated Independent Federation')
    FederationMembership.create!(federation: other, party: spare_party)
    expect(other.reload.name).to eq('Updated Independent Federation')
    expect(snapshot.reload.canonical_data).to eq(canonical)
    expect(snapshot.digest).to eq(digest)
  end
end
