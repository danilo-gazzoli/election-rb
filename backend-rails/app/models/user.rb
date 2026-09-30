# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :school_installation
  has_secure_password
  validates :name, :login, presence: true
  validates :login, uniqueness: { scope: :school_installation_id }
end
