# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      def login
        return unless allow_attempt!(scope: 'login_ip', identity: request.remote_ip, limit: 30, period: 900)
        return unless allow_attempt!(scope: 'login_account', identity: params[:login].to_s, limit: 10, period: 900)

        installation = SchoolInstallation.first
        user = User.find_by(school_installation: installation, login: params[:login], active: true)
        unless user&.authenticate(params[:password])
          return render_api_error(code: 'invalid_credentials', message: 'Invalid login or password',
                                  status: :unauthorized)
        end

        reset_session
        session[:user_id] = user.id
        session[:user_expires_at] = 8.hours.from_now.to_i
        render json: { user: public_user(user), csrf_token: form_authenticity_token }
      end

      def logout
        reset_session
        head :no_content
      end

      def show
        render json: { user: current_user && public_user(current_user),
                       csrf_token: form_authenticity_token }
      end

      private

      def public_user(user)
        { id: user.id, name: user.name, login: user.login }
      end
    end
  end
end
