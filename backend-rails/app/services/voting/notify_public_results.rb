# frozen_string_literal: true

require 'digest'

module Voting
  class NotifyPublicResults
    # Rails 7.1 forwards this record through savepoints to the outer commit.
    class AfterCommit
      def initialize(election_id)
        @election_id = election_id
        @finished = false
      end

      def trigger_transactional_callbacks?
        false
      end

      def before_committed!; end

      def committed!(**)
        return if @finished

        @finished = true
        NotifyPublicResults.call(election_id: @election_id)
      end

      def rolledback!(**)
        @finished = true
      end
    end
    private_constant :AfterCommit

    def self.call(election_id:)
      connection = ActiveRecord::Base.connection
      if connection.transaction_open?
        connection.add_transaction_record(AfterCommit.new(election_id))
        return true
      end

      ActionCable.server.broadcast("public_results:election:#{election_id}",
                                   { event: 'results_changed', election_id: election_id,
                                     revision: revision(election_id) })
      true
    rescue StandardError => error
      # HTTP refetch remains available; a transport failure cannot undo a durable command.
      Rails.logger.warn("Public result notification failed: #{error.class.name}")
      false
    end

    def self.revision(election_id)
      election = Election.find(election_id)
      unless election.canceled?
        round = election.rounds.where(state: %w[open suspended]).order(number: :desc).first
        return PublicPartialResult.call(round: round).fetch(:revision) if round
      end
      unavailable_revision(election_id)
    rescue PublicPartialResult::NotAvailable
      unavailable_revision(election_id)
    end

    def self.unavailable_revision(election_id)
      Digest::SHA256.hexdigest(JSON.generate({ election_id: election_id, status: 'not_available' }))
    end
    private_class_method :revision, :unavailable_revision
  end
end
