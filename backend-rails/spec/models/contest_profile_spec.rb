# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestProfile do
  it 'accepts the two-choice simple-majority profile' do
    profile = described_class.new(method: 'simple_majority', seats: 2, choices_per_person: 2, has_vice: false)
    expect(profile).to be_valid
  end

  it 'requires one choice for proportional contests' do
    profile = described_class.new(method: 'proportional', seats: 5, choices_per_person: 2, has_vice: false)
    expect(profile).not_to be_valid
  end

  it 'rejects two-seat absolute majority and vice in a proportional contest' do
    absolute = described_class.new(method: 'absolute_majority', seats: 2, choices_per_person: 2, has_vice: false)
    proportional = described_class.new(method: 'proportional', seats: 2, choices_per_person: 1, has_vice: true)
    expect(absolute).not_to be_valid
    expect(proportional).not_to be_valid
  end
end
