# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PartiesController < BaseController
        before_action :require_user!
        before_action :authorize_election!

        rescue_from ::Configuration::ManageParty::Locked do |error|
          render_api_error(code: 'configuration_locked', message: error.message, status: :conflict)
        end
        rescue_from ::Configuration::ManageParty::NotAllowed do |error|
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        end
        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Resource not found', status: :not_found)
        end
        rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique do
          render_api_error(code: 'invalid_configuration', message: 'Invalid party configuration',
                           status: :unprocessable_entity)
        end
        rescue_from ActiveRecord::InvalidForeignKey, 'ActiveRecord::DeleteRestrictionError' do
          render_api_error(code: 'party_in_use', message: 'Party is referenced by election data', status: :conflict)
        end
        rescue_from ActionController::ParameterMissing do
          render_api_error(code: 'invalid_request', message: 'Party attributes are required', status: :bad_request)
        end

        def index
          registrations = ElectionPartyRegistration.includes(:party).where(election: @election).order(:ballot_number)
          render json: { parties: registrations.map do |registration|
            registration.party.as_json(only: %i[id name abbreviation description]).merge(
              'ballot_number' => registration.ballot_number
            )
          end }
        end

        def create
          party = manage(:create, attributes: party_attributes)
          render json: { id: party.id }, status: :created
        end

        def update
          party = manage(:update, attributes: party_attributes, party_id: params[:id])
          render json: party.as_json(only: %i[id name abbreviation ballot_number description])
        end

        def destroy
          manage(:delete, party_id: params[:id])
          head :no_content
        end

        private

        def authorize_election!
          @election = Election.find(params[:election_id])
          if current_user.school_installation_id != @election.school_installation_id
            render_api_error(code: 'forbidden', message: 'Role is required', status: :forbidden)
            return
          end
          require_role!(@election, 'creator')
        end

        def party_attributes
          params.require(:party).permit(:name, :abbreviation, :ballot_number, :description).to_h
        end

        def manage(operation, **arguments)
          ::Configuration::ManageParty.call(election: @election, actor: current_user,
                                            operation: operation, **arguments)
        end
      end
    end
  end
end
