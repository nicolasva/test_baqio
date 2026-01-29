# frozen_string_literal: true

# Orders::FilterQuery Spec
# ========================
# Tests for the order filtering query object.
#
# Covers:
# - Default behavior (all orders, sorted by created_at desc)
# - Status filter (single and multiple statuses)
# - Customer filter (by customer_id)
# - Date range filter (from_date, to_date)
# - Amount range filter (min_amount, max_amount)
# - Reference filter (partial match)
# - Invoice filter (has_invoice: true/false)
# - Sorting (sort_by, sort_dir)
# - Class method shortcut (.call)
#

require "rails_helper"

RSpec.describe Orders::FilterQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  describe "#call" do
    context "without filters" do
      it "returns all orders" do
        orders = create_list(:order, 3, account: account, customer: customer)
        result = described_class.new(account.orders).call

        expect(result.count).to eq(3)
      end

      it "orders by created_at desc by default" do
        old_order = create(:order, account: account, customer: customer, created_at: 2.days.ago)
        new_order = create(:order, account: account, customer: customer, created_at: 1.hour.ago)

        result = described_class.new(account.orders).call

        expect(result.first).to eq(new_order)
        expect(result.last).to eq(old_order)
      end
    end

    context "with status filter" do
      before do
        create(:order, :pending, account: account, customer: customer)
        create(:order, :validated, account: account, customer: customer)
        create(:order, :cancelled, account: account, customer: customer)
      end

      it "filters by single status" do
        result = described_class.new(account.orders, filters: { status: :pending }).call

        expect(result.count).to eq(1)
        expect(result.first.status).to eq("pending")
      end

      it "filters by multiple statuses" do
        result = described_class.new(account.orders, filters: { status: [:pending, :validated] }).call

        expect(result.count).to eq(2)
      end
    end

    context "with customer filter" do
      let(:other_customer) { create(:customer, account: account) }

      before do
        create(:order, account: account, customer: customer)
        create(:order, account: account, customer: other_customer)
      end

      it "filters by customer_id" do
        result = described_class.new(account.orders, filters: { customer_id: customer.id }).call

        expect(result.count).to eq(1)
        expect(result.first.customer).to eq(customer)
      end
    end

    context "with date range filter" do
      before do
        create(:order, account: account, customer: customer, created_at: 10.days.ago)
        create(:order, account: account, customer: customer, created_at: 5.days.ago)
        create(:order, account: account, customer: customer, created_at: 1.day.ago)
      end

      it "filters by from_date" do
        result = described_class.new(account.orders, filters: { from_date: 7.days.ago }).call

        expect(result.count).to eq(2)
      end

      it "filters by to_date" do
        result = described_class.new(account.orders, filters: { to_date: 3.days.ago }).call

        expect(result.count).to eq(2)
      end

      it "filters by date range" do
        result = described_class.new(account.orders, filters: {
          from_date: 7.days.ago,
          to_date: 3.days.ago
        }).call

        expect(result.count).to eq(1)
      end
    end

    context "with amount range filter" do
      before do
        create(:order, account: account, customer: customer, total_amount: 50)
        create(:order, account: account, customer: customer, total_amount: 150)
        create(:order, account: account, customer: customer, total_amount: 300)
      end

      it "filters by min_amount" do
        result = described_class.new(account.orders, filters: { min_amount: 100 }).call

        expect(result.count).to eq(2)
      end

      it "filters by max_amount" do
        result = described_class.new(account.orders, filters: { max_amount: 200 }).call

        expect(result.count).to eq(2)
      end
    end

    context "with reference filter" do
      before do
        create(:order, account: account, customer: customer, reference: "ORD-20240101-ABC123")
        create(:order, account: account, customer: customer, reference: "ORD-20240101-XYZ789")
      end

      it "filters by partial reference" do
        result = described_class.new(account.orders, filters: { reference: "ABC" }).call

        expect(result.count).to eq(1)
      end
    end

    context "with has_invoice filter" do
      before do
        order_with_invoice = create(:order, :invoiced, account: account, customer: customer)
        create(:invoice, order: order_with_invoice)
        create(:order, :pending, account: account, customer: customer)
      end

      it "filters orders with invoice" do
        result = described_class.new(account.orders, filters: { has_invoice: true }).call

        expect(result.count).to eq(1)
      end

      it "filters orders without invoice" do
        result = described_class.new(account.orders, filters: { has_invoice: false }).call

        expect(result.count).to eq(1)
      end
    end

    context "with sorting" do
      before do
        create(:order, account: account, customer: customer, total_amount: 100)
        create(:order, account: account, customer: customer, total_amount: 300)
        create(:order, account: account, customer: customer, total_amount: 200)
      end

      it "sorts by specified field" do
        result = described_class.new(account.orders, filters: {
          sort_by: :total_amount,
          sort_dir: :asc
        }).call

        expect(result.map(&:total_amount)).to eq([100, 200, 300])
      end
    end
  end

  describe ".call" do
    it "provides class method shortcut" do
      create(:order, account: account, customer: customer)

      result = described_class.call(account.orders)

      expect(result.count).to eq(1)
    end
  end
end
