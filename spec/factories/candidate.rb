FactoryBot.define do
  factory :candidate do
    name { 'John Wiliam' }
    candidate_num { rand(1..99).to_s } 

    after(:build) do |candidate|
      candidate.election << build(:election)
      candidate.office << build(:office)
      candidate.party << build(:party)
    end
  end
end
