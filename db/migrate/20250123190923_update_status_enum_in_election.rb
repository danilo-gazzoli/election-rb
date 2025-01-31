# frozen_string_literal: true

class UpdateStatusEnumInElection < ActiveRecord::Migration[7.1]
  def change
    change_column :elections, :status, :integer, default: 0, null: false
  end
end
