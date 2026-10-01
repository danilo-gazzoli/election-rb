# frozen_string_literal: true

class AddElectionCreationPermission < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :can_create_elections, :boolean, null: false, default: false
  end
end
