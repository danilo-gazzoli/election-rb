# frozen_string_literal: true

require_relative '../../backend-rails/config/environment'
require_relative 'same_origin_gateway'

run Feature9::SameOriginGateway.new(
  Rails.application,
  frontend_root: File.expand_path('../../frontend-voting', __dir__)
)
Rails.application.load_server
