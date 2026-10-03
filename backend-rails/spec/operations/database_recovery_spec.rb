# frozen_string_literal: true

require 'rails_helper'
require 'open3'
require 'pg'
require 'tmpdir'

RSpec.describe 'Pilot database backup and recovery' do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false
  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }

  let(:script) { Rails.root.join('../deployment/pilot/database.sh').to_s }
  let(:db_config) { ActiveRecord::Base.connection_db_config.configuration_hash }
  let(:target_name) { "election_f12_restore_#{Process.pid}_#{SecureRandom.hex(3)}" }

  around do |example|
    Dir.mktmpdir('election-f12') do |directory|
      @archive = File.join(directory, 'school.dump')
      @source = PG.connect(db_config.slice(:host, :port, :username, :password).transform_keys { |key|
        key == :username ? :user : key
      }.merge(dbname: db_config.fetch(:database)))
      @source.exec("CREATE DATABASE #{PG::Connection.quote_ident(target_name)}")
      begin
        @target = PG.connect(db_config.slice(:host, :port, :username, :password).transform_keys { |key|
          key == :username ? :user : key
        }.merge(dbname: target_name))
        example.run
      ensure
        @target&.close
        @source.exec("DROP DATABASE #{PG::Connection.quote_ident(target_name)}")
        @source.close
      end
    end
  end

  def command(action, database:, **extra)
    env = { 'DB_HOST' => db_config[:host].to_s, 'DB_PORT' => db_config.fetch(:port, 5432).to_s,
            'DB_USERNAME' => db_config[:username].to_s, 'DB_PASSWORD' => db_config[:password].to_s,
            'DB_NAME_PROD' => database }.merge(extra.transform_keys(&:to_s))
    Open3.capture3(env, 'bash', script, action, @archive)
  end

  def backup
    _, error, result = command('backup', database: db_config.fetch(:database))
    expect(result.success?).to be(true), error
  end

  it 'restores votes, receipts, frozen configuration and published results into another database' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'recovery-final',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    Voting::PublishReport.call(election: election, actor: creator)
    expected = Voting::PublicReport.call(election: election)
    backup
    expect(File.stat(@archive).mode & 0o777).to eq(0o600)
    _, error, result = command('restore', database: target_name)
    expect(result.success?).to be(true), error
    %w[cast_votes confirmation_receipts configuration_snapshots tally_runs report_versions].each do |table|
      expect(@target.exec("SELECT COUNT(*) FROM #{table}").first.fetch('count').to_i)
        .to eq(ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i)
    end
    code = "puts JSON.generate(check: Operations::Verify.call, report: Voting::PublicReport.call(election: Election.find(#{election.id})))"
    output, error, result = Open3.capture3({ 'DB_NAME_TEST' => target_name }, 'bundle', 'exec', 'rails', 'runner', code)
    expect(result.success?).to be(true), error
    data = JSON.parse(output.lines.last)
    expect(data.fetch('check').fetch('status')).to eq('ok')
    expect(data.fetch('report')).to eq(JSON.parse(JSON.generate(expected)))
  end

  it 'refuses a corrupt archive before writing to the destination' do
    backup
    File.open(@archive, 'ab') { |file| file.write('corrupt') }
    _, error, result = command('restore', database: target_name)
    expect(result.success?).to be(false)
    expect(error).to match(/checksum/i)
    expect(@target.exec("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'").first.fetch('count')).to eq('0')
  end

  it 'never overwrites a populated database during restoration' do
    backup
    @target.exec('CREATE TABLE preserved (value integer)')
    @target.exec('INSERT INTO preserved VALUES (7)')
    _, error, result = command('restore', database: target_name)
    expect(result.success?).to be(false)
    expect(error).to match(/empty/i)
    expect(@target.exec('SELECT value FROM preserved').first.fetch('value')).to eq('7')
  end

  it 'keeps an existing backup and does not label a failed dump as successful' do
    File.write(@archive, 'previous backup')
    _, _, result = command('backup', database: db_config.fetch(:database))
    expect(result.success?).to be(false)
    expect(File.read(@archive)).to eq('previous backup')
    File.delete(@archive)
    _, _, result = command('backup', database: db_config.fetch(:database), DB_HOST: '/missing-f12-socket')
    expect(result.success?).to be(false)
    expect(File.exist?(@archive)).to be(false)
    expect(File.exist?("#{@archive}.sha256")).to be(false)
  end
end
