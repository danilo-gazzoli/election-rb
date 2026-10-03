# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe 'Pilot operator commands' do
  include_context 'an opened school voting round'

  def finish
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'export-final',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    Voting::PublishReport.call(election: election, actor: creator)
  end

  it 'exports exactly the published public projection and does not overwrite another file' do
    finish
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'report.json')
      Operations::ExportReport.call(election: election, path: path)
      expect(JSON.parse(File.read(path))).to eq(Voting::PublicReport.call(election: election))
      expect(File.stat(path).mode & 0o777).to eq(0o600)
      expect(File.read(path)).not_to match(/session_id|credential|receipt_id|occurred_at/)
      expect { Operations::ExportReport.call(election: election, path: path) }.to raise_error(Errno::EEXIST)
    end
  end

  it 'refuses export before publication without creating a misleading final report' do
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'report.json')
      expect { Operations::ExportReport.call(election: election, path: path) }
        .to raise_error(Voting::FinalReport::NotReady)
      expect(File.exist?(path)).to be(false)
    end
  end

  it 'exports the selected immutable historical version' do
    finish
    first = ReportVersion.sole
    Incident.create!(round: round, user: creator, kind: 'technical', reason: 'Private note', occurred_at: now)
    Voting::PublishReport.call(election: election, actor: creator)
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'old.json')
      Operations::ExportReport.call(election: election, path: path, version: first.version)
      expect(JSON.parse(File.read(path)).fetch('version')).to eq(1)
      expect(JSON.parse(File.read(path)).fetch('occurrences')).to eq([])
    end
  end

  it 'checks reconciliation and reproduces recorded published tallies without changing the database' do
    finish
    expect { expect(Operations::Verify.call.fetch(:status)).to eq('ok') }.not_to change(AuditEvent, :count)
    run = TallyRun.sole
    TallyRun.create!(round_contest: run.round_contest, input_digest: run.input_digest, state: 'final',
                    algorithm_version: run.algorithm_version, calculation: run.calculation,
                    totals: run.totals.merge('elected_ids' => []), created_at: run.created_at + 1.second)
    result = Operations::Verify.call
    expect(result.fetch(:status)).to eq('failed')
    expect(result.fetch(:issues).first.fetch(:reason)).to match(/differs/)
  end

  it 'reports reconciliation failure rather than repairing or deleting votes' do
    confirm_first_vote
    Voting::Abandon.call(session: voting_session, actor: creator, reason: 'Voter left', now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    CastVote.create!(round: round, contest: contest, voting_stage: first_stage,
                     kind: 'blank', origin: 'confirmation')
    expect { expect(Operations::Verify.call.fetch(:status)).to eq('failed') }.not_to change(CastVote, :count)
  end
end

RSpec.describe 'Pilot installation provisioning' do
  def provision(**options)
    Operations::ProvisionCreator.call(identifier: 'pilot-school', school_name: 'Pilot School',
                                       timezone: 'America/Sao_Paulo', login: 'teacher', name: 'Teacher', **options)
  end

  def activate(result, **options)
    Operations::ProvisionCreator.activate(user: result.user, credential: result.credential,
                                          password: 'long-random-password', **options)
  end

  it 'generates a hashed initial credential and activates the first creator by consuming it once' do
    result = provision
    user = result.user
    expect(user).to have_attributes(active: false, can_create_elections: true, login: 'teacher')
    expect(result.credential.length).to be >= 24
    expect(user.authenticate(result.credential)).to eq(user)
    expect(user.password_digest).not_to eq(result.credential)
    expect(user.school_installation).to have_attributes(identifier: 'pilot-school', timezone: 'America/Sao_Paulo')
    activate(result)
    expect(user.reload.active).to be(true)
    expect(user.authenticate('long-random-password')).to eq(user)
    expect(user.authenticate(result.credential)).to be(false)
    expect { activate(result) }.to raise_error(Operations::ProvisionCreator::NotAllowed)
  end

  it 'refuses invalid activation without changing the initial account' do
    result = provision
    original = result.user.attributes
    expect { activate(result, credential: 'invalid') }.to raise_error(Operations::ProvisionCreator::NotAllowed)
    expect { activate(result, password: result.credential) }.to raise_error(ArgumentError)
    expect { activate(result, password: 'short') }.to raise_error(ArgumentError)
    expect(result.user.reload.attributes).to eq(original)
  end

  it 'refuses repeated bootstrap without altering credentials or creating another installation' do
    first = provision
    original = first.user.attributes
    expect { provision(login: 'another') }.to raise_error(Operations::ProvisionCreator::NotAllowed)
    expect(first.user.reload.attributes).to eq(original)
    expect(SchoolInstallation.count).to eq(1)
    expect(User.count).to eq(1)
  end

  it 'rolls back bootstrap for an unknown timezone or missing login' do
    expect { provision(timezone: 'Invalid/Clock') }.to raise_error(ArgumentError)
    expect { provision(login: '') }.to raise_error(ActiveRecord::RecordInvalid)
    expect(User.count).to eq(0)
    expect(SchoolInstallation.count).to eq(0)
  end
end
