# frozen_string_literal: true

class Device < ApplicationRecord
  belongs_to :user

  PLATFORMS = %w[ios android].freeze

  validates :platform, inclusion: { in: PLATFORMS }
  validates :push_token, presence: true, uniqueness: true
end
