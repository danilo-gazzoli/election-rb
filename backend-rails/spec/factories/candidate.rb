# frozen_string_literal: true

FactoryBot.define do
  factory :candidate do
    name { 'John Wiliam' }
    candidate_num { rand(1..99).to_s }

    election { build(:election) }
    office { build(:office) }
    party { build(:party) }
  end
end
