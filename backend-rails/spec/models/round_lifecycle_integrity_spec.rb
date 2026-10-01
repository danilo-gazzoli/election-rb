# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Irreversible voting round states', type: :model do
  include_context 'an opened school voting round'

  def change_state_directly(state)
    Round.where(id: round.id).update_all(state: state)
  end

  {
    'open' => %w[draft scheduled],
    'suspended' => %w[draft scheduled],
    'closed' => %w[draft scheduled open suspended],
    'annulled' => %w[draft scheduled open suspended closed]
  }.each do |original_state, forbidden_states|
    forbidden_states.each do |target_state|
      it "rejects direct #{original_state} to #{target_state} even without model validation" do
        change_state_directly(original_state)

        expect do
          Round.transaction(requires_new: true) { change_state_directly(target_state) }
        end.to raise_error(ActiveRecord::StatementInvalid)
        expect(round.reload.state).to eq(original_state)
        expect(round.voting_stages.count).to eq(2)
      end
    end
  end

  it 'rejects an unknown state at the database boundary' do
    expect do
      Round.transaction(requires_new: true) { change_state_directly('unknown') }
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect(round.reload.state).to eq('open')
  end

  it 'allows suspension and resumption while retaining the frozen configuration' do
    stage_ids = round.voting_stages.order(:global_position).pluck(:id)
    change_state_directly('suspended')
    change_state_directly('open')
    expect(round.reload.state).to eq('open')
    expect(round.voting_stages.order(:global_position).pluck(:id)).to eq(stage_ids)
  end

  it 'allows closure after suspension' do
    change_state_directly('suspended')
    change_state_directly('closed')
    expect(round.reload.state).to eq('closed')
  end

  it 'allows annulling a closed round while retaining its stages' do
    change_state_directly('closed')
    change_state_directly('annulled')
    expect(round.reload.state).to eq('annulled')
    expect(round.voting_stages.count).to eq(2)
  end
end
