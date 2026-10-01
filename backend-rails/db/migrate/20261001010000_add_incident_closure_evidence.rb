# frozen_string_literal: true

class AddIncidentClosureEvidence < ActiveRecord::Migration[7.1]
  def change
    add_reference :incidents, :user, foreign_key: true
    # NULL means legacy evidence is unknown; a known cancellation stores [].
    add_column :incidents, :remaining_stage_ids, :jsonb
  end
end
