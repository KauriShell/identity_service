# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  validates :notification_type, presence: true
  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
