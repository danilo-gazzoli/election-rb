# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Election configuration database integrity' do
  let(:installation) { SchoolInstallation.create!(identifier: 'election-integrity', name: 'Election Integrity School') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'Election configuration integrity tests', timezone: 'America/Sao_Paulo',
                     start_time: 1.day.from_now, end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let!(:round) do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end

  it 'prevents direct changes to election configuration after a round opens' do
    expect do
      Election.transaction(requires_new: true) { election.update_columns(title: 'Unsafe School Election') }
    end.to raise_error(ActiveRecord::StatementInvalid, /immutable/)
    expect(election.reload.title).to eq('School Election')
  end

  it 'prevents direct calendar changes after a round opens' do
    closes_at = round.closes_at
    expect do
      Round.transaction(requires_new: true) do
        round.update_columns(closes_at: closes_at + 1.hour, grace_until: closes_at + 70.minutes)
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /immutable/)
    expect(round.reload.closes_at).to eq(closes_at)
  end
end
