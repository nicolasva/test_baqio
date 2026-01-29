# frozen_string_literal: true

# Customers::InactiveQuery Spec
# =============================
# Tests for the inactive/churned customers query.
#
# Covers:
# - call: all inactive customers
# - never_ordered: customers who never placed an order
# - no_recent_orders: customers with no orders in threshold period
# - with_abandoned_carts: customers with old pending orders
# - segmented: customers grouped by inactivity duration
#   - 30-60 days, 60-90 days, 90-180 days, 180+ days
# - stats: inactivity statistics
# - Custom inactive_since threshold
#

require "rails_helper"

RSpec.describe Customers::InactiveQuery do
  let(:account) { create(:account) }

  describe "#call" do
    it "returns all inactive customers" do
      # Customer who never ordered
      never_ordered = create(:customer, account: account)

      # Customer with old orders
      old_customer = create(:customer, account: account)
      create(:order, account: account, customer: old_customer, created_at: 6.months.ago)

      # Active customer
      active_customer = create(:customer, account: account)
      create(:order, account: account, customer: active_customer, created_at: 1.week.ago)

      result = described_class.new(account.customers).call

      expect(result).to include(never_ordered, old_customer)
      expect(result).not_to include(active_customer)
    end
  end

  describe "#never_ordered" do
    it "returns customers without any orders" do
      never_ordered = create(:customer, account: account)

      with_orders = create(:customer, account: account)
      create(:order, account: account, customer: with_orders)

      result = described_class.new(account.customers).never_ordered

      expect(result).to include(never_ordered)
      expect(result).not_to include(with_orders)
    end
  end

  describe "#no_recent_orders" do
    it "returns customers whose last order is old" do
      old_customer = create(:customer, account: account)
      create(:order, account: account, customer: old_customer, created_at: 6.months.ago)

      recent_customer = create(:customer, account: account)
      create(:order, account: account, customer: recent_customer, created_at: 1.week.ago)

      result = described_class.new(account.customers).no_recent_orders

      expect(result).to include(old_customer)
      expect(result).not_to include(recent_customer)
    end
  end

  describe "#with_abandoned_carts" do
    it "returns customers with old pending orders" do
      abandoned = create(:customer, account: account)
      create(:order, :pending, account: account, customer: abandoned, created_at: 10.days.ago)

      recent_pending = create(:customer, account: account)
      create(:order, :pending, account: account, customer: recent_pending, created_at: 1.day.ago)

      result = described_class.new(account.customers).with_abandoned_carts

      expect(result).to include(abandoned)
      expect(result).not_to include(recent_pending)
    end
  end

  describe "#segmented" do
    before do
      # 30-60 days inactive
      c1 = create(:customer, account: account)
      create(:order, account: account, customer: c1, created_at: 45.days.ago)

      # 60-90 days inactive
      c2 = create(:customer, account: account)
      create(:order, account: account, customer: c2, created_at: 75.days.ago)

      # 90-180 days inactive
      c3 = create(:customer, account: account)
      create(:order, account: account, customer: c3, created_at: 120.days.ago)

      # Over 180 days inactive
      c4 = create(:customer, account: account)
      create(:order, account: account, customer: c4, created_at: 200.days.ago)
    end

    it "segments customers by inactivity duration" do
      result = described_class.new(account.customers).segmented

      expect(result).to have_key(:inactive_30_60_days)
      expect(result).to have_key(:inactive_60_90_days)
      expect(result).to have_key(:inactive_90_180_days)
      expect(result).to have_key(:inactive_over_180_days)
    end
  end

  describe "#stats" do
    before do
      create(:customer, account: account) # never ordered
      c = create(:customer, account: account)
      create(:order, :pending, account: account, customer: c, created_at: 10.days.ago)
    end

    it "returns inactivity statistics" do
      stats = described_class.new(account.customers).stats

      expect(stats[:total_inactive]).to be >= 1
      expect(stats[:never_ordered]).to eq(1)
      expect(stats[:with_abandoned_carts]).to eq(1)
    end
  end

  describe "with custom inactive_since" do
    it "uses custom threshold" do
      customer = create(:customer, account: account)
      create(:order, account: account, customer: customer, created_at: 45.days.ago)

      # Default (90 days) - should not be inactive
      result_default = described_class.new(account.customers).no_recent_orders
      expect(result_default).not_to include(customer)

      # Custom (30 days) - should be inactive
      result_custom = described_class.new(account.customers, inactive_since: 30.days.ago).no_recent_orders
      expect(result_custom).to include(customer)
    end
  end
end
