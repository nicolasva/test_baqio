# frozen_string_literal: true

# AccountEvent Factory
# ====================
# Factory for creating AccountEvent (audit log) records.
#
# Payload traits:
# - :with_payload - includes JSON payload with key, value, timestamp, user_agent
#
# Order event traits:
# - :order_created - "order.created" event
# - :order_validated - "order.validated" event
# - :order_cancelled - "order.cancelled" event
#
# Invoice event traits:
# - :invoice_created - "invoice.debit.created" event
# - :invoice_credit_created - "invoice.credit.created" event
# - :invoice_sent - "invoice.sent" event
# - :invoice_paid - "invoice.paid" event
#
# Fulfillment event traits:
# - :fulfillment_shipped - "fulfillment.shipped" event
# - :fulfillment_delivered - "fulfillment.delivered" event
#
# Date traits:
# - :recent - created within last 7 days
# - :old - created 90 days ago
#
# Examples:
#   create(:account_event)
#   create(:account_event, :order_created)
#   create(:account_event, :invoice_paid, :with_payload)
#

FactoryBot.define do
  factory :account_event do
    account
    resource
    event_type { "event.#{Faker::Verb.base}.#{Faker::Verb.past}" }
    payload { nil }

    trait :with_payload do
      payload do
        {
          key: Faker::Lorem.word,
          value: Faker::Lorem.sentence,
          timestamp: Faker::Time.backward(days: 30).iso8601,
          user_agent: Faker::Internet.user_agent
        }.to_json
      end
    end

    trait :order_created do
      event_type { "order.created" }
      resource { association :resource, :order }
    end

    trait :order_validated do
      event_type { "order.validated" }
      resource { association :resource, :order }
    end

    trait :order_cancelled do
      event_type { "order.cancelled" }
      resource { association :resource, :order }
    end

    trait :invoice_created do
      event_type { "invoice.debit.created" }
      resource { association :resource, :invoice }
    end

    trait :invoice_credit_created do
      event_type { "invoice.credit.created" }
      resource { association :resource, :invoice }
    end

    trait :invoice_sent do
      event_type { "invoice.sent" }
      resource { association :resource, :invoice }
    end

    trait :invoice_paid do
      event_type { "invoice.paid" }
      resource { association :resource, :invoice }
    end

    trait :fulfillment_shipped do
      event_type { "fulfillment.shipped" }
      resource { association :resource, :fulfillment }
    end

    trait :fulfillment_delivered do
      event_type { "fulfillment.delivered" }
      resource { association :resource, :fulfillment }
    end

    trait :recent do
      created_at { Faker::Time.backward(days: 7) }
    end

    trait :old do
      created_at { Faker::Time.backward(days: 90) }
    end
  end
end
