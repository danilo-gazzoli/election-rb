# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Configuration and opening with concurrent PostgreSQL connections', type: :service do
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
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

  before { @workers = [] }
  after do
    @workers.each do |worker|
      next if worker.join(8)

      worker.kill
      worker.join
    end
  end

  def take(queue)
    Timeout.timeout(5) { queue.pop }
  end

  def worker(&operation)
    ready = Queue.new
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute("SET lock_timeout = '5s'")
        ready << connection.select_value('SELECT pg_backend_pid()').to_i
        begin
          operation.call
        rescue StandardError => error
          error
        ensure
          connection.execute("SET lock_timeout = '0'")
        end
      end
    end
    @workers << thread
    [thread, take(ready)]
  end

  def wait_for_database_lock(pid)
    Timeout.timeout(4) do
      loop do
        blocked = ActiveRecord::Base.uncached do
          ActiveRecord::Base.connection.select_value(
            "SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))"
          ).to_i.positive?
        end
        break if blocked

        Thread.pass
      end
    end
  end

  def result_of(thread)
    raise 'Concurrent operation did not finish' unless thread.join(8)

    thread.value
  end

  it 'freezes the committed contest edit and current version when opening waits for that edit' do
    round_id = round.id
    creator_id = creator.id
    opening = nil

    election.with_lock('FOR NO KEY UPDATE') do
      Configuration::UpdateContest.call(election: election, contest_id: contest.id, actor: creator,
                                         attributes: { name: 'Updated Senate' })
      opening, pid = worker do
        Voting::OpenRound.call(round: Round.find(round_id), actor: User.find(creator_id))
      end
      wait_for_database_lock(pid)
    end

    result = result_of(opening)
    expect(result).not_to be_a(StandardError)
    expect(result.canonical_data.fetch('contests').first.fetch('name')).to eq('Updated Senate')
    expect(result.version).to eq(election.reload.configuration_version)
    expect(result.canonical_data.fetch('rule_version')).to eq(result.version)
    expect(ConfigurationSnapshot.where(round_id: round_id).count).to eq(1)
    expect(AuditEvent.where(action: 'contest_update').count).to eq(1)
    expect(AuditEvent.where(action: 'round_open').count).to eq(1)
  end

  it 'freezes the committed federation composition and current version when opening waits for replacement' do
    federation = configure_federation(2)
    replacement = Party.create!(name: 'Replacement Alliance Party', abbreviation: 'RAP', party_number: 49)
    ElectionPartyRegistration.create!(election: election, party: replacement, ballot_number: '49')
    members = [federation.parties.order(:id).first.id, replacement.id].sort
    round_id = round.id
    creator_id = creator.id
    opening = nil

    election.with_lock('FOR NO KEY UPDATE') do
      Configuration::ManageFederation.call(election: election, actor: creator, operation: :update,
                                           federation_id: federation.id, attributes: { party_ids: members })
      opening, pid = worker do
        Voting::OpenRound.call(round: Round.find(round_id), actor: User.find(creator_id))
      end
      wait_for_database_lock(pid)
    end

    result = result_of(opening)
    expect(result).not_to be_a(StandardError)
    expect(result.canonical_data.fetch('federations').first.fetch('party_ids')).to eq(members)
    expect(result.version).to eq(election.reload.configuration_version)
    expect(result.canonical_data.fetch('rule_version')).to eq(result.version)
    expect(AuditEvent.where(action: 'federation_update').count).to eq(1)
    expect(AuditEvent.where(action: 'round_open').count).to eq(1)
  end

  it 'rejects a contest edit queued behind opening without changing the catalog, version or audit' do
    election_id = election.id
    contest_id = contest.id
    creator_id = creator.id
    version = election.configuration_version
    editing = nil
    snapshot = nil

    round.with_lock do
      snapshot = Voting::OpenRound.call(round: round, actor: creator)
      editing, pid = worker do
        Configuration::UpdateContest.call(election: Election.find(election_id), contest_id: contest_id,
                                           actor: User.find(creator_id), attributes: { name: 'Late Edit' })
      end
      wait_for_database_lock(pid)
    end

    expect(result_of(editing)).to be_a(Configuration::UpdateContest::Locked)
    expect(contest.reload.name).to eq('Senate')
    expect(election.reload.configuration_version).to eq(version)
    expect(snapshot.reload.canonical_data.fetch('contests').first.fetch('name')).to eq('Senate')
    expect(AuditEvent.where(action: 'contest_update').count).to eq(0)
    expect(AuditEvent.where(action: 'round_open').count).to eq(1)
  end

  it 'commits only one snapshot and stage plan when two creators open the same round together' do
    round_id = round.id
    creator_id = creator.id
    start = Queue.new
    openings = 2.times.map do
      worker do
        take(start)
        Voting::OpenRound.call(round: Round.find(round_id), actor: User.find(creator_id))
      end.first
    end
    2.times { start << true }
    results = openings.map { |thread| result_of(thread) }

    expect(results.count { |result| result.is_a?(ConfigurationSnapshot) }).to eq(1)
    expect(results.count { |result| result.is_a?(Voting::OpenRound::NotAllowed) }).to eq(1)
    expect(round.reload.state).to eq('open')
    expect(ConfigurationSnapshot.where(round_id: round_id).count).to eq(1)
    expect(VotingStage.where(round_id: round_id).order(:global_position).pluck(:choice_index)).to eq([1, 2])
    expect(RoundCandidacy.where(round_id: round_id).count).to eq(2)
    expect(AuditEvent.where(action: 'round_open').count).to eq(1)
  end
end
