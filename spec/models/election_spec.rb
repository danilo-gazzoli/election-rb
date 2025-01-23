require 'rails_helper'

describe Election do
  let(:election) { build(:election) }

  # title
  it "is valid when title is present" do
    election.title = "Election 2025"
    expect(election).to be_valid
  end

  it "is not valid when title is nil" do
    election.title = nil
    expect(election).to_not be_valid
  end

  it "is valid when title length is between 5 and 100 characters" do
    election.title = "Election 2025"
    expect(election).to be_valid
  end

  it "is not valid when title length is less than 5 characters" do
    election.title = "1234"
    expect(election).to_not be_valid
  end
  
  it "is not valid when title length is greater than 100 characters" do
    election.title = "a" * 101
    expect(election).to_not be_valid
  end

  # description
  it "is valid when description is present" do
    election.description = "This is a election 2025"
    expect(election).to be_valid
  end
  
  it "is not valid when description is nil" do
    election.description = nil
    expect(election).to_not be_valid
  end
  
  it "is not valid when description is empty" do
    election.description = ""
    expect(election).to_not be_valid
  end

  it "is valid when description length is between 10 and 200 characters" do
    election.description = "This is a election 2025"
    expect(election).to be_valid
  end

  it "is not valid when description length is less than 10 characters" do
    election.description = "123456789"
    expect(election).to_not be_valid
  end

  it "is not valid when description length is greater than 200 characters" do
    election.description = "a" * 201
    expect(election).to_not be_valid
  end

  # status
  it "is valid when status is present" do
    election.status = 1
    expect(election).to be_valid
  end
  
  it "is not valid when status is nil" do
    election.status = nil
    expect(election).to_not be_valid
  end
  
  it "is not valid when status is not one of 1, 2, 3, or 4" do
    election.status = 5
    expect(election).to_not be_valid
  end
  
  it "is valid when status value is 1 (scheduled), 2 (ongoing), 3 (completed), or 4 (canceled)" do
    election.status = 1
    expect(election).to be_valid
  end
  
  it "is not valid when status value is greater than 4" do
    election.status = 5
    expect(election).to_not be_valid
  end

  # start time
  it "is valid when start time is present" do
    election.start_time = Time.now
    expect(election).to be_valid
  end
  
  it "is not valid when start time is nil" do
    election.start_time = nil
    expect(election).to_not be_valid
  end
  
  it "is not valid when start time is in the past" do
    election.start_time = Time.now - 1.day
    expect(election).to_not be_valid
  end

  # end time
  it "is valid when end time is greater than start time" do
    election.start_time = Time.now
    election.end_time = Time.now + 2.hours
    expect(election).to be_valid
  end

  it "is not valid when end time is before start time" do
    election.start_time = Time.now
    election.end_time = Time.now - 5.hours
    expect(election).to_not be_valid
  end
  
  it "is valid when end time is in the future" do
    election.end_time = Time.now + 3.hours
    expect(election).to be_valid
  end

  # election day
  it "is valid when election day is present" do
    election.election_day = Time.zone.now
    expect(election).to be_valid
  end
  
  it "is not valid when election day is nil" do
    election.election_day = nil
    expect(election).to_not be_valid
  end
  
  it "is not valid when election day is a number" do
    election.election_day = 25
    expect(election).to_not be_valid
  end
  
  it "is valid when election day is today or in the future" do
    election.election_day = Time.zone.now + 7.day
    expect(election).to be_valid
  end
  
  it "is not valid when election day is in the past" do
    election.election_day = Time.zone.now - 1.day
    expect(election).to_not be_valid
  end
end
