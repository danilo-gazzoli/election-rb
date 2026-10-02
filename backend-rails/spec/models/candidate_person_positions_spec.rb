# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate person positions within a contest' do
  let(:installation) { SchoolInstallation.create!(identifier: 'person-positions', name: 'Person Positions School') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'Election for candidate person compatibility',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'School Presidency', position: 1, method: 'simple_majority',
                    seats: 1, choices_per_person: 1, has_vice: true)
  end
  let(:party) do
    Party.create!(name: 'Person Positions Party', abbreviation: 'PPP', party_number: 46).tap do |party|
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '46')
    end
  end
  let!(:existing) do
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Existing Principal'),
                      vice_person: CandidatePerson.create!(name: 'Existing Vice'), principal_party: party,
                      vice_party: party, ballot_number: '461')
  end

  def another_candidate(target_contest = contest)
    Candidacy.new(contest: target_contest, principal_person: CandidatePerson.create!(name: 'Another Principal'),
                  vice_person: CandidatePerson.create!(name: 'Another Vice'), principal_party: party,
                  vice_party: party, ballot_number: '462')
  end

  def insert_without_validations(candidate)
    Candidacy.insert_all!([candidate.attributes.except('id', 'created_at', 'updated_at')])
  end

  it 'rejects the same person as principal and vice in the model' do
    candidate = another_candidate
    candidate.vice_person = candidate.principal_person
    expect(candidate).not_to be_valid
  end

  it 'rejects the same person as principal and vice in PostgreSQL without model validation' do
    candidate = another_candidate
    candidate.vice_person = candidate.principal_person
    expect { Candidacy.transaction(requires_new: true) { insert_without_validations(candidate) } }
      .to raise_error(ActiveRecord::StatementInvalid, /incompatible/)
  end

  %i[principal_person vice_person].product(%i[principal_person vice_person]).each do |existing_role, new_role|
    it "rejects reusing #{existing_role} as #{new_role} in another candidature of the same contest" do
      candidate = another_candidate
      candidate.public_send("#{new_role}=", existing.public_send(existing_role))
      expect(candidate).not_to be_valid
    end

    it "rejects direct SQL reusing #{existing_role} as #{new_role} within the same contest" do
      candidate = another_candidate
      candidate.public_send("#{new_role}=", existing.public_send(existing_role))
      expect { Candidacy.transaction(requires_new: true) { insert_without_validations(candidate) } }
        .to raise_error(ActiveRecord::StatementInvalid, /incompatible/)
    end
  end

  it 'permits sharing a person with another contest without changing the original identity' do
    other = Contest.create!(election: election, name: 'Other Presidency', position: 2,
                            method: 'simple_majority', seats: 1, choices_per_person: 1, has_vice: true)
    candidate = another_candidate(other)
    candidate.principal_person = existing.vice_person
    expect(candidate).to be_valid
    candidate.save!
    expect(candidate.reload.principal_person_id).to eq(existing.vice_person_id)
    expect(existing.reload.vice_person.name).to eq('Existing Vice')
  end

  it 'allows editing a candidacy without treating its own people as another candidature' do
    existing.update!(ballot_number: '463')
    expect(existing.reload.ballot_number).to eq('463')
    expect(existing).to be_valid
  end

  it 'rejects direct SQL person replacement with someone used by another candidature' do
    candidate = another_candidate
    candidate.save!
    before_state = candidate.attributes
    expect do
      Candidacy.transaction(requires_new: true) do
        candidate.update_columns(vice_person_id: existing.principal_person_id)
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /incompatible/)
    expect(candidate.reload.attributes).to eq(before_state)
  end
end
