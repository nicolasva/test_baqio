# frozen_string_literal: true

# Account Factory
# ===============
# Factory for creating Account records (multi-tenant root model).
#
# Basic traits:
# - :with_customers - creates associated customers (default: 3)
# - :with_orders - creates a customer with orders (default: 3)
# - :with_fulfillment_services - creates shipping services (default: 2)
# - :with_revenue - creates a paid invoice for revenue testing
# - :with_pending_invoices - creates sent invoices awaiting payment
# - :with_overdue_invoices - creates overdue invoices
#
# Complete setup traits:
# - :boutique - small business setup (2 services, 5 customers with orders)
# - :enterprise - large business setup (5 services, 20 customers, multiple orders)
# - :complete - balanced setup with fulfillments attached to orders
#
# Named factories:
# - :demo_account - "Baqio Demo" account
# - :test_account - "Test Account" account
#
# Examples:
#   create(:account)
#   create(:account, :with_customers, customers_count: 5)
#   create(:account, :with_revenue, revenue_amount: 5000.0)
#   create(:account, :enterprise)
#

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }

    trait :with_customers do
      transient do
        customers_count { 3 }
      end
      after(:create) do |account, evaluator|
        create_list(:customer, evaluator.customers_count, account: account)
      end
    end

    trait :with_orders do
      transient do
        orders_count { 3 }
      end
      after(:create) do |account, evaluator|
        customer = create(:customer, account: account)
        create_list(:order, evaluator.orders_count, account: account, customer: customer)
      end
    end

    trait :with_fulfillment_services do
      transient do
        services_count { 2 }
      end
      after(:create) do |account, evaluator|
        create_list(:fulfillment_service, evaluator.services_count, account: account)
      end
    end

    trait :with_revenue do
      transient do
        revenue_amount { 1000.0 }
      end
      after(:create) do |account, evaluator|
        customer = create(:customer, account: account)
        order = create(:order, :validated, account: account, customer: customer, total_amount: evaluator.revenue_amount)
        create(:invoice, :paid, order: order, amount: evaluator.revenue_amount, tax_amount: 0)
      end
    end

    trait :with_pending_invoices do
      transient do
        invoices_count { 3 }
      end
      after(:create) do |account, evaluator|
        customer = create(:customer, account: account)
        evaluator.invoices_count.times do
          order = create(:order, :validated, account: account, customer: customer)
          create(:invoice, :sent, order: order)
        end
      end
    end

    trait :with_overdue_invoices do
      transient do
        overdue_count { 2 }
      end
      after(:create) do |account, evaluator|
        customer = create(:customer, account: account)
        evaluator.overdue_count.times do
          order = create(:order, :validated, account: account, customer: customer)
          create(:invoice, :overdue, order: order)
        end
      end
    end

    trait :boutique do
      name { "#{Faker::Color.color_name.capitalize} Boutique" }
      after(:create) do |account|
        create_list(:fulfillment_service, 2, account: account)
        5.times do
          customer = create(:customer, :with_full_info, account: account)
          create(:order, :with_lines, account: account, customer: customer)
        end
      end
    end

    trait :enterprise do
      name { "#{Faker::Company.name} Enterprise" }
      after(:create) do |account|
        create_list(:fulfillment_service, 5, account: account)
        20.times do
          customer = create(:customer, :with_full_info, account: account)
          3.times do
            order = create(:order, :with_lines, account: account, customer: customer)
            if rand < 0.7
              create(:invoice, %i[draft sent paid].sample, order: order, amount: order.total_amount)
            end
          end
        end
      end
    end

    trait :complete do
      after(:create) do |account|
        # Create fulfillment services
        services = create_list(:fulfillment_service, 3, account: account)

        # Create customers with orders
        3.times do
          customer = create(:customer, account: account)
          2.times do
            order = create(:order, :with_lines, account: account, customer: customer)
            if rand < 0.5
              fulfillment = create(:fulfillment, :shipped, fulfillment_service: services.sample)
              order.update!(fulfillment: fulfillment)
            end
          end
        end
      end
    end

    # Named accounts for specific test scenarios
    factory :demo_account do
      name { "Baqio Demo" }
    end

    factory :test_account do
      name { "Test Account" }
    end
  end
end
