# frozen_string_literal: true

class CreateAuthenticationAttemptWindows < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_attempt_windows, id: false do |t|
      t.string :key_digest, null: false, limit: 64
      t.bigint :window_started_at, null: false
      t.datetime :expires_at, null: false
      t.bigint :attempts, null: false, default: 1
    end
    add_index :authentication_attempt_windows, [:key_digest, :window_started_at], unique: true,
              name: 'idx_authentication_attempt_window'
    add_index :authentication_attempt_windows, :expires_at
    add_check_constraint :authentication_attempt_windows, 'attempts > 0', name: 'positive_authentication_attempts'
  end
end
