# frozen_string_literal: true

# Order Factory
# =============
# Factory for creating Order records.
#
# Status traits:
# - :pending - order awaiting validation (default)
# - :validated - order ready for invoicing
# - :invoiced - order has been invoiced
# - :cancelled - order has been cancelled
#
# Fulfillment traits:
# - :with_fulfillment - attached pending fulfillment
# - :with_shipped_fulfillment - attached shipped fulfillment
# - :with_delivered_fulfillment - attached delivered fulfillment
#
# Line item traits:
# - :with_lines - 3 random order lines
# - :with_single_line - 1 order line
# - :with_specific_lines - custom lines via lines_data transient
# - :with_clothing_items - 2 clothing items
# - :with_electronics - 1 electronic item
# - :with_mixed_items - clothing + electronics + accessories
#
# Invoice traits:
# - :with_invoice - attached draft invoice
# - :with_paid_invoice - attached paid invoice
#
# Special traits:
# - :expensive - order with expensive items
# - :high_quantity - order with bulk quantity
# - :recent - created within last 7 days
# - :old - created 90 days ago
# - :complete - fully processed order (invoiced, paid, delivered)
# - :urgent - marked urgent with notes
# - :gift - marked as gift order
# - :b2b - business order with bulk items
# - :in_transit - invoiced and shipped
# - :awaiting_payment - invoiced, awaiting payment
# - :overdue_payment - invoiced with overdue payment
#
# Examples:
#   create(:order)
#   create(:order, :validated, :with_lines)
#   create(:order, :complete)
#   create(:order, :with_specific_lines, lines_data: [{name: "Shirt", quantity: 2, unit_price: 29.99}])
#

FactoryBot.define do
  factory :order do
    account
    customer { association :customer, account: account }
    fulfillment { nil }
    reference { "ORD-#{Time.current.strftime('%Y%m%d')}-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    status { "pending" }
    total_amount { 0 }
    notes { nil }

    trait :pending do
      status { "pending" }
    end

    trait :validated do
      status { "validated" }
    end

    trait :invoiced do
      status { "invoiced" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_fulfillment do
      fulfillment { association :fulfillment, fulfillment_service: association(:fulfillment_service, account: account) }
    end

    trait :with_shipped_fulfillment do
      fulfillment { association :fulfillment, :shipped, fulfillment_service: association(:fulfillment_service, account: account) }
    end

    trait :with_delivered_fulfillment do
      fulfillment { association :fulfillment, :delivered, fulfillment_service: association(:fulfillment_service, account: account) }
    end

    trait :with_notes do
      notes { Faker::Lorem.paragraph(sentence_count: 2) }
    end

    trait :with_lines do
      after(:create) do |order|
        create_list(:order_line, 3, order: order)
        order.update_total!
      end
    end

    trait :with_single_line do
      after(:create) do |order|
        create(:order_line, order: order, quantity: Faker::Number.between(from: 1, to: 3))
        order.update_total!
      end
    end

    trait :with_invoice do
      status { "invoiced" }
      after(:create) do |order|
        create(:invoice, order: order, amount: order.total_amount)
      end
    end

    trait :with_paid_invoice do
      status { "invoiced" }
      after(:create) do |order|
        create(:invoice, :paid, order: order, amount: order.total_amount)
      end
    end

    trait :expensive do
      after(:create) do |order|
        create(:order_line, :expensive, order: order, quantity: Faker::Number.between(from: 2, to: 5))
        order.update_total!
      end
    end

    trait :recent do
      created_at { Faker::Time.backward(days: 7) }
    end

    trait :old do
      created_at { Faker::Time.backward(days: 90) }
    end

    trait :complete do
      status { "invoiced" }
      after(:create) do |order|
        create_list(:order_line, 3, order: order)
        order.update_total!
        create(:invoice, :paid, order: order, amount: order.total_amount)
        fulfillment_service = create(:fulfillment_service, account: order.account)
        fulfillment = create(:fulfillment, :delivered, fulfillment_service: fulfillment_service)
        order.update!(fulfillment: fulfillment)
      end
    end

    trait :with_specific_lines do
      transient do
        lines_data { [] }
      end
      after(:create) do |order, evaluator|
        evaluator.lines_data.each do |line|
          create(:order_line,
            order: order,
            name: line[:name] || Faker::Commerce.product_name,
            quantity: line[:quantity] || 1,
            unit_price: line[:unit_price] || 10.0,
            sku: line[:sku]
          )
        end
        order.update_total!
      end
    end

    trait :with_clothing_items do
      after(:create) do |order|
        create(:order_line, :clothing, order: order)
        create(:order_line, :clothing, order: order)
        order.update_total!
      end
    end

    trait :with_electronics do
      after(:create) do |order|
        create(:order_line, :electronics, order: order)
        order.update_total!
      end
    end

    trait :with_mixed_items do
      after(:create) do |order|
        create(:order_line, :clothing, order: order)
        create(:order_line, :electronics, order: order)
        create(:order_line, :accessories, order: order)
        order.update_total!
      end
    end

    trait :high_quantity do
      after(:create) do |order|
        create(:order_line, :large_quantity, order: order)
        order.update_total!
      end
    end

    trait :urgent do
      notes { "URGENT - Livraison express requise" }
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
        order.update_total!
      end
    end

    trait :gift do
      notes { "Commande cadeau - Emballage spécial requis" }
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
        order.update_total!
      end
    end

    trait :b2b do
      notes { "Commande professionnelle - Facture avec TVA" }
      after(:create) do |order|
        create_list(:order_line, 5, :bulk, order: order)
        order.update_total!
      end
    end

    trait :in_transit do
      status { "invoiced" }
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
        order.update_total!
        create(:invoice, :sent, order: order, amount: order.total_amount)
        fulfillment_service = create(:fulfillment_service, account: order.account)
        fulfillment = create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
        order.update!(fulfillment: fulfillment)
      end
    end

    trait :awaiting_payment do
      status { "invoiced" }
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
        order.update_total!
        create(:invoice, :sent, order: order, amount: order.total_amount)
      end
    end

    trait :overdue_payment do
      status { "invoiced" }
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
        order.update_total!
        create(:invoice, :overdue, order: order, amount: order.total_amount)
      end
    end

  end
end
