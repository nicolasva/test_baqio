# frozen_string_literal: true

# FulfillmentService Factory
# ==========================
# Factory for creating FulfillmentService (shipping provider) records.
#
# Status traits:
# - :inactive - deactivated service
#
# Carrier traits:
# - :dhl - DHL Express
# - :ups - UPS
# - :fedex - FedEx
# - :colissimo - La Poste Colissimo
# - :chronopost - Chronopost
# - :mondial_relay - Mondial Relay pickup points
#
# With fulfillments traits:
# - :with_fulfillments - creates 3 pending fulfillments
# - :with_shipped_fulfillments - creates 3 shipped fulfillments
# - :with_delivered_fulfillments - creates 3 delivered fulfillments
# - :popular - creates 10 fulfillments with random statuses
#
# Examples:
#   create(:fulfillment_service)
#   create(:fulfillment_service, :dhl)
#   create(:fulfillment_service, :colissimo, :with_shipped_fulfillments)
#

FactoryBot.define do
  factory :fulfillment_service do
    account
    name { Faker::Company.name + " Logistics" }
    provider { %w[dhl ups fedex colissimo chronopost gls tnt mondial_relay].sample }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :dhl do
      name { "DHL Express" }
      provider { "dhl" }
    end

    trait :ups do
      name { "UPS" }
      provider { "ups" }
    end

    trait :fedex do
      name { "FedEx" }
      provider { "fedex" }
    end

    trait :colissimo do
      name { "Colissimo" }
      provider { "colissimo" }
    end

    trait :chronopost do
      name { "Chronopost" }
      provider { "chronopost" }
    end

    trait :mondial_relay do
      name { "Mondial Relay" }
      provider { "mondial_relay" }
    end

    trait :with_fulfillments do
      after(:create) do |service|
        create_list(:fulfillment, 3, fulfillment_service: service)
      end
    end

    trait :with_shipped_fulfillments do
      after(:create) do |service|
        create_list(:fulfillment, 3, :shipped, fulfillment_service: service)
      end
    end

    trait :with_delivered_fulfillments do
      after(:create) do |service|
        create_list(:fulfillment, 3, :delivered, fulfillment_service: service)
      end
    end

    trait :popular do
      after(:create) do |service|
        10.times do
          create(:fulfillment, %i[pending processing shipped delivered].sample, fulfillment_service: service)
        end
      end
    end
  end
end
