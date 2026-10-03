# frozen_string_literal: true

require 'digest'

module Voting
  class PublishReport
    class NotAllowed < StandardError; end
    NotReady = FinalReport::NotReady

    def self.call(election:, actor:, now: Time.current)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      report, changed = ReportVersion.transaction do
        # Lifecycle commands lock rounds before changing the election status.
        Round.where(election_id: election.id).order(:number).lock.to_a
        election.lock!
        content = FinalReport.call(election: election)
        digest = Digest::SHA256.hexdigest(JSON.generate(content))
        previous = ReportVersion.where(election: election).order(:version).last
        next [previous, false] if previous&.input_digest == digest

        version = ReportVersion.create!(election: election, previous_version: previous,
                                         version: previous ? previous.version + 1 : 1,
                                         input_digest: digest, content: content, published_at: now)
        AuditEvent.create!(election: election, user: actor, action: 'report_publish',
                           result: 'success', occurred_at: now)
        [version, true]
      end
      NotifyPublicResults.call(election_id: election.id) if changed
      report
    rescue NotReady => error
      if error.round
        Incident.create!(round: error.round, user: actor, kind: 'publication_mismatch',
                         reason: error.message, occurred_at: now)
      end
      AuditEvent.create!(election: election, user: actor, action: 'report_publish',
                         result: 'denied', reason: error.message, occurred_at: now)
      raise
    end
  end
end
