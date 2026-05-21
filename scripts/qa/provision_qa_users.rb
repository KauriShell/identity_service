# frozen_string_literal: true

# Run inside identity container:
#   bundle exec rails runner /path/to/provision_qa_users.rb
# Or: docker exec tb_identity sh -c 'cd /rails && bundle exec rails runner scripts/qa/provision_qa_users.rb'
# (copy script into container or mount repo)

PASSWORD = "QaTestPass1234!"

USERS = [
  { email: "qa-buyer@trustbridge.test", role: :member, first_name: "QA", last_name: "Buyer" },
  { email: "qa-seller@trustbridge.test", role: :member, first_name: "QA", last_name: "Seller" },
  { email: "qa-mediator1@trustbridge.test", role: :mediator, first_name: "QA", last_name: "Mediator One" },
  { email: "qa-mediator2@trustbridge.test", role: :mediator, first_name: "QA", last_name: "Mediator Two" }
].freeze

def upsert_user!(email:, password:, role:, first_name:, last_name:)
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
  user
end

puts "=== Provisioning QA users (identity) ==="
USERS.each do |attrs|
  user = upsert_user!(password: PASSWORD, **attrs)
  puts "  #{user.role.ljust(10)} #{user.email} id=#{user.id}"
end

admin = upsert_user!(
  email: "admin@trustbridge.local",
  password: PASSWORD,
  role: :admin,
  first_name: "Platform",
  last_name: "Admin"
)
puts "  #{admin.role.ljust(10)} #{admin.email} id=#{admin.id}"

puts "\nQA_PASSWORD=#{PASSWORD}"
puts "Done."
