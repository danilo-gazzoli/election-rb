# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  include ActiveSupport::Testing::TimeHelpers

  let(:school) { SchoolInstallation.create!(identifier: 'operator-cable-school', name: 'Operator School') }
  let(:operator) do
    User.create!(school_installation: school, name: 'Operator', login: 'operator', password: 'long-random-password')
  end

  def session_data
    { user_id: operator.id, user_expires_at: 8.hours.from_now.to_i }
  end

  it 'accepts an active user session independently of a voting device credential' do
    connect session: session_data
    expect(connection.current_user).to eq(operator)
    expect(connection.current_voting_device).to be_nil
    expect(connection.operator_session_current?).to be(true)
  end

  it 'rejects an expired user session at connection time' do
    expect { connect session: { user_id: operator.id, user_expires_at: Time.current.to_i } }
      .to have_rejected_connection
  end

  it 'recognizes expiration after the connection has already opened' do
    connect session: session_data
    travel 8.hours
    expect(connection.operator_session_current?).to be(false)
  end

  it 'recognizes an account deactivated after the connection has already opened' do
    connect session: session_data
    User.find(operator.id).update!(active: false)
    expect(connection.operator_session_current?).to be(false)
  end

  it 'rejects anonymous and deadline-less user connections' do
    expect { connect }.to have_rejected_connection
    expect { connect session: { user_id: operator.id } }.to have_rejected_connection
  end
end
