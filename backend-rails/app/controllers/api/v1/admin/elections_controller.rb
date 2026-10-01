# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ElectionsController < BaseController
        before_action :require_user!
        before_action :authorize_election!, only: %i[show update preview]

        rescue_from ::Configuration::ManageElection::NotAllowed, ::Configuration::PreviewElection::NotAllowed do |error|
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        end
        rescue_from ::Configuration::ManageElection::Locked do |error|
          render_api_error(code: 'configuration_locked', message: error.message, status: :conflict)
        end
        rescue_from ::Configuration::ManageElection::Stale do |error|
          render_api_error(code: 'stale_configuration', message: error.message, status: :conflict)
        end
        rescue_from ::Configuration::ManageElection::InvalidConfiguration,
                    ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique do
          render_api_error(code: 'invalid_configuration', message: 'Invalid election configuration',
                           status: :unprocessable_entity)
        end
        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Election not found', status: :not_found)
        end
        rescue_from ActionController::ParameterMissing do
          render_api_error(code: 'invalid_request', message: 'Election attributes are required', status: :bad_request)
        end

        def index
          roles = ElectionRole.where(user: current_user, role: 'creator', active: true).select(:election_id)
          elections = Election.where(school_installation: current_user.school_installation, id: roles)
                              .includes(:rounds).order(:id)
          render json: { elections: elections.map { |election| serialize(election) } }
        end

        def show
          render json: serialize(@election)
        end

        def preview
          render json: ::Configuration::PreviewElection.call(election: @election, actor: current_user)
        end

        def create
          election = ::Configuration::ManageElection.create(actor: current_user, attributes: election_attributes)
          render json: serialize(election), status: :created
        end

        def update
          election = ::Configuration::ManageElection.update(election: @election, actor: current_user,
                                                             attributes: election_attributes)
          render json: serialize(election)
        end

        private

        def authorize_election!
          @election = Election.find(params[:id])
          if current_user.school_installation_id != @election.school_installation_id
            render_api_error(code: 'forbidden', message: 'Role is required', status: :forbidden)
            return
          end
          require_role!(@election, 'creator')
        end

        def election_attributes
          params.require(:election).permit(:title, :description, :timezone, :opens_at, :closes_at,
                                            :configuration_version).to_h
        end

        def serialize(election)
          rounds = election.rounds.to_a
          first_round = rounds.find { |round| round.number == 1 }
          current_round = rounds.max_by(&:number)
          {
            id: election.id, title: election.title, description: election.description,
            timezone: election.timezone, state: current_round&.state || election.status,
            configuration_version: election.configuration_version,
            first_round: first_round && {
              id: first_round.id, number: first_round.number, opens_at: first_round.opens_at.utc.iso8601(6),
              closes_at: first_round.closes_at.utc.iso8601(6), grace_until: first_round.grace_until.utc.iso8601(6)
            }
          }
        end
      end
    end
  end
end
