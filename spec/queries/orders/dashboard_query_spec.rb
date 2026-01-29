# frozen_string_literal: true

# Orders::DashboardQuery Spec
# ===========================
# Tests for the dashboard statistics query.
#
# Covers:
# - call: orders filtered by period (today, this_week, this_month, custom range)
# - Eager loading of associations (customer, order_lines)
# - stats: aggregate statistics
#   - total_orders count
#   - total_revenue from paid invoices
#   - average_order_value
#   - orders_by_status breakdown
# - recent: limited list of recent orders
#

require "rails_helper"

RSpec.describe Orders::DashboardQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  describe "#call" do
    context "with today period" do
      it "returns orders created today" do
        today_order = create(:order, account: account, customer: customer, created_at: Time.current)
        create(:order, account: account, customer: customer, created_at: 2.days.ago)

        result = described_class.new(account.orders, period: :today).call

        expect(result).to include(today_order)
        expect(result.count).to eq(1)
      end
    end

    context "with this_week period" do
      it "returns orders created this week" do
        this_week_order = create(:order, account: account, customer: customer, created_at: Time.current.beginning_of_week + 1.day)
        create(:order, account: account, customer: customer, created_at: 2.weeks.ago)

        result = described_class.new(account.orders, period: :this_week).call

        expect(result).to include(this_week_order)
      end
    end

    context "with this_month period" do
      it "returns orders created this month" do
        this_month_order = create(:order, account: account, customer: customer, created_at: Time.current.beginning_of_month + 1.day)

        result = described_class.new(account.orders, period: :this_month).call

        expect(result).to include(this_month_order)
      end
    end

    context "with custom date range" do
      it "returns orders in the specified range" do
        in_range = create(:order, account: account, customer: customer, created_at: 5.days.ago)
        out_of_range = create(:order, account: account, customer: customer, created_at: 15.days.ago)

        result = described_class.new(account.orders, period: 10.days.ago..Time.current).call

        expect(result).to include(in_range)
        expect(result).not_to include(out_of_range)
      end
    end

    it "includes associations for eager loading" do
      create(:order, :with_lines, account: account, customer: customer)

      result = described_class.new(account.orders, period: :today).call

      expect(result.first.association(:customer).loaded?).to be true
      expect(result.first.association(:order_lines).loaded?).to be true
    end
  end

  describe "#stats" do
    before do
      # Create orders with different statuses
      create(:order, :pending, account: account, customer: customer)
      create(:order, :validated, account: account, customer: customer)

      # Create paid order
      paid_order = create(:order, :invoiced, account: account, customer: customer, total_amount: 100)
      create(:invoice, :paid, order: paid_order, amount: 100, tax_amount: 0)
    end

    it "returns total orders count" do
      stats = described_class.new(account.orders, period: :today).stats

      expect(stats[:total_orders]).to eq(3)
    end

    it "returns total revenue from paid invoices" do
      stats = described_class.new(account.orders, period: :today).stats

      expect(stats[:total_revenue]).to eq(100)
    end

    it "returns average order value" do
      stats = described_class.new(account.orders, period: :today).stats

      expect(stats[:average_order_value]).to be_present
    end

    it "returns orders grouped by status" do
      stats = described_class.new(account.orders, period: :today).stats

      expect(stats[:orders_by_status]).to include("pending" => 1, "validated" => 1, "invoiced" => 1)
    end
  end

  describe "#recent" do
    it "returns limited number of recent orders" do
      create_list(:order, 15, account: account, customer: customer)

      result = described_class.new(account.orders, period: :today).recent(limit: 5)

      expect(result.count).to eq(5)
    end
  end
end
