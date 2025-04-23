# frozen_string_literal: true

class CreateElections < ActiveRecord::Migration[7.1]
  def change
    create_table :elections do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.datetime :start_time
      t.datetime :end_time
      t.date :election_day

      t.timestamps
    end
  end
end
