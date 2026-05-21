# frozen_string_literal: true

Rails.application.config.after_initialize do
  Security::ProductionSecrets.verify!
end
