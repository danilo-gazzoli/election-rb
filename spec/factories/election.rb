# frozen_string_literal: true

FactoryBot.define do
  factory :election do
    title { 'Election 2025' }
    description { 'This is the description for Election 2025' }
    status { :draft }
    start_time { 1.day.from_now }
    end_time { 2.days.from_now }
    election_day { Time.zone.today + 1.week }
  end
end
