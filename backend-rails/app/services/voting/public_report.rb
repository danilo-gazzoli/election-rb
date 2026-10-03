# frozen_string_literal: true

module Voting
  class PublicReport
    class NotAvailable < StandardError; end

    def self.call(election:, version: nil)
      if version && !version.to_s.match?(/\A[1-9]\d*\z/)
        raise NotAvailable, 'Report version not found'
      end
      scope = ReportVersion.where(election: election)
      report = version ? scope.find_by(version: version) : scope.order(:version).last
      raise NotAvailable, 'Report version not found' if version && !report
      if election.reload.canceled?
        return { status: 'annulled', election_id: election.id, reason: 'election is annulled' }
      end
      if election.rounds.empty? || election.rounds.where.not(state: 'closed').exists?
        return { status: 'pending', election_id: election.id, reason: 'all rounds must be closed' }
      end
      unless report
        latest = TallyRun.joins(round_contest: :round).where(rounds: { election_id: election.id })
                         .order('rounds.number', :created_at, :id).to_a
                         .index_by { |run| run.round_contest.contest_id }
        pending = latest.values.find { |run| run.state == 'pending' }
        return { status: 'pending', election_id: election.id,
                 reason: pending ? pending.totals.fetch('reason', 'tally is pending') : 'report is not published' }
      end
      report.content.merge('version' => report.version, 'previous_version' => report.previous_version&.version,
                           'published_at' => report.published_at.utc.iso8601(6), 'input_digest' => report.input_digest)
    end
  end
end
