# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def seed_privileged_user!(email:, password:, role:, first_name:, last_name:)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    password: password,
    password_confirmation: password,
    role: role,
    status: :active,
    kyc_status: :approved,
    first_name: first_name,
    last_name: last_name,
    confirmed_at: Time.current
  )
  user.save!
  puts "Seeded #{role}: #{email}"
end

admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "admin@trustbridge.local")
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "AdminPass1234!")
superadmin_email = ENV.fetch("SEED_SUPERADMIN_EMAIL", "superadmin@trustbridge.local")
superadmin_password = ENV.fetch("SEED_SUPERADMIN_PASSWORD", "SuperAdminPass1234!")

seed_privileged_user!(
  email: admin_email,
  password: admin_password,
  role: :admin,
  first_name: "Platform",
  last_name: "Admin"
)

seed_privileged_user!(
  email: superadmin_email,
  password: superadmin_password,
  role: :superadmin,
  first_name: "Platform",
  last_name: "Superadmin"
)

# Service tenants (X-Service-Token). Raw token must match escrow_service IDENTITY_SERVICE_TOKEN.
service_token = ENV.fetch("IDENTITY_SERVICE_TOKEN", "development_escrow_service_token")
ServiceTenant.find_or_initialize_by(name: "escrow_service").tap do |tenant|
  tenant.assign_attributes(
    active: true,
    description: "Escrow service (internal API)",
    token_digest: ServiceTenant.hash_token(service_token)
  )
  tenant.save!
end
puts "Seeded service tenant: escrow_service"
