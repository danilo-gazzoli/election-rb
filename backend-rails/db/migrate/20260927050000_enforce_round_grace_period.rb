# frozen_string_literal: true

class EnforceRoundGracePeriod < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :rounds,
                         'EXTRACT(EPOCH FROM (grace_until - closes_at)) BETWEEN 599 AND 601',
                         name: 'round_grace_period_ten_minutes'
  end
end
