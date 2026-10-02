# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'Opening configuration requirements' do
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

  [
    ['election timezone', 'invalid_timezone', 'timezone'],
    ['school timezone fallback', 'invalid_timezone', 'timezone'],
    ['contest rule version', 'invalid_rule_version', 'rule version']
  ].each do |setting, code, message|
    def corrupt_setting(setting)
      case setting
      when 'election timezone' then election.update_columns(timezone: 'Invalid/Timezone')
      when 'school timezone fallback' then installation.update_columns(timezone: 'Invalid/Timezone')
      when 'contest rule version' then contest.update_columns(rule_version: ' ')
      end
    end

    it "reports invalid #{setting} in preview without a ballot or operational side effects" do
      corrupt_setting(setting)
      before_state = [round.reload.attributes, ConfigurationSnapshot.count, VotingStage.count,
                      RoundContest.count, RoundCandidacy.count, AuditEvent.count]
      preview = Configuration::PreviewElection.call(election: election, actor: creator)
      expect(preview.fetch(:valid)).to be(false)
      expect(preview.fetch(:issues)).to include(a_hash_including(code: code))
      expect(preview.fetch(:ballot)).to be_nil
      expect(preview.fetch(:stages)).to eq([])
      expect([round.reload.attributes, ConfigurationSnapshot.count, VotingStage.count,
              RoundContest.count, RoundCandidacy.count, AuditEvent.count]).to eq(before_state)
    end

    it "rejects opening with invalid #{setting} without partially freezing configuration" do
      corrupt_setting(setting)
      before_state = [round.reload.attributes, ConfigurationSnapshot.count, VotingStage.count,
                      RoundContest.count, RoundCandidacy.count, AuditEvent.count]
      expect { Voting::OpenRound.call(round: round, actor: creator) }
        .to raise_error(Voting::OpenRound::InvalidConfiguration, /#{message}/)
      expect([round.reload.attributes, ConfigurationSnapshot.count, VotingStage.count,
              RoundContest.count, RoundCandidacy.count, AuditEvent.count]).to eq(before_state)
    end
  end

  it 'documents timezone and rule version issues in the preview contract' do
    document = YAML.safe_load_file(Rails.root.join('openapi/v1.yaml'))
    codes = document.dig('components', 'schemas', 'ElectionPreview', 'properties', 'issues',
                         'items', 'properties', 'code', 'enum')
    expect(codes).to include('invalid_timezone', 'invalid_rule_version')
  end
end
