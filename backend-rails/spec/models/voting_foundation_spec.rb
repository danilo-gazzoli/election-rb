# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting foundation' do
  it 'keeps an anonymous cast vote separate from the operational receipt' do
    vote_columns = ActiveRecord::Base.connection.columns(:cast_votes).map(&:name)
    receipt_columns = ActiveRecord::Base.connection.columns(:confirmation_receipts).map(&:name)

    expect(vote_columns).to include('round_id', 'contest_id', 'voting_stage_id', 'kind', 'origin')
    expect(vote_columns).not_to include('voting_session_id', 'voting_device_id', 'created_at', 'updated_at')
    expect(receipt_columns).not_to include('cast_vote_id', 'candidacy_id', 'party_id', 'kind')
  end

  it 'allows only one active session per voting device at the database level' do
    indexes = ActiveRecord::Base.connection.indexes(:voting_sessions)
    expect(indexes).to include(have_attributes(unique: true, where: /released|in_progress/))
  end
end
