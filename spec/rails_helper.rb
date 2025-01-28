require 'simplecov'
require 'simplecov-html'
require 'simplecov_json_formatter'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.start do
  add_group 'Config', 'config'
  add_group 'Controllers', 'app/controllers'
  add_group 'Libs', 'lib'
  add_group 'Models', 'app/models'
  add_group 'Serializers', 'app/serializers'
  add_group 'Specs', 'spec'
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'shoulda/matchers'

Capybara.default_driver = :rack_test

Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods

  # shoulda matchers config
  Shoulda::Matchers.configure do |config| 
    config.integrate do |with| 
      with.library :rails
      with.test_framework :rspec
    end
  end

  config.include Request::JsonHelpers, type: :request
end
