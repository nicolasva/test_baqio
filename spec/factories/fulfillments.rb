# frozen_string_literal: true

# Fulfillment Factory
# ===================
# Factory for creating Fulfillment (shipment) records.
#
# Status traits:
# - :pending - awaiting processing (default)
# - :processing - being prepared for shipment
# - :shipped - shipped with tracking number and carrier
# - :delivered - delivered to customer
# - :cancelled - shipment cancelled
#
# Delivery speed traits:
# - :express - 1-day delivery via Chronopost Express
# - :fast_delivery - delivered in 1 day
# - :long_transit - 13-day transit time (slow delivery)
#
# Special traits:
# - :international - international shipment with INT prefix
# - :with_orders - creates 2 associated orders
#
# Examples:
#   create(:fulfillment)
#   create(:fulfillment, :shipped)
#   create(:fulfillment, :delivered, shipped_at: 5.days.ago)
#   create(:fulfillment, :express, ship_date: 1.day.ago)
#

FactoryBot.define do
  factory :fulfillment do
    fulfillment_service
    status { "pending" }
    tracking_number { nil }
    carrier { nil }
    shipped_at { nil }
    delivered_at { nil }

    trait :pending do
      status { "pending" }
    end

    trait :processing do
      status { "processing" }
    end

    trait :shipped do
      status { "shipped" }
      tracking_number { "#{%w[DHL UPS FEDEX TNT GLS].sample}#{Faker::Number.number(digits: 12)}" }
      carrier { fulfillment_service&.name || Faker::Company.name }
      shipped_at { Faker::Time.backward(days: 5) }
    end

    trait :delivered do
      status { "delivered" }
      tracking_number { "#{%w[DHL UPS FEDEX TNT GLS].sample}#{Faker::Number.number(digits: 12)}" }
      carrier { fulfillment_service&.name || Faker::Company.name }
      shipped_at { Faker::Time.backward(days: 7) }
      delivered_at { Faker::Time.between(from: shipped_at, to: Time.current) }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :express do
      carrier { "Chronopost Express" }
      transient do
        ship_date { 2.days.ago }
      end
      shipped_at { ship_date }
      delivered_at { ship_date + 1.day }
    end

    trait :international do
      tracking_number { "INT#{Faker::Number.number(digits: 15)}" }
      carrier { %w[DHL FedEx UPS].sample }
    end

    trait :with_orders do
      after(:create) do |fulfillment|
        account = fulfillment.fulfillment_service.account
        customer = create(:customer, account: account)
        create_list(:order, 2, fulfillment: fulfillment, account: account, customer: customer)
      end
    end

    trait :long_transit do
      status { "delivered" }
      tracking_number { "SLOW#{Faker::Number.number(digits: 10)}" }
      carrier { "Standard Post" }
      shipped_at { 15.days.ago }
      delivered_at { 2.days.ago }
    end

    trait :fast_delivery do
      status { "delivered" }
      tracking_number { "EXPRESS#{Faker::Number.number(digits: 10)}" }
      carrier { "Express Delivery" }
      shipped_at { 2.days.ago }
      delivered_at { 1.day.ago }
    end
  end
end
