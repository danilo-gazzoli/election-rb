# frozen_string_literal: true

require 'rack/files'

module Feature9
  # Local acceptance entry point for the separate voting frontend and Rails.
  class SameOriginGateway
    STATIC_PATHS = %w[
      /votacao/index.html
      /votacao/src/app.js
      /votacao/src/flow.js
      /votacao/src/device_updates.js
      /votacao/src/styles.css
    ].freeze

    def initialize(app, frontend_root:)
      @app = app
      @files = Rack::Files.new(frontend_root.to_s)
    end

    def call(env)
      path = env.fetch('PATH_INFO')
      if path == '/'
        return [302, { 'location' => '/votacao/index.html', 'content-type' => 'text/plain' }, []]
      end
      if STATIC_PATHS.include?(path)
        return @files.call(env.merge('PATH_INFO' => path.delete_prefix('/votacao'),
                                     'SCRIPT_NAME' => "#{env['SCRIPT_NAME']}/votacao"))
      end
      return @app.call(env) if path == '/api/v1' || path.start_with?('/api/v1/') || path == '/cable'

      [404, { 'content-type' => 'text/plain' }, ['Not found']]
    end
  end
end
