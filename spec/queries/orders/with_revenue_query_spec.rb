# frozen_string_literal: true

# Orders::WithRevenueQuery Spec
# =============================
# Tests for the revenue analysis query.
#
# Covers:
# - call: orders with paid invoices (includes invoice_total)
# - total_revenue: sum of all paid invoice amounts
# - average_revenue: average revenue per order
# - revenue_by_period: grouped by month/week
# - top_products: products ranked by revenue
#

require "rails_helper"

RSpec.describe Orders::WithRevenueQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  def create_paid_order(amount:, paid_at: Date.current)
    order = create(:order, :invoiced, account: account, customer: customer, total_amount: amount)
    create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: paid_at)
    order
  end

  describe "#call" do
    it "returns only orders with paid invoices" do
      paid_order = create_paid_order(amount: 100)

      unpaid_order = create(:order, :invoiced, account: account, customer: customer)
      create(:invoice, :sent, order: unpaid_order)

      result = described_class.new(account.orders).call

      expect(result).to include(paid_order)
      expect(result).not_to include(unpaid_order)
    end

    it "includes invoice total in results" do
      create_paid_order(amount: 150)

      result = described_class.new(account.orders).call.first

      expect(result.invoice_total).to eq(150)
    end
  end

  describe "#total_revenue" do
    it "calculates total revenue" do
      create_paid_order(amount: 100)
      create_paid_order(amount: 200)
      create_paid_order(amount: 300)

      result = described_class.new(account.orders).total_revenue

      expect(result).to eq(600)
    end

    it "returns 0 when no paid orders" do
      result = described_class.new(account.orders).total_revenue

      expect(result).to eq(0)
    end
  end

  describe "#average_revenue" do
    it "calculates average revenue per order" do
      create_paid_order(amount: 100)
      create_paid_order(amount: 200)

      result = described_class.new(account.orders).average_revenue

      expect(result).to eq(150)
    end

    it "returns 0 when no orders" do
      result = described_class.new(account.orders).average_revenue

      expect(result).to eq(0)
    end
  end

  describe "#revenue_by_period" do
    before do
      create_paid_order(amount: 100, paid_at: Date.current)
      create_paid_order(amount: 200, paid_at: 1.month.ago)
      create_paid_order(amount: 150, paid_at: 1.month.ago)
    end

    it "groups revenue by month" do
      result = described_class.new(account.orders).revenue_by_period(group_by: :month)

      expect(result.values).to include(100, 350)
    end
  end

  describe "#top_products" do
    before do
      order1 = create_paid_order(amount: 100)
      create(:order_line, order: order1, name: "Product A", quantity: 2, unit_price: 50)

      order2 = create_paid_order(amount: 200)
      create(:order_line, order: order2, name: "Product B", quantity: 1, unit_price: 200)

      order3 = create_paid_order(amount: 150)
      create(:order_line, order: order3, name: "Product A", quantity: 3, unit_price: 50)
    end

    it "returns top products by revenue" do
      result = described_class.new(account.orders).top_products(limit: 5)

      expect(result.keys).to include("Product A", "Product B")
      expect(result["Product A"]).to eq(250) # (2*50) + (3*50)
      expect(result["Product B"]).to eq(200)
    end
  end
end
