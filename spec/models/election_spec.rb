# frozen_string_literal: true

require 'rails_helper'

describe Election do
  let(:election) { build(:election) }

  describe '#election_atributes' do
    context 'when atributes is present' do
      # title
      it 'is valid when title is present' do
        election.title = 'Election 2025'
        expect(election).to be_valid
      end

      # description
      it 'is valid when description is present' do
        election.description = 'This is a election 2025'
        expect(election).to be_valid
      end

      # status
      it 'is valid when status is present' do
        election.status = :draft
        expect(election).to be_valid
      end

      # start_time
      it 'is valid when start time is present' do
        election.start_time = 3.seconds.from_now
        expect(election).to be_valid
      end

      # end_time
      it 'is valid when end time is greater than start time' do
        election.start_time = 5.seconds.from_now
        election.end_time   = 2.hours.from_now
        expect(election).to be_valid
      end

      # election_day
      it 'is valid when election day is present' do
        election.election_day = Time.zone.now
        expect(election).to be_valid
      end
    end
    # title

    it 'is not valid when title is nil' do
      election.title = nil
      expect(election).to_not be_valid
    end

    it 'is valid when title length is between 5 and 100 characters' do
      election.title = 'Election 2025'
      expect(election).to be_valid
    end

    it 'is not valid when title length is less than 5 characters' do
      election.title = '1234'
      expect(election).to_not be_valid
    end

    it 'is not valid when title length is greater than 100 characters' do
      election.title = 'a' * 101
      expect(election).to_not be_valid
    end

    # description

    it 'is not valid when description is nil' do
      election.description = nil
      expect(election).to_not be_valid
    end

    it 'is not valid when description is empty' do
      election.description = ''
      expect(election).to_not be_valid
    end

    it 'is valid when description length is between 10 and 200 characters' do
      election.description = 'This is a election 2025'
      expect(election).to be_valid
    end

    it 'is not valid when description length is less than 10 characters' do
      election.description = '123456789'
      expect(election).to_not be_valid
    end

    it 'is not valid when description length is greater than 200 characters' do
      election.description = 'a' * 201
      expect(election).to_not be_valid
    end

    # status

    it 'is not valid when status is nil' do
      election.status = nil
      expect(election).to_not be_valid
    end

    it 'is valid when status is one of the valid enum values' do
      valid_statuses = %i[draft scheduled ongoing completed canceled]
      valid_statuses.each do |valid_status|
        election.status = valid_status
        expect(election).to be_valid
      end
    end

    it 'is valid when status is a string of valid values' do
      # Rails converte "scheduled" em :scheduled, que é um valor válido do enum
      election.status = 'scheduled'
      expect(election).to be_valid
    end

    # start time

    it 'is not valid when start time is nil' do
      election.start_time = nil
      expect(election).to_not be_valid
    end

    it 'is not valid when start time is in the past' do
      election.start_time = Time.current - 1.day
      expect(election).to_not be_valid
    end

    # end time

    it 'is not valid when end time is before start time' do
      election.start_time = Time.current
      election.end_time   = Time.current - 5.hours
      expect(election).to_not be_valid
    end

    it 'is valid when end time is in the future' do
      election.start_time = 2.seconds.from_now
      election.end_time   = 3.hours.from_now
      expect(election).to be_valid
    end

    # election day

    it 'is not valid when election day is nil' do
      election.election_day = nil
      expect(election).to_not be_valid
    end

    it 'is not valid when election day is a number' do
      election.election_day = 25
      expect(election).to_not be_valid
    end

    it 'is valid when election day is today or in the future' do
      election.election_day = Time.zone.now + 7.days
      expect(election).to be_valid
    end

    it 'is not valid when election day is in the past' do
      election.election_day = Date.yesterday
      expect(election).to_not be_valid
    end
  end
end
