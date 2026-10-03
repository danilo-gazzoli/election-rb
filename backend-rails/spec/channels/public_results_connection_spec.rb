# frozen_string_literal: true

require 'rails_helper'

# SDD: anonymous result updates must never grant access to private operational streams.
RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:school) { SchoolInstallation.create!(identifier: 'public-cable-school', name: 'Public School') }
  let(:operator) do
    User.create!(school_installation: school, name: 'Teacher', login: 'public-test-teacher',
                 password: 'long-random-password')
  end
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Private Device',
                         credential_digest: VotingDevice.digest_credential('paired-device-secret'))
  end

  it 'accepts an explicitly public connection without a user session or device credential' do
    connect params: { audience: 'public' }
    expect(connection.current_user).to be_nil
    expect(connection.current_voting_device).to be_nil
    expect(connection.operator_session_current?).to be(false)
    expect(connection.device_credential_current?).to be(false)
  end

  it 'does not promote a public connection to an operator even when an active user session exists' do
    connect params: { audience: 'public' },
            session: { user_id: operator.id, user_expires_at: 8.hours.from_now.to_i }
    expect(connection.current_user).to be_nil
    expect(connection.operator_session_current?).to be(false)
  end

  it 'does not promote a public connection to a voting device even when a paired cookie exists' do
    cookies.encrypted[:voting_device] = "#{device.id}:paired-device-secret"
    connect params: { audience: 'public' }
    expect(connection.current_voting_device).to be_nil
    expect(connection.device_credential_current?).to be(false)
  end

  it 'continues to reject anonymous connections without the explicit public audience' do
    expect { connect }.to have_rejected_connection
    expect { connect params: { audience: 'pollworker' } }.to have_rejected_connection
  end
end
