# frozen_string_literal: true

RSpec.shared_context 'an opened school voting round' do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.current.change(usec: 0) }
  let(:school) { SchoolInstallation.create!(identifier: 'pause-school', name: 'Pause School') }
  let(:creator) { user('creator') }
  let(:pollworker) { user('pollworker') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'School Election',
                     description: 'A school election for lifecycle tests', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft', opens_at: now - 1.minute,
                  closes_at: now + 1.hour, grace_until: now + 70.minutes)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Computer',
                         credential_digest: 'test-digest', state: 'locked')
  end
  let(:voting_session) { Voting::Release.call(round: round, device: device, actor: pollworker, now: now) }
  let(:first_stage) { round.voting_stages.order(:global_position).first }
  let(:second_stage) { round.voting_stages.order(:global_position).second }
  let(:first_candidate) { contest.candidacies.order(:id).first }

  def user(login, installation = school)
    User.create!(school_installation: installation, name: 'Teacher', login: login,
                 password: 'long-random-password')
  end

  # Draft/scheduled fixtures must be new rounds, never reset an opened ballot.
  def round_with_state(state)
    if %w[draft scheduled].include?(state)
      Round.create!(election: election, number: 2, state: state, opens_at: round.opens_at,
                    closes_at: round.closes_at, grace_until: round.grace_until)
    else
      round.update!(state: state)
      round
    end
  end

  def confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: first_stage.id,
                         command_key: 'first-confirmation', kind: 'nominal',
                         candidacy_id: first_candidate.id, now: now)
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionRole.create!(election: election, user: pollworker, role: 'pollworker')
    party = Party.create!(name: 'Lifecycle Test Party', abbreviation: 'LTP', party_number: 47)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '47')
    2.times do |index|
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Person #{index}"),
                        principal_party: party, ballot_number: "47#{index}")
    end
    Voting::OpenRound.call(round: round, actor: creator, now: now)
  end
end
