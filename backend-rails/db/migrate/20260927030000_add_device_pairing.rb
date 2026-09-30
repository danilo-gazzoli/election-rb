# frozen_string_literal: true

class AddDevicePairing < ActiveRecord::Migration[7.1]
  def change
    add_column :voting_devices, :pairing_code_digest, :string
    add_column :voting_devices, :pairing_expires_at, :datetime
    add_index :voting_devices, :pairing_code_digest, unique: true
  end
end
