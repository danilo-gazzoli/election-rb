# frozen_string_literal: true

require 'time'

module Api
  module V1
    module Admin
      class RoundsController < BaseController
        class InvalidRunoffCalendar < StandardError; end
        before_action :require_user!

        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Round not found', status: :not_found)
        end

        def runoff
          first = Round.find(params[:id])
          return unless require_role!(first.election, 'creator')

          second = ::Voting::PrepareRunoff.call(first_round: first, actor: current_user,
                                                opens_at: runoff_timestamp(params[:opens_at]),
                                                closes_at: runoff_timestamp(params[:closes_at]))
          render json: runoff_response(second, first.id), status: second.previously_new_record? ? :created : :ok
        rescue InvalidRunoffCalendar => e
          render_api_error(code: 'invalid_runoff_calendar', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::PrepareRunoff::Conflict => e
          render_api_error(code: 'runoff_conflict', message: e.message, status: :conflict)
        rescue ::Voting::PrepareRunoff::InvalidConfiguration => e
          render_api_error(code: 'invalid_runoff_configuration', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::PrepareRunoff::NotAllowed => e
          render_api_error(code: 'runoff_prepare_denied', message: e.message, status: :conflict)
        end

        def results
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          render json: ::Voting::RoundResult.call(round: round)
        rescue ::Voting::RoundResult::NotAvailable => e
          render_api_error(code: 'result_not_available', message: e.message, status: :conflict)
        end

        def suspend
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          ::Voting::SuspendRound.call(round: round, actor: current_user, reason: params[:reason])
          render json: { state: round.state }
        rescue ::Voting::SuspendRound::InvalidReason => e
          render_api_error(code: 'invalid_reason', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::SuspendRound::NotAllowed => e
          render_api_error(code: 'round_suspend_denied', message: e.message, status: :conflict)
        end

        def resume
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          ::Voting::ResumeRound.call(round: round, actor: current_user, reason: params[:reason])
          render json: { state: round.state }
        rescue ::Voting::ResumeRound::InvalidReason => e
          render_api_error(code: 'invalid_reason', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::ResumeRound::NotAllowed => e
          render_api_error(code: 'round_resume_denied', message: e.message, status: :conflict)
        end

        def annul
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          ::Voting::AnnulRound.call(round: round, actor: current_user, reason: params[:reason],
                                   confirmed: params[:confirmed])
          render json: { state: round.state }
        rescue ::Voting::AnnulRound::InvalidReason => e
          render_api_error(code: 'invalid_reason', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::AnnulRound::InvalidConfirmation => e
          render_api_error(code: 'confirmation_required', message: e.message, status: :unprocessable_entity)
        rescue ::Voting::AnnulRound::NotAllowed => e
          render_api_error(code: 'round_annul_denied', message: e.message, status: :conflict)
        end

        def open
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          snapshot = Voting::OpenRound.call(round: round, actor: current_user)
          stages = round.voting_stages.order(:global_position).map do |stage|
            { id: stage.id, global_position: stage.global_position,
              choice_index: stage.choice_index, contest_id: stage.round_contest.contest_id }
          end
          render json: { state: round.reload.state, snapshot_digest: snapshot.digest, stages: stages }
        rescue Voting::OpenRound::InvalidConfiguration => e
          render_api_error(code: 'invalid_configuration', message: e.message, status: :unprocessable_entity)
        rescue Voting::OpenRound::NotAllowed => e
          render_api_error(code: 'round_open_denied', message: e.message, status: :conflict)
        end

        def close
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          Voting::CloseRound.call(round: round, actor: current_user)
          tallies = TallyRun.joins(:round_contest).where(round_contests: { round_id: round.id })
                            .order(:round_contest_id).map do |tally|
            { contest_id: tally.round_contest.contest_id, state: tally.state }
          end
          render json: { state: round.reload.state, tallies: tallies }
        rescue Voting::CloseRound::NotAllowed => e
          render_api_error(code: 'round_close_denied', message: e.message, status: :conflict)
        end

        private

        def runoff_timestamp(value)
          unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/)
            raise InvalidRunoffCalendar, 'Calendar timestamps must be ISO8601 with an explicit offset'
          end

          parsed = Time.iso8601(value)
          raise InvalidRunoffCalendar, 'Invalid calendar timestamp' unless parsed.strftime('%Y-%m-%dT%H:%M:%S') == value[0, 19]

          parsed
        rescue ArgumentError, RangeError
          raise InvalidRunoffCalendar, 'Invalid calendar timestamp'
        end

        def runoff_response(second, first_id)
          {
            source_round_id: first_id,
            round: { id: second.id, number: second.number, state: second.state,
                     opens_at: second.opens_at.utc.iso8601(6), closes_at: second.closes_at.utc.iso8601(6),
                     grace_until: second.grace_until.utc.iso8601(6) },
            contests: second.round_contests.includes(:contest).sort_by { |item| item.contest.position }.map do |item|
              ids = RoundCandidacy.joins(:candidacy)
                                  .where(round_id: second.id, eligible: true, candidacies: { contest_id: item.contest_id })
                                  .order(:candidacy_id).pluck(:candidacy_id)
              { contest_id: item.contest_id, candidacy_ids: ids }
            end
          }
        end
      end
    end
  end
end
