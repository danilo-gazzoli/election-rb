# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::Confirm do
  let(:installation) { SchoolInstallation.create!(identifier: 'school-a', name: 'School A') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'A school election for the integration test',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft',
                  opens_at: 1.hour.ago, closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:round_contest) { RoundContest.create!(round: round, contest: contest) }
  let!(:first_stage) do
    VotingStage.create!(round: round, round_contest: round_contest, global_position: 1, choice_index: 1)
  end
  let!(:second_stage) do
    VotingStage.create!(round: round, round_contest: round_contest, global_position: 2, choice_index: 2)
  end
  let(:party) do
    Party.create!(name: 'Sample Party A', abbreviation: 'SPA', party_number: 31)
  end
  let!(:registration) do
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '31')
  end
  let(:first_candidate) do
    registration
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate A'),
                      principal_party: party, ballot_number: '311')
  end
  let(:second_candidate) do
    registration
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate B'),
                      principal_party: party, ballot_number: '312')
  end
  let!(:first_round_candidacy) do
    RoundCandidacy.create!(round: round, candidacy: first_candidate)
  end
  let!(:second_round_candidacy) do
    RoundCandidacy.create!(round: round, candidacy: second_candidate)
  end
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Device A',
                         credential_digest: 'digest', state: 'released')
  end
  let(:session) { VotingSession.create!(round: round, voting_device: device, released_at: Time.current) }

  let(:pollworker) do
    User.create!(school_installation: installation, name: 'Pollworker', login: 'pollworker',
                 password: 'long-random-password')
  end

  before do
    first_stage
    second_stage
    first_round_candidacy
    second_round_candidacy
    ElectionRole.create!(election: election, user: pollworker, role: 'pollworker')
    round.update!(state: 'open')
  end

  def confirm(stage, candidate, key, acknowledged: false)
    described_class.call(session: session, stage_id: stage.id, command_key: key,
                         kind: 'nominal', candidacy_id: candidate.id,
                         warning_acknowledged: acknowledged, secret: 'test-secret')
  end

  it 'commits one vote and one receipt, then replays without replacing the choice' do
    first = confirm(first_stage, first_candidate, 'cmd-1')
    replay = confirm(first_stage, second_candidate, 'cmd-1')
    different_key = confirm(first_stage, second_candidate, 'cmd-other')

    expect([first.status, replay.status, different_key.status]).to eq(%i[confirmed confirmed confirmed])
    expect([replay.receipt_id, different_key.receipt_id]).to eq([first.receipt_id, first.receipt_id])
    expect(CastVote.count).to eq(1)
    expect(CastVote.first.candidacy_id).to eq(first_candidate.id)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(session.reload.current_stage_position).to eq(2)
  end

  it 'rolls back the vote if persisting its receipt fails' do
    allow(ConfirmationReceipt).to receive(:create!)
      .and_raise(ActiveRecord::RecordNotUnique, 'simulated receipt conflict')

    expect { confirm(first_stage, first_candidate, 'cmd-1') }
      .to raise_error(ActiveRecord::RecordNotUnique)
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
    expect(session.reload.current_stage_position).to eq(1)
    expect(session.state).to eq('released')
  end

  it 'warns before repeating the first candidate and only then records a null second vote' do
    confirm(first_stage, first_candidate, 'cmd-1')
    warning = confirm(second_stage, first_candidate, 'cmd-2')

    expect(warning.status).to eq(:warning_required)
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(session.reload.current_stage_position).to eq(2)

    accepted = confirm(second_stage, first_candidate, 'cmd-2', acknowledged: true)
    expect(accepted.status).to eq(:confirmed)
    expect(CastVote.order(:kind).pluck(:kind)).to eq(%w[nominal null])
    expect(CastVote.where(kind: 'nominal').first.candidacy_id).to eq(first_candidate.id)
    expect(session.reload.state).to eq('completed')
    expect(session.first_choice_fingerprint).to be_nil
  end

  it 'notifies the device only after a durable second-stage confirmation' do
    confirm(first_stage, first_candidate, 'cmd-1')
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once
    expect(confirm(second_stage, first_candidate, 'cmd-2').status).to eq(:warning_required)
    confirm(second_stage, first_candidate, 'cmd-2', acknowledged: true)
  end

  it 'returns the durable receipt and permits replay when the notification transport fails' do
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError, 'transport unavailable')
    result = nil

    expect { result = confirm(first_stage, first_candidate, 'cmd-1') }.not_to raise_error
    expect(result.status).to eq(:confirmed)
    expect(confirm(first_stage, first_candidate, 'cmd-1').receipt_id).to eq(result.receipt_id)
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(session.reload.current_stage_position).to eq(2)
  end

  it 'preserves a committed abandonment when the notification transport fails' do
    confirm(first_stage, first_candidate, 'cmd-1')
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError, 'transport unavailable')

    expect { Voting::Abandon.call(session: session, actor: pollworker, reason: 'voter left') }.not_to raise_error
    expect(session.reload.state).to eq('abandoned')
    expect(session.first_choice_fingerprint).to be_nil
    expect(device.reload.state).to eq('locked')
    expect(CastVote.where(kind: 'nominal', candidacy: first_candidate).count).to eq(1)
    expect(CastVote.where(kind: 'null', origin: 'abandonment').count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
  end

  it 'keeps distinct second candidacies nominal and clears transient progress' do
    confirm(first_stage, first_candidate, 'cmd-1')
    confirm(second_stage, second_candidate, 'cmd-2')
    expect(CastVote.where(kind: 'nominal').count).to eq(2)
    expect(session.reload.first_choice_fingerprint).to be_nil
  end

  %w[blank null].each do |first_kind|
    it "accepts a nominal second choice after a #{first_kind} first choice" do
      described_class.call(session: session, stage_id: first_stage.id, command_key: 'cmd-1',
                           kind: first_kind, secret: 'test-secret')
      expect(session.reload.first_choice_fingerprint).to be_nil

      result = confirm(second_stage, first_candidate, 'cmd-2')
      expect(result.status).to eq(:confirmed)
      expect(CastVote.order(:voting_stage_id).pluck(:kind)).to contain_exactly(first_kind, 'nominal')
    end
  end

  it 'lets the voter choose another candidate after declining a repetition warning' do
    confirm(first_stage, first_candidate, 'cmd-1')
    expect(confirm(second_stage, first_candidate, 'cmd-2').status).to eq(:warning_required)

    result = confirm(second_stage, second_candidate, 'cmd-2')
    expect(result.status).to eq(:confirmed)
    expect(CastVote.where(kind: 'nominal').pluck(:candidacy_id))
      .to match_array([first_candidate.id, second_candidate.id])
    expect(session.reload.first_choice_fingerprint).to be_nil
  end

  it 'replays the second confirmed choice without adding a vote or warning' do
    confirm(first_stage, first_candidate, 'cmd-1')
    first = confirm(second_stage, first_candidate, 'cmd-2', acknowledged: true)
    replay = confirm(second_stage, first_candidate, 'cmd-2')
    different_key = confirm(second_stage, first_candidate, 'cmd-3')

    expect([replay.receipt_id, different_key.receipt_id]).to eq([first.receipt_id, first.receipt_id])
    expect(CastVote.count).to eq(2)
    expect(ConfirmationReceipt.count).to eq(2)
  end

  it 'rejects voting outside the current stage and duplicate command keys on a later stage' do
    expect { confirm(second_stage, first_candidate, 'cmd-2') }.to raise_error(Voting::Confirm::Conflict)
    confirm(first_stage, first_candidate, 'cmd-1')
    expect { confirm(second_stage, second_candidate, 'cmd-1') }.to raise_error(Voting::Confirm::Conflict)
    expect(CastVote.count).to eq(1)
  end

  it 'keeps the first vote and adds one administrative null on abandonment' do
    confirm(first_stage, first_candidate, 'cmd-1')
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Person left before finishing')
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Repeated request')

    expect(CastVote.where(origin: 'confirmation').count).to eq(1)
    expect(CastVote.where(origin: 'abandonment', kind: 'null').count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(session.reload.first_choice_fingerprint).to be_nil
    expect(session.state).to eq('abandoned')
    expect(device.reload.state).to eq('locked')
  end

  it 'notifies the device when an unfinished session is abandoned' do
    confirm(first_stage, first_candidate, 'cmd-1')
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once

    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Person left before finishing')
  end

  it 'cancels a released but unstarted session without counting any votes' do
    session
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Release cancelled')
    expect(session.reload.state).to eq('cancelled')
    expect(CastVote.count).to eq(0)
  end

  it 'shows only aggregate partial percentages and no winner while voting is open' do
    confirm(first_stage, first_candidate, 'cmd-1')
    partial = Voting::PartialResult.call(round_contest: round_contest)

    expect(partial.fetch(:status)).to eq('partial')
    expect(partial.fetch(:participation)).to eq(1)
    expect(partial.fetch(:nominal_votes)).to eq(1)
    expect(partial.fetch(:candidates)).to include(
      { candidacy_id: first_candidate.id, votes: 1, percentage: 100.0 }
    )
    expect(partial).not_to have_key(:winner)
    expect(partial.to_s).not_to include(session.id)
  end

  it 'reports confirmed nominal and repeated-choice null votes in their respective stages' do
    confirm(first_stage, first_candidate, 'cmd-1')
    confirm(second_stage, first_candidate, 'cmd-2', acknowledged: true)

    stages = Voting::PartialResult.call(round_contest: round_contest).fetch(:stages)
    expect(stages).to eq([
      { stage_id: first_stage.id, choice_index: 1, nominal_votes: 1, blank_votes: 0,
        null_votes: 0, administrative_null_votes: 0 },
      { stage_id: second_stage.id, choice_index: 2, nominal_votes: 0, blank_votes: 0,
        null_votes: 1, administrative_null_votes: 0 }
    ])
  end

  it 'counts both stages for a simple-majority tally after the round closes' do
    confirm(first_stage, first_candidate, 'cmd-1')
    confirm(second_stage, second_candidate, 'cmd-2')
    round.update!(state: 'closed')

    result = Voting::SimpleMajorityTally.call(round_contest: round_contest)
    expect(result.fetch(:status)).to eq('final')
    expect(result.fetch(:elected_ids)).to match_array([first_candidate.id, second_candidate.id])
    expect(result.fetch(:valid_votes)).to eq(2)
  end

  it 'keeps a tally pending when receipts and confirmed votes disagree by stage' do
    ConfirmationReceipt.create!(voting_session: session, voting_stage: first_stage,
                                command_key: 'cmd-1', confirmed_at: Time.current)
    ConfirmationReceipt.create!(voting_session: session, voting_stage: second_stage,
                                command_key: 'cmd-2', confirmed_at: Time.current)
    CastVote.create!(round: round, contest: contest, voting_stage: first_stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: first_candidate)
    CastVote.create!(round: round, contest: contest, voting_stage: first_stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: second_candidate)
    round.update!(state: 'closed')

    result = Voting::SimpleMajorityTally.call(round_contest: round_contest)
    expect(result.fetch(:status)).to eq('pending')
    expect(result.fetch(:reason)).to match(/stage/)
  end

  it 'rejects direct SQL changes to confirmed votes' do
    confirm(first_stage, first_candidate, 'cmd-1')
    expect { CastVote.update_all(kind: 'null', candidacy_id: nil) }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { CastVote.delete_all }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'closes and stores a reconciled final tally after the grace period' do
    confirm(first_stage, first_candidate, 'cmd-1')
    confirm(second_stage, second_candidate, 'cmd-2')
    creator = User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                           password: 'long-random-password')
    ElectionRole.create!(election: election, user: creator, role: 'creator')

    expect do
      Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.minute)
    end.to change(TallyRun, :count).by(1)

    expect(round.reload.state).to eq('closed')
    tally = TallyRun.last
    expect(tally.state).to eq('final')
    expect(tally.totals.fetch('elected_ids')).to match_array([first_candidate.id, second_candidate.id])
    expect { tally.update_columns(state: 'pending') }.to raise_error(ActiveRecord::StatementInvalid)
  end

  context 'with concurrent database connections' do
    self.use_transactional_tests = false

    before(:context) { DatabaseCleaner.strategy = :truncation }
    after(:context) { DatabaseCleaner.strategy = :transaction }

    it 'records one vote and receipt when two requests confirm the same stage together' do
      session_id = session.id
      stage_id = first_stage.id
      candidacy_id = first_candidate.id
      ready = Queue.new
      start = Queue.new

      workers = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            connection_id = ActiveRecord::Base.connection.object_id
            ready << true
            start.pop
            result = described_class.call(session: VotingSession.find(session_id), stage_id: stage_id,
                                          command_key: 'same-command', kind: 'nominal', candidacy_id: candidacy_id,
                                          secret: 'test-secret')
            [connection_id, result]
          end
        end
      end
      2.times { ready.pop }
      2.times { start << true }
      connection_ids, results = workers.map(&:value).transpose

      expect(connection_ids.uniq.size).to eq(2)
      expect(results.map(&:status)).to eq(%i[confirmed confirmed])
      expect(results.map(&:receipt_id).uniq.size).to eq(1)
      expect(CastVote.count).to eq(1)
      expect(ConfirmationReceipt.count).to eq(1)
      expect(session.reload.current_stage_position).to eq(2)
    end

    it 'records only one of two different second choices submitted together' do
      confirm(first_stage, first_candidate, 'cmd-1')
      session_id = session.id
      stage_id = second_stage.id
      choices = [[first_candidate.id, 'cmd-2'], [second_candidate.id, 'cmd-3']]
      ready = Queue.new
      start = Queue.new

      workers = choices.map do |candidate_id, key|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            start.pop
            described_class.call(session: VotingSession.find(session_id), stage_id: stage_id,
                                 command_key: key, kind: 'nominal', candidacy_id: candidate_id,
                                 warning_acknowledged: true, secret: 'test-secret')
          end
        end
      end
      2.times { ready.pop }
      2.times { start << true }
      results = workers.map(&:value)

      expect(results.map(&:receipt_id).uniq.size).to eq(1)
      expect(CastVote.count).to eq(2)
      expect(ConfirmationReceipt.count).to eq(2)
      expect(session.reload.state).to eq('completed')
      expect(session.first_choice_fingerprint).to be_nil
    end
  end
end
