# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PollworkerChannel, type: :channel do
  let(:school) { SchoolInstallation.create!(identifier: 'worker-channel-school', name: 'Worker School') }
  let(:operator) { user('worker') }
  let(:creator) { user('creator') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'School Election',
                     description: 'Election for private operations', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end

  def user(login, installation = school)
    User.create!(school_installation: installation, name: 'Operator', login: login, password: 'long-random-password')
  end

  def connect_user(account, valid: true)
    stub_connection current_user: account, current_voting_device: nil
    connection.define_singleton_method(:operator_session_current?) { valid }
  end

  %w[pollworker creator].each do |role|
    it "allows the active #{role} only into the election operations stream" do
      ElectionRole.create!(election: election, user: operator, role: role)
      connect_user(operator)
      subscribe election_id: election.id
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("pollworker:election:#{election.id}")
      expect(subscription.streams).not_to include("voting_device:#{election.id}")
    end
  end

  it 'rejects a user without an active role in the election' do
    connect_user(operator)
    subscribe election_id: election.id
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'rejects an operator from another school even with a mismatched election role' do
    other_school = SchoolInstallation.create!(identifier: 'foreign-channel-school', name: 'Foreign School')
    outsider = user('outsider', other_school)
    connect_user(outsider)
    subscribe election_id: election.id
    expect(subscription).to be_rejected
  end

  it 'rejects an expired session' do
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    connect_user(operator, valid: false)
    subscribe election_id: election.id
    expect(subscription).to be_rejected
  end

  it 'stops transmitting when an election role is revoked after subscription' do
    role = ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    connect_user(operator)
    subscribe election_id: election.id
    subscription.send(:transmit, { event: 'state_changed' })
    expect(transmissions.last).to eq('event' => 'state_changed')
    role.update!(active: false)
    previous = transmissions.size
    subscription.send(:transmit, { event: 'state_changed' })
    expect(transmissions.size).to eq(previous)
    expect(subscription.streams).to be_empty
  end

  it 'stops transmitting when the operator session expires after subscription' do
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    connect_user(operator)
    subscribe election_id: election.id
    connection.define_singleton_method(:operator_session_current?) { false }
    subscription.send(:transmit, { event: 'state_changed' })
    expect(transmissions).to be_empty
    expect(subscription.streams).to be_empty
  end

  it 'rejects an anonymous connection' do
    connect_user(nil)
    subscribe election_id: election.id
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'transmits only a refresh event without leaking fields from the source payload' do
    ElectionRole.create!(election: election, user: operator, role: 'pollworker')
    connect_user(operator)
    subscribe election_id: election.id
    subscription.send(:transmit, { event: 'state_changed', candidacy_id: 123, session_id: 'private-session' })
    expect(transmissions.last).to eq('event' => 'state_changed')
  end
end
