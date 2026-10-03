# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting method availability' do
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

  %w[proportional].each do |method|
    it "reports #{method} with an unsupported rule version in preview without altering the draft" do
      contest.update!(method: method, seats: 1, choices_per_person: 1)
      version = election.configuration_version
      result = Configuration::PreviewElection.call(election: election, actor: creator)
      expect(result.fetch(:valid)).to be(false)
      expect(result.fetch(:issues)).to include(
        a_hash_including(code: 'invalid_rule_version', contest_id: contest.id)
      )
      expect(result.fetch(:ballot)).to be_nil
      expect(result.fetch(:stages)).to be_empty
      expect(contest.reload.method).to eq(method)
      expect(round.reload.state).to eq('draft')
      expect(election.reload.configuration_version).to eq(version)
      expect(AuditEvent.count).to eq(0)
    end

    it "rejects opening #{method} with an unsupported rule version before creating any snapshot or voting records" do
      contest.update!(method: method, seats: 1, choices_per_person: 1)
      version = election.configuration_version
      expect { Voting::OpenRound.call(round: round, actor: creator) }
        .to raise_error(Voting::OpenRound::InvalidConfiguration, /rule version/)
      expect(round.reload.state).to eq('draft')
      expect(election.reload.configuration_version).to eq(version)
      expect(ConfigurationSnapshot.where(round: round)).to be_empty
      expect(VotingStage.where(round: round)).to be_empty
      expect(RoundContest.where(round: round)).to be_empty
      expect(RoundCandidacy.where(round: round)).to be_empty
      expect(AuditEvent.count).to eq(0)
    end
  end

  it 'makes an absolute-majority profile without a vice available with one choice stage' do
    contest.update!(method: 'absolute_majority', seats: 1, choices_per_person: 1, has_vice: false)
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(round.reload.state).to eq('open')
    expect(snapshot.canonical_data.fetch('contests').first)
      .to include('method' => 'absolute_majority', 'has_vice' => false, 'choices_per_person' => 1)
    expect(VotingStage.where(round: round).count).to eq(1)
    expect(snapshot.canonical_data.fetch('contests').first.fetch('candidacies'))
      .to all(satisfy { |candidate| !candidate.key?('vice_person') && !candidate.key?('vice_party_id') })
  end

  it 'keeps the implemented simple-majority profile available irrespective of the office name' do
    contest.update!(name: 'Custom School Office')
    preview = Configuration::PreviewElection.call(election: election, actor: creator)
    expect(preview.fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    expect(round.reload.state).to eq('open')
    expect(snapshot.canonical_data.fetch('contests').first.fetch('method')).to eq('simple_majority')
    expect(VotingStage.where(round: round).count).to eq(2)
  end

  it 'opens, confirms nominal and legend votes, and records a complete proportional result with remainder memory' do
    contest.update!(method: 'proportional', seats: 3, choices_per_person: 1,
                    rule_version: Voting::ProportionalCore::ALGORITHM_VERSION)
    [48, 49].each do |number|
      party = Party.create!(name: "Classroom Party #{number}", abbreviation: (number == 48 ? 'FPA' : 'FPB'), party_number: number)
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: number.to_s)
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Person #{number}"),
                        principal_party: party, ballot_number: "#{number}0")
    end
    expect(Configuration::PreviewElection.call(election: election, actor: creator).fetch(:valid)).to be(true)
    snapshot = Voting::OpenRound.call(round: round, actor: creator)
    device = VotingDevice.create!(school_installation: installation, public_label: 'Classroom',
                                  credential_digest: 'test-digest', state: 'locked')
    operator = User.create!(school_installation: installation, name: 'Operator', login: 'operator',
                           password: 'long-random-password')
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    stage = round.voting_stages.first
    candidates = contest.candidacies.order(:id).to_a
    commands = candidates.zip([4, 1, 3, 2]).flat_map do |candidate, count|
      Array.new(count) { { kind: 'nominal', candidacy_id: candidate.id } }
    end
    commands << { kind: 'legend', party_id: candidates.first.principal_party_id }
    commands.each_with_index do |command, index|
      session = Voting::Release.call(round: round, device: device, actor: operator)
      expect(Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "vote-#{index}", **command).status)
        .to eq(:confirmed)
    end
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    run = TallyRun.find_by!(round_contest: round.round_contests.first)
    expect(run.state).to eq('final')
    expect(run.totals).to include('qe' => 4, 'valid_votes' => 11,
                                'elected_ids' => candidates.first(3).map(&:id))
    expect(run.totals.fetch('allocation_steps').map { |step| step.fetch('phase') }).to eq(%w[restricted remaining])
    expect(run.totals.to_json).not_to match(/session_id|receipt_id|credential/)
    expect(snapshot.canonical_data.fetch('contests').first.fetch('rule_version')).to eq(run.algorithm_version)
    expect(Voting::RoundResult.call(round: round).fetch(:contests).first.fetch(:result)).to eq(run.totals)
    before_counts = [TallyRun.count, CastVote.count, AuditEvent.count]
    Voting::RoundResult.call(round: round)
    expect([TallyRun.count, CastVote.count, AuditEvent.count]).to eq(before_counts)
    report = Voting::PublishReport.call(election: election, actor: creator, now: round.grace_until + 2.seconds)
    public_contest = report.content.fetch('rounds').first.fetch('contests').first
    expect(public_contest.fetch('result')).to eq(run.totals)
    expect(public_contest.fetch('legends')).to include(
      a_hash_including('party_id' => candidates.first.principal_party_id, 'votes' => 1)
    )
  end
end
