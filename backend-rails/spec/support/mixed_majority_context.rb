# frozen_string_literal: true

RSpec.shared_context 'a mixed majority election' do
  let(:now) { Time.current.change(usec: 0) }
  let(:school) { SchoolInstallation.create!(identifier: 'mixed-majority-school', name: 'Mixed School') }
  let(:creator) do
    User.create!(school_installation: school, name: 'Creator', login: 'mixed-creator',
                 password: 'long-random-password')
  end
  let(:operator) do
    User.create!(school_installation: school, name: 'Pollworker', login: 'mixed-worker',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Mixed Election',
                     description: 'A mixed election for the real majority journey', timezone: school.timezone,
                     start_time: now + 1.day, end_time: now + 25.hours,
                     election_day: (now + 1.day).in_time_zone(school.timezone).to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'scheduled', opens_at: now + 1.day,
                  closes_at: now + 25.hours, grace_until: now + 25.hours + 10.minutes)
  end
  let(:decided) do
    Contest.create!(election: election, name: 'President', position: 1, method: 'absolute_majority',
                    seats: 1, choices_per_person: 1, has_vice: true)
  end
  let(:simple) do
    Contest.create!(election: election, name: 'Representative', position: 2, method: 'simple_majority',
                    seats: 1, choices_per_person: 1, has_vice: false)
  end
  let(:contested) do
    Contest.create!(election: election, name: 'Governor', position: 3, method: 'absolute_majority',
                    seats: 1, choices_per_person: 1, has_vice: true)
  end
  let(:principal_party) { Party.create!(name: 'Mixed Principal Party', abbreviation: 'MPP', party_number: 71) }
  let(:vice_party) { Party.create!(name: 'Mixed Vice Party', abbreviation: 'MVP', party_number: 72) }
  let(:slates) do
    [decided, simple, contested].to_h do |contest|
      candidates = (contest.has_vice? ? 3 : 2).times.map do |index|
        attributes = { contest: contest, ballot_number: "71#{index}", principal_party: principal_party,
                       principal_person: CandidatePerson.create!(name: "#{contest.name} Principal #{index}") }
        if contest.has_vice?
          attributes.merge!(vice_party: vice_party,
                            vice_person: CandidatePerson.create!(name: "#{contest.name} Vice #{index}"))
        end
        Candidacy.create!(**attributes)
      end
      [contest.id, candidates]
    end
  end
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Mixed Device',
                         credential_digest: 'test-digest', state: 'locked')
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    [principal_party, vice_party].each do |party|
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: party.party_number.to_s)
    end
    slates
    round
  end

  def open_first
    Voting::OpenRound.call(round: round, actor: creator, now: round.opens_at)
  end

  def mixed_vote(target_round, choices)
    session = Voting::Release.call(round: target_round, device: device, actor: operator, now: target_round.opens_at)
    target_round.voting_stages.order(:global_position).each do |stage|
      candidate = choices.fetch(stage.round_contest.contest_id)
      Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "mixed-vote-#{stage.id}",
                           kind: 'nominal', candidacy_id: candidate.id, now: target_round.opens_at)
    end
    session
  end

  def finish_mixed_first(all_decided: false)
    open_first
    [0, 0, 0, 1, 1, 2].each do |index|
      mixed_vote(round, decided.id => slates.fetch(decided.id).first,
                        simple.id => slates.fetch(simple.id).first,
                        contested.id => slates.fetch(contested.id).fetch(all_decided ? 0 : index))
    end
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  def prepare_mixed_second
    Voting::PrepareRunoff.call(first_round: round, actor: creator, opens_at: round.opens_at + 2.days,
                               closes_at: round.closes_at + 2.days, now: round.grace_until + 1.second)
  end
end
