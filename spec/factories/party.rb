FactoryBot.define do
  factory :party do
    sequence(:name) { |n| "Valid Party Name #{n}" } 
    sequence(:abbreviation) do |n| 
      letters = ('A'..'Z').to_a
      first = letters[n % 26]
      second = letters[(n / 26) % 26]
      third = letters[(n / (26 * 26)) % 26]
      "#{first}#{second}#{third}"
    end
    sequence(:party_number) { |n| (n % 99) + 1 }
    description { "This is a valid description for the party model. It provides sufficient detail." }

    after(:build) do |party|
      party.elections << build(:election)
    end
  end
end
