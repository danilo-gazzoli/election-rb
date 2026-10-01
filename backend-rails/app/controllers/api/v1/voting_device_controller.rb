# frozen_string_literal: true

module Api
  module V1
    class VotingDeviceController < BaseController
      def pair
        code = params[:pairing_code]
        return invalid_pairing unless code.is_a?(String) && code.present?

        device = VotingDevice.find_by(pairing_code_digest: VotingDevice.digest_credential(code))
        return invalid_pairing unless device

        credential = nil
        device.with_lock do
          return invalid_pairing unless device.pairing_code_digest && device.pairing_expires_at > Time.current

          credential = SecureRandom.hex(32)
          device.update!(credential_digest: VotingDevice.digest_credential(credential),
                         pairing_code_digest: nil, pairing_expires_at: nil,
                         credential_version: device.credential_version + 1)
        end
        cookies.encrypted[:voting_device] = {
          value: "#{device.id}:#{credential}", httponly: true, same_site: :lax,
          secure: Rails.env.production?
        }
        render json: { state: device.state }
      end

      def state
        device = authenticated_device
        return render_api_error(code: 'unauthorized', message: 'Device authentication required',
                                status: :unauthorized) unless device

        active = device.voting_sessions.find_by(state: %w[released in_progress])
        latest = active || device.voting_sessions.order(released_at: :desc).first
        round_state = latest&.round&.state
        stage = if active && round_state == 'open' && !active.round.election.canceled?
                  VotingStage.find_by(round_id: active.round_id, global_position: active.current_stage_position)
                end
        receipt_session = latest if latest && (
          %w[released in_progress completed].include?(latest.state) ||
          (latest.state == 'cancelled' && round_state == 'annulled')
        )
        last_receipt = receipt_session&.confirmation_receipts&.order(confirmed_at: :desc)&.first
        render json: { state: device.state, round_state: round_state, session_id: active&.id,
                       next_stage_position: active&.current_stage_position,
                       stage: stage && stage_catalog(stage), last_receipt_id: last_receipt&.id }
      end

      def confirm
        device = authenticated_device
        return render_api_error(code: 'unauthorized', message: 'Device authentication required',
                                status: :unauthorized) unless device

        active = device.voting_sessions.find_by(state: %w[released in_progress])
        if active.nil?
          latest = device.voting_sessions.order(released_at: :desc).first
          recoverable = latest && (latest.state == 'completed' ||
            (latest.state == 'cancelled' && latest.round.state == 'annulled'))
          active = latest if recoverable && latest.confirmation_receipts.exists?(
            voting_stage_id: params[:stage_id], command_key: params[:command_key]
          )
        end
        return render_api_error(code: 'locked', message: 'Device is locked',
                                status: :conflict) unless active

        result = Voting::Confirm.call(
          session: active, stage_id: params.require(:stage_id), command_key: params.require(:command_key),
          kind: params.require(:kind), candidacy_id: params[:candidacy_id], party_id: params[:party_id],
          warning_acknowledged: params[:warning_acknowledged] == true
        )
        return render_api_error(code: 'choice_warning', message: 'Second choice repeats the first',
                                status: :conflict) if result.status == :warning_required

        render json: { status: 'confirmed', receipt_id: result.receipt_id,
                       next_stage_position: result.next_stage_position }
      rescue Voting::Confirm::Conflict => e
        render_api_error(code: 'stage_conflict', message: e.message, status: :conflict)
      rescue Voting::Confirm::NotAllowed => e
        render_api_error(code: 'not_allowed', message: e.message, status: :forbidden)
      end

      private

      def invalid_pairing
        render_api_error(code: 'invalid_pairing_code', message: 'Invalid or expired pairing code',
                         status: :unauthorized)
      end

      def authenticated_device
        id, credential = cookies.encrypted[:voting_device].to_s.split(':', 2)
        return nil unless id&.match?(/\A\d+\z/) && credential

        device = VotingDevice.find_by(id: id)
        device if device&.authenticated_by?(credential)
      end

      def stage_catalog(stage)
        contest = stage.round_contest.contest
        candidates = RoundCandidacy.where(round_id: stage.round_id, eligible: true)
                                    .joins(:candidacy).where(candidacies: { contest_id: contest.id })
                                    .order(:candidacy_id).map do |entry|
          candidate = entry.candidacy
          { id: candidate.id, number: candidate.ballot_number, name: candidate.principal_person.name }
        end
        { id: stage.id, contest: contest.name, choice_index: stage.choice_index,
          method: contest.method, candidates: candidates }
      end
    end
  end
end
