# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ContestsController < BaseController
        before_action :require_user!

        rescue_from ActiveRecord::RecordNotFound do
          render_api_error(code: 'not_found', message: 'Election or contest not found', status: :not_found)
        end

        def index
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          contests = election.contests.order(:position, :id).includes(candidacies: %i[principal_person vice_person])
          render json: { contests: contests.map { |contest| contest_payload(contest) } }
        end

        def show
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          contest = election.contests.includes(candidacies: %i[principal_person vice_person]).find(params[:id])
          render json: { contest: contest_payload(contest) }
        end

        def create
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          attributes = params.require(:contest).permit(
            :name, :position, :method, :seats, :choices_per_person, :has_vice,
            candidacies: %i[principal_name principal_party_id ballot_number vice_name vice_party_id]
          ).to_h.symbolize_keys
          contest = ::Configuration::CreateContest.call(election: election, actor: current_user,
                                                      attributes: attributes)
          render json: { id: contest.id }, status: :created
        rescue ::Configuration::CreateContest::Locked => e
          render_configuration_locked(message: e.message)
        rescue ::Configuration::CreateContest::NotAllowed => e
          render_api_error(code: 'forbidden', message: e.message, status: :forbidden)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render_api_error(code: 'invalid_configuration', message: 'Invalid contest configuration',
                           status: :unprocessable_entity)
        end

        def update
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          attributes = params.require(:contest).permit(
            :name, :position, :method, :seats, :choices_per_person, :has_vice
          ).to_h.symbolize_keys
          contest = ::Configuration::UpdateContest.call(election: election, contest_id: params[:id],
                                                        actor: current_user, attributes: attributes)
          render json: { contest: contest_payload(contest) }
        rescue ::Configuration::UpdateContest::Locked => error
          render_configuration_locked(message: error.message)
        rescue ::Configuration::UpdateContest::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render_api_error(code: 'invalid_configuration', message: 'Invalid contest configuration',
                           status: :unprocessable_entity)
        end

        def destroy
          election = @election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          ::Configuration::DeleteContest.call(election: election, contest_id: params[:id], actor: current_user)
          head :no_content
        rescue ::Configuration::DeleteContest::Locked => error
          render_configuration_locked(message: error.message)
        rescue ::Configuration::DeleteContest::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ::Configuration::DeleteContest::InUse, ActiveRecord::InvalidForeignKey
          render_api_error(code: 'contest_in_use', message: 'Contest is referenced by election data', status: :conflict)
        end

        private

        def contest_payload(contest)
          contest.attributes.slice('id', 'name', 'position', 'method', 'seats', 'choices_per_person',
                                   'has_vice', 'rule_version').merge(
            'candidacies' => contest.candidacies.sort_by(&:id).map do |candidate|
              candidate.attributes.slice('id', 'ballot_number', 'state', 'principal_party_id', 'vice_party_id').merge(
                'principal_person' => candidate.principal_person.attributes.slice('id', 'name'),
                'vice_person' => candidate.vice_person&.attributes&.slice('id', 'name')
              )
            end
          )
        end
      end
    end
  end
end
