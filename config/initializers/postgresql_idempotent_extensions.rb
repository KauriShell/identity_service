# frozen_string_literal: true

# Defense in depth: Docker entrypoint (`bin/docker-entrypoint`) uses `flock` so only
# one process runs `db:prepare` at a time (avoids parallel schema loads / duplicate
# tables). If CREATE EXTENSION still races, treat pg_extension_unique_violation as
# success—the extension is already present.
module PostgreSQLIdempotentExtensions
  def enable_extension(name, **)
    super
  rescue ActiveRecord::RecordNotUnique => e
    raise unless duplicate_pg_extension_race?(e)

    reload_type_map
  end

  private

  def duplicate_pg_extension_race?(error)
    msg = [error.cause&.message, error.message].compact.join(" ")
    msg.include?("pg_extension_name_index")
  end
end

Rails.application.config.after_initialize do
  require "active_record/connection_adapters/postgresql_adapter"

  adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  unless adapter.ancestors.include?(PostgreSQLIdempotentExtensions)
    adapter.prepend(PostgreSQLIdempotentExtensions)
  end
end
