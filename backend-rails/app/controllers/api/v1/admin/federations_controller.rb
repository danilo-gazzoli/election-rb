# frozen_string_literal: true

module Api
  module V1
    module Admin
      class FederationsController < BaseController
        before_action :require_user!
        before_action :authorize_election!

        rescue_from ::Configuration::ManageFederation::Locked do |error|
          render_configuration_locked(message: error.message)
        end
        rescue_from ::Configuration::ManageFederation::NotAllowed do |error|
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        end
        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Resource not found', status: :not_found)
        end
        rescue_from ::Configuration::ManageFederation::InvalidConfiguration,
                    ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique do
          render_api_error(code: 'invalid_configuration', message: 'Invalid federation configuration',
                           status: :unprocessable_entity)
        end
        rescue_from ActiveRecord::InvalidForeignKey do
          render_api_error(code: 'federation_in_use', message: 'Federation is referenced by election data',
                           status: :conflict)
        end
        rescue_from ActionController::ParameterMissing do
          render_api_error(code: 'invalid_request', message: 'Federation attributes are required', status: :bad_request)
        end

        def index
          federations = @election.federations.includes(:federation_memberships).order(:id)
          render json: { federations: federations.map { |federation| payload(federation) } }
        end

        def create
          federation = manage(:create, attributes: federation_attributes)
          render json: { federation: payload(federation) }, status: :created
        end

        def update
          federation = manage(:update, attributes: federation_attributes, federation_id: params[:id])
          render json: { federation: payload(federation) }
        end

        def destroy
          manage(:delete, federation_id: params[:id])
          head :no_content
        end

        private

        def authorize_election!
          @election = Election.find(params[:election_id])
          require_role!(@election, 'creator')
        end

        def federation_attributes
          params.require(:federation).permit(:name, :abbreviation, :state, party_ids: []).to_h
        end

        def manage(operation, **arguments)
          ::Configuration::ManageFederation.call(election: @election, actor: current_user,
                                                 operation: operation, **arguments)
        end

        def payload(federation)
          federation.attributes.slice('id', 'name', 'abbreviation', 'state').merge(
            'party_ids' => federation.federation_memberships.map(&:party_id).sort
          )
        end
      end
    end
  end
end
