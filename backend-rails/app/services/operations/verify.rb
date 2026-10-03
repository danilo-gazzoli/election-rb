# frozen_string_literal: true

module Operations
  # Read-only recovery check; pending electoral outcomes are not invented or repaired.
  class Verify
    def self.call
      rounds = Round.where(state: %w[closed annulled]).order(:election_id, :number).map do |round|
        result = Voting::ReconcileRound.call(round: round)
        { round_id: round.id, status: result.fetch(:status), issues: result.fetch(:issues) }
      end
      issues = rounds.select { |round| round.fetch(:status) != 'reconciled' }
      Election.where(id: ReportVersion.select(:election_id)).find_each do |election|
        next if election.canceled? || election.rounds.where.not(state: 'closed').exists?
        begin
          Voting::FinalReport.call(election: election)
        rescue Voting::FinalReport::NotReady => error
          issues << { election_id: election.id, reason: error.message }
        end
      end
      { status: issues.empty? ? 'ok' : 'failed', rounds: rounds, issues: issues,
        votes: CastVote.count, receipts: ConfirmationReceipt.count, reports: ReportVersion.count }
    end
  end
end
