# frozen_string_literal: true

# Development customers seed

after "development:01_accounts" do
  puts "Seeding customers..."

  Faker::Config.locale = "fr"

  demo_account = Account.find_by!(name: "Baqio Demo")

  30.times do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name

    Customer.create!(
      account: demo_account,
      first_name: first_name,
      last_name: last_name,
      email: Faker::Internet.unique.email(name: "#{first_name} #{last_name}", separators: [".", "_"]),
      phone: Faker::PhoneNumber.cell_phone_in_e164,
      address: [
        Faker::Address.street_address,
        "#{Faker::Address.zip_code} #{Faker::Address.city}",
        "France"
      ].join("\n")
    )
  end

  Faker::UniqueGenerator.clear

  puts "  -> #{demo_account.customers.count} customers created"
end
