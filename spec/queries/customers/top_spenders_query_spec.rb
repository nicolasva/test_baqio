# frozen_string_literal: true

# Customers::TopSpendersQuery Spec
# ================================
# Tests for the top customers by spending query.
#
# Covers:
# - call: customers ranked by total spent (paid invoices)
# - Limit parameter (top N customers)
# - Excludes customers without paid invoices
# - with_stats: returns customer + statistics hash
#   - total_spent, orders_count, average_order_value
# - ids: returns only customer IDs
# - Period filter (this_month, last_month, etc.)
#

require "rails_helper"

RSpec.describe Customers::TopSpendersQuery do
  let(:account) { create(:account) }

  def create_customer_with_spending(amount)
    customer = create(:customer, account: account)
    order = create(:order, :validated, account: account, customer: customer)
    create(:invoice, :paid, order: order, amount: amount, tax_amount: 0)
    customer
  end

  describe "#call" do
    it "returns top spenders ordered by total spent" do
      low_spender = create_customer_with_spending(100)
      high_spender = create_customer_with_spending(500)
      medium_spender = create_customer_with_spending(250)

      result = described_class.new(account.customers, limit: 3).call

      expect(result.first.id).to eq(high_spender.id)
      expect(result.second.id).to eq(medium_spender.id)
      expect(result.third.id).to eq(low_spender.id)
    end

    it "respects the limit parameter" do
      5.times { create_customer_with_spending(100) }

      result = described_class.new(account.customers, limit: 3).call

      expect(result.to_a.size).to eq(3)
    end

    it "excludes customers without paid invoices" do
      create_customer_with_spending(100)
      create(:customer, account: account) # No orders

      result = described_class.new(account.customers).call

      expect(result.to_a.size).to eq(1)
    end
  end

  describe "#with_stats" do
    it "returns customers with statistics" do
      customer = create_customer_with_spending(200)

      result = described_class.new(account.customers, limit: 1).with_stats

      expect(result.first[:customer].id).to eq(customer.id)
      expect(result.first[:total_spent]).to eq(200)
      expect(result.first[:orders_count]).to eq(1)
    end
  end

  describe "#ids" do
    it "returns only customer IDs" do
      customer = create_customer_with_spending(100)

      result = described_class.new(account.customers).ids

      expect(result).to eq([customer.id])
    end
  end

  describe "with period filter" do
    it "filters by this_month" do
      # Customer with payment this month
      customer_this_month = create(:customer, account: account)
      order1 = create(:order, :validated, account: account, customer: customer_this_month)
      create(:invoice, :paid, order: order1, amount: 100, tax_amount: 0, paid_at: Date.current)

      # Customer with payment last month
      customer_last_month = create(:customer, account: account)
      order2 = create(:order, :validated, account: account, customer: customer_last_month)
      create(:invoice, :paid, order: order2, amount: 200, tax_amount: 0, paid_at: 1.month.ago)

      result = described_class.new(account.customers, period: :this_month).call

      expect(result.map(&:id)).to include(customer_this_month.id)
      expect(result.map(&:id)).not_to include(customer_last_month.id)
    end
  end
end
