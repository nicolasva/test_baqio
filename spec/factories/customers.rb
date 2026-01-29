# frozen_string_literal: true

# Customer Factory
# ================
# Factory for creating Customer records.
#
# Info traits (modify customer data):
# - :without_email - customer with no email
# - :without_name - customer with no first/last name
# - :without_phone - customer with no phone
# - :minimal - customer with only email (no name, phone, address)
# - :with_full_info - customer with complete address details
#
# Order traits (create associated orders):
# - :with_orders - creates orders (default: 3)
# - :with_paid_invoices - creates paid invoices (default: 1)
# - :with_pending_orders - creates pending orders (default: 2)
# - :with_complete_orders - creates fully completed orders (default: 2)
#
# Value traits:
# - :vip - high-value customer with multiple paid orders
# - :high_value - customer with high-value paid invoices (€1000-5000)
# - :inactive - customer with no recent activity (6+ months)
#
# Location traits:
# - :french - customer with French phone/address format
# - :belgian - customer with Belgian phone/address format
# - :swiss - customer with Swiss phone/address format
#
# Named factories:
# - :jean_dupont - test customer "Jean Dupont"
# - :marie_martin - test customer "Marie Martin"
#
# Examples:
#   create(:customer)
#   create(:customer, :vip, vip_orders_count: 10)
#   create(:customer, :french, :with_orders)
#

FactoryBot.define do
  factory :customer do
    account
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    address { "#{Faker::Address.street_address}\n#{Faker::Address.zip_code} #{Faker::Address.city}\nFrance" }

    trait :without_email do
      email { nil }
    end

    trait :without_name do
      first_name { nil }
      last_name { nil }
    end

    trait :without_phone do
      phone { nil }
    end

    trait :minimal do
      first_name { nil }
      last_name { nil }
      phone { nil }
      address { nil }
    end

    trait :with_full_info do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      phone { Faker::PhoneNumber.cell_phone_in_e164 }
      address do
        [
          Faker::Address.street_address,
          Faker::Address.secondary_address,
          "#{Faker::Address.zip_code} #{Faker::Address.city}",
          "France"
        ].join("\n")
      end
    end

    trait :with_orders do
      transient do
        orders_count { 3 }
      end
      after(:create) do |customer, evaluator|
        create_list(:order, evaluator.orders_count, customer: customer, account: customer.account)
      end
    end

    trait :with_paid_invoices do
      transient do
        invoices_count { 1 }
        invoice_amount { Faker::Commerce.price(range: 50..500) }
      end
      after(:create) do |customer, evaluator|
        evaluator.invoices_count.times do
          order = create(:order, :validated, customer: customer, account: customer.account)
          create(:invoice, :paid, order: order, amount: evaluator.invoice_amount, tax_amount: 0)
        end
      end
    end

    trait :with_pending_orders do
      transient do
        pending_count { 2 }
      end
      after(:create) do |customer, evaluator|
        create_list(:order, evaluator.pending_count, :pending, customer: customer, account: customer.account)
      end
    end

    trait :with_complete_orders do
      transient do
        complete_count { 2 }
      end
      after(:create) do |customer, evaluator|
        evaluator.complete_count.times do
          create(:order, :complete, customer: customer, account: customer.account)
        end
      end
    end

    trait :vip do
      transient do
        vip_orders_count { 5 }
        vip_amount_range { 200..1000 }
      end
      after(:create) do |customer, evaluator|
        evaluator.vip_orders_count.times do
          order = create(:order, :validated, customer: customer, account: customer.account)
          create(:invoice, :paid, order: order, amount: Faker::Commerce.price(range: evaluator.vip_amount_range))
        end
      end
    end

    trait :french do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      phone { "+33#{Faker::Number.number(digits: 9)}" }
      address do
        [
          Faker::Address.street_address,
          "#{Faker::Number.number(digits: 5)} #{Faker::Address.city}",
          "France"
        ].join("\n")
      end
    end

    trait :belgian do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      phone { "+32#{Faker::Number.number(digits: 9)}" }
      address do
        [
          Faker::Address.street_address,
          "#{Faker::Number.number(digits: 4)} #{Faker::Address.city}",
          "Belgique"
        ].join("\n")
      end
    end

    trait :swiss do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      phone { "+41#{Faker::Number.number(digits: 9)}" }
      address do
        [
          Faker::Address.street_address,
          "#{Faker::Number.number(digits: 4)} #{Faker::Address.city}",
          "Suisse"
        ].join("\n")
      end
    end

    trait :inactive do
      after(:create) do |customer|
        # Customer with no recent activity - orders from 6+ months ago
        order = create(:order, :validated, customer: customer, account: customer.account, created_at: 6.months.ago)
        create(:invoice, :paid, order: order, created_at: 6.months.ago)
      end
    end

    trait :high_value do
      after(:create) do |customer|
        3.times do
          order = create(:order, :validated, customer: customer, account: customer.account)
          create(:invoice, :paid, order: order, amount: Faker::Commerce.price(range: 1000..5000), tax_amount: 0)
        end
      end
    end

    # Named customers for specific test scenarios
    factory :jean_dupont do
      first_name { "Jean" }
      last_name { "Dupont" }
      email { "jean.dupont@example.com" }
    end

    factory :marie_martin do
      first_name { "Marie" }
      last_name { "Martin" }
      email { "marie.martin@example.com" }
    end
  end
end
