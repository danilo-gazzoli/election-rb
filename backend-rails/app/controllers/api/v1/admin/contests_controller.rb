# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ContestsController < BaseController
        before_action :require_user!

        def create
          election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          attributes = params.require(:contest).permit(
            :name, :position, :method, :seats, :choices_per_person, :has_vice,
            candidacies: %i[principal_name principal_party_id ballot_number]
          ).to_h.symbolize_keys
          contest = ::Configuration::CreateContest.call(election: election, actor: current_user,
                                                      attributes: attributes)
          render json: { id: contest.id }, status: :created
        rescue ::Configuration::CreateContest::Locked => e
          render_api_error(code: 'configuration_locked', message: e.message, status: :conflict)
        rescue ::Configuration::CreateContest::NotAllowed => e
          render_api_error(code: 'forbidden', message: e.message, status: :forbidden)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render_api_error(code: 'invalid_configuration', message: 'Invalid contest configuration',
                           status: :unprocessable_entity)
        end
      end
    end
  end
end
