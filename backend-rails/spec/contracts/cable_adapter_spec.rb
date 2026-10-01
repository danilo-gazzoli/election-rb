# frozen_string_literal: true

require 'rails_helper'
require 'erb'
require 'yaml'

RSpec.describe 'Action Cable deployment configuration' do
  it 'uses the PostgreSQL adapter required by the solution design for a school deployment' do
    source = Rails.root.join('config/cable.yml').read
    production = YAML.safe_load(ERB.new(source).result).fetch('production')

    expect(production.fetch('adapter')).to eq('postgresql')
  end
end
