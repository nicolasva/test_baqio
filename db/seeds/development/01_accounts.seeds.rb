# frozen_string_literal: true

# Development accounts seed

puts "Seeding accounts..."

Faker::Config.locale = "fr"

accounts = [
  { name: "Baqio Demo" },
  { name: Faker::Company.name }
]

accounts.each do |account_attrs|
  Account.find_or_create_by!(name: account_attrs[:name])
end

puts "  -> #{Account.count} accounts created"
