# frozen_string_literal: true

# Mission Control Jobs UI (Solid Queue dashboard) protection.
# This is dev/test oriented; use env vars in docker-compose.
Rails.application.config.to_prepare do
  next unless defined?(MissionControl::Jobs)

  MissionControl::Jobs.http_basic_auth_user =
    ENV.fetch("MISSION_CONTROL_JOBS_USER", "dev")

  MissionControl::Jobs.http_basic_auth_password =
    ENV.fetch("MISSION_CONTROL_JOBS_PASSWORD", "change-me")
end

