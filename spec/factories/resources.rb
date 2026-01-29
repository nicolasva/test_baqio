# frozen_string_literal: true

# Resource Factory
# ================
# Factory for creating Resource records (polymorphic reference for events).
#
# Type traits:
# - :order - resource of type "Order"
# - :invoice - resource of type "Invoice"
# - :customer - resource of type "Customer"
# - :fulfillment - resource of type "Fulfillment"
#
# Other traits:
# - :with_random_name - generates random name with resource type prefix
#
# Note: Resource is used by AccountEvent to reference any model
# type without a direct foreign key relationship.
#
# Examples:
#   create(:resource)
#   create(:resource, :order)
#   create(:resource, :invoice, :with_random_name)
#

FactoryBot.define do
  factory :resource do
    sequence(:name) { |n| "Resource##{n}" }
    resource_type { "Order" }

    trait :order do
      resource_type { "Order" }
      sequence(:name) { |n| "Order##{n}" }
    end

    trait :invoice do
      resource_type { "Invoice" }
      sequence(:name) { |n| "Invoice##{n}" }
    end

    trait :customer do
      resource_type { "Customer" }
      sequence(:name) { |n| "Customer##{n}" }
    end

    trait :fulfillment do
      resource_type { "Fulfillment" }
      sequence(:name) { |n| "Fulfillment##{n}" }
    end

    trait :with_random_name do
      name { "#{resource_type}##{Faker::Number.number(digits: 6)}" }
    end
  end
end
