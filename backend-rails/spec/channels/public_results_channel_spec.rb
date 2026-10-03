# frozen_string_literal: true

require 'rails_helper'

# ERS RF-36/RF-38: refresh notifications contain no individual vote or operational identity.
RSpec.describe PublicResultsChannel, type: :channel do
  include_context 'an opened school voting round'

  before { stub_connection current_user: nil, current_voting_device: nil }

  it 'allows anonymous access only to the requested election public stream' do
    subscribe election_id: election.id
    expect(subscription).to be_confirmed
    expect(subscription.streams).to eq(["public_results:election:#{election.id}"])
  end

  it 'allows partial result updates while the round is suspended' do
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    subscribe election_id: election.id
    expect(subscription).to be_confirmed
  end

  it 'rejects an unknown election without creating any stream' do
    subscribe election_id: 0
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'rejects a draft election without an opened public ballot' do
    draft = Election.create!(school_installation: school, creator: creator, title: 'Draft Election',
                             description: 'Not available publicly', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    subscribe election_id: draft.id
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'rejects a new subscription after the round is annulled' do
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid process', confirmed: true, now: now)
    subscribe election_id: election.id
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'transmits only the aggregate resource identity and opaque revision' do
    subscribe election_id: election.id
    revision = 'a' * 64
    subscription.send(:transmit, { event: 'results_changed', election_id: election.id, revision: revision,
                                  session_id: 'private-session', candidacy_id: 7, votes: 1,
                                  voting_device_id: device.id, confirmed_at: now.iso8601 })
    expect(transmissions).to eq([
      { 'event' => 'results_changed', 'election_id' => election.id, 'revision' => revision }
    ])
  end

  it 'ignores another election, other events and malformed revisions' do
    subscribe election_id: election.id
    [
      { event: 'results_changed', election_id: election.id + 1, revision: 'a' * 64 },
      { event: 'state_changed', election_id: election.id, revision: 'a' * 64 },
      { event: 'results_changed', election_id: election.id, revision: 'private-session' },
      { event: 'results_changed', election_id: election.id }
    ].each { |payload| subscription.send(:transmit, payload) }
    expect(transmissions).to be_empty
  end
end
