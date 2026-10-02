# frozen_string_literal: true

module Configuration
  class RecordRejectedChange
    def self.call(election:, actor:, resource:, operation:)
      AuditEvent.create!(election: election, user: actor, action: 'configuration_change_rejected',
                         result: 'rejected', reason: "#{resource}.#{operation}: configuration_locked",
                         occurred_at: Time.current)
    end
  end
end
