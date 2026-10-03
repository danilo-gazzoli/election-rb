# frozen_string_literal: true

RSpec.shared_context 'an absolute majority tally round' do
  let(:now) { Time.current.change(usec: 0) }
  let(:round_number) { 1 }
  let(:candidate_count) { 3 }
  let(:school) { SchoolInstallation.create!(identifier: 'absolute-tally-school', name: 'Absolute School') }
  let(:creator) do
    User.create!(school_installation: school, name: 'Teacher', login: 'absolute-teacher',
                 password: 'long-random-password')
  end
  let(:operator) do
    User.create!(school_installation: school, name: 'Pollworker', login: 'absolute-pollworker',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Absolute Election',
                     description: 'Absolute majority tally tests', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: round_number, state: 'draft', opens_at: now - 1.minute,
                  closes_at: now + 1.hour, grace_until: now + 70.minutes)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'President', position: 1, method: 'absolute_majority',
                    seats: 1, choices_per_person: 1, has_vice: true)
  end
  let(:principal_party) { Party.create!(name: 'Principal Party', abbreviation: 'APP', party_number: 61) }
  let(:vice_party) { Party.create!(name: 'Vice Party', abbreviation: 'AVP', party_number: 62) }
  let(:candidates) do
    candidate_count.times.map do |index|
      Candidacy.create!(contest: contest, ballot_number: "61#{index}", principal_party: principal_party,
                        principal_person: CandidatePerson.create!(name: "Principal #{index}"),
                        vice_party: vice_party, vice_person: CandidatePerson.create!(name: "Vice #{index}"))
    end
  end
  let(:round_contest) { RoundContest.create!(round: round, contest: contest) }
  let(:stage) { VotingStage.create!(round: round, round_contest: round_contest, global_position: 1, choice_index: 1) }
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Absolute Device',
                         credential_digest: 'test-digest', state: 'locked')
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    [principal_party, vice_party].each do |party|
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: party.party_number.to_s)
    end
    stage
    candidates.each { |candidate| RoundCandidacy.create!(round: round, candidacy: candidate) }
    round.update!(state: 'open')
  end

  def cast(choice)
    session = Voting::Release.call(round: round, device: device, actor: operator, now: now)
    attributes = choice.is_a?(Candidacy) ? { kind: 'nominal', candidacy_id: choice.id } : { kind: choice }
    Voting::Confirm.call(session: session, stage_id: stage.id, command_key: 'absolute-vote', now: now, **attributes)
  end

  def close_and_tally
    round.update!(state: 'closed')
    described_class.call(round_contest: round_contest)
  end

  def counts_for(*numbers)
    numbers.each_with_index { |count, index| count.times { cast(candidates.fetch(index)) } }
  end

end
