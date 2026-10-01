# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VotingStagePlan do
  it 'puts two simple-majority choices consecutively in configured office order' do
    contests = [
      { id: 10, position: 2, choices_per_person: 2 },
      { id: 9, position: 1, choices_per_person: 1 }
    ]

    expect(described_class.call(contests)).to eq([
      { contest_id: 9, global_position: 1, choice_index: 1 },
      { contest_id: 10, global_position: 2, choice_index: 1 },
      { contest_id: 10, global_position: 3, choice_index: 2 }
    ])
  end

  it 'rejects repeated contest positions' do
    contests = [{ id: 1, position: 1, choices_per_person: 1 },
                { id: 2, position: 1, choices_per_person: 1 }]
    expect { described_class.call(contests) }.to raise_error(ArgumentError)
  end
end
