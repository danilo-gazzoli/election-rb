# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CandidaciesController < BaseController
        before_action :require_user!

        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Election or contest not found', status: :not_found)
        end

        def create
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          attributes = params.require(:candidacy).permit(
            :principal_name, :principal_party_id, :ballot_number, :vice_name, :vice_party_id
          ).to_h.symbolize_keys
          candidacy = ::Configuration::CreateCandidacy.call(
            election: election, contest_id: params[:contest_id], actor: current_user, attributes: attributes
          )
          render json: { candidacy: candidacy.attributes.slice(
            'id', 'ballot_number', 'state', 'principal_person_id', 'principal_party_id',
            'vice_person_id', 'vice_party_id'
          ) }, status: :created
        rescue ::Configuration::CreateCandidacy::Locked => error
          render_configuration_locked(message: error.message)
        rescue ::Configuration::CreateCandidacy::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render_api_error(code: 'invalid_configuration', message: 'Invalid candidacy configuration',
                           status: :unprocessable_entity)
        end

        def update
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          attributes = params.require(:candidacy).permit(
            :principal_name, :principal_party_id, :ballot_number, :vice_name, :vice_party_id
          ).to_h.symbolize_keys
          candidacy = ::Configuration::UpdateCandidacy.call(
            election: election, contest_id: params[:contest_id], candidacy_id: params[:id],
            actor: current_user, attributes: attributes
          )
          render json: { candidacy: candidacy.attributes.slice(
            'id', 'ballot_number', 'state', 'principal_person_id', 'principal_party_id',
            'vice_person_id', 'vice_party_id'
          ) }
        rescue ::Configuration::UpdateCandidacy::PersonInUse => error
          render_api_error(code: 'candidate_person_in_use', message: error.message, status: :conflict)
        rescue ::Configuration::UpdateCandidacy::Locked => error
          render_configuration_locked(message: error.message)
        rescue ::Configuration::UpdateCandidacy::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render_api_error(code: 'invalid_configuration', message: 'Invalid candidacy configuration',
                           status: :unprocessable_entity)
        end

        def destroy
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          ::Configuration::DeleteCandidacy.call(
            election: election, contest_id: params[:contest_id], candidacy_id: params[:id], actor: current_user
          )
          head :no_content
        rescue ::Configuration::DeleteCandidacy::Locked => error
          render_configuration_locked(message: error.message)
        rescue ::Configuration::DeleteCandidacy::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ActiveRecord::InvalidForeignKey
          render_api_error(code: 'candidacy_in_use', message: 'Candidacy is referenced by election data',
                           status: :conflict)
        end
      end
    end
  end
end
