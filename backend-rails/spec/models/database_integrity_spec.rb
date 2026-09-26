# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Database integrity' do
  it 'keeps the vote and ballot references protected by foreign keys' do
    connection = ActiveRecord::Base.connection

    expect(connection.foreign_keys(:votes).map(&:column)).to include('candidate_id', 'ballot_id', 'election_id')
    expect(connection.foreign_keys(:ballots).map(&:column)).to include('pollworker_id', 'election_id')
  end
end
