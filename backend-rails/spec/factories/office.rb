# frozen_string_literal: true

FactoryBot.define do
  factory :office do
    name { 'President' }
    num_of_seats { 1 }
    needs_vice { false }
  end
end
