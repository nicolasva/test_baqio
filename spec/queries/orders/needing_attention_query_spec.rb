# frozen_string_literal: true

# Orders::NeedingAttentionQuery Spec
# ==================================
# Tests for the problematic orders detection query.
#
# Covers:
# - call: all orders needing attention
# - pending_too_long: orders pending > 3 days
# - validated_not_invoiced: validated orders without invoice > 7 days
# - invoiced_with_overdue_payment: orders with overdue invoices
# - awaiting_shipment: paid orders without fulfillment
# - grouped: orders grouped by problem type
#

require "rails_helper"

RSpec.describe Orders::NeedingAttentionQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  describe "#call" do
    it "returns orders needing attention" do
      # Order pending trop longtemps
      create(:order, :pending, account: account, customer: customer, created_at: 5.days.ago)

      # Order normal (ne devrait pas être inclus)
      create(:order, :pending, account: account, customer: customer, created_at: 1.day.ago)

      result = described_class.new(account.orders).call

      expect(result.count).to eq(1)
    end
  end

  describe "#pending_too_long" do
    it "returns orders pending for more than 3 days" do
      old_pending = create(:order, :pending, account: account, customer: customer, created_at: 5.days.ago)
      create(:order, :pending, account: account, customer: customer, created_at: 1.day.ago)

      result = described_class.new(account.orders).pending_too_long

      expect(result).to include(old_pending)
      expect(result.count).to eq(1)
    end
  end

  describe "#validated_not_invoiced" do
    it "returns validated orders without invoice after 7 days" do
      old_validated = create(:order, :validated, account: account, customer: customer, created_at: 10.days.ago)
      create(:order, :validated, account: account, customer: customer, created_at: 3.days.ago)

      result = described_class.new(account.orders).validated_not_invoiced

      expect(result).to include(old_validated)
      expect(result.count).to eq(1)
    end
  end

  describe "#invoiced_with_overdue_payment" do
    it "returns invoiced orders with overdue invoices" do
      order = create(:order, :invoiced, account: account, customer: customer)
      create(:invoice, :overdue, order: order)

      create(:order, :invoiced, account: account, customer: customer)

      result = described_class.new(account.orders).invoiced_with_overdue_payment

      expect(result.count).to eq(1)
      expect(result.first).to eq(order)
    end
  end

  describe "#awaiting_shipment" do
    it "returns paid orders without fulfillment" do
      order = create(:order, :invoiced, account: account, customer: customer, fulfillment: nil)
      create(:invoice, :paid, order: order)

      result = described_class.new(account.orders).awaiting_shipment

      expect(result.count).to eq(1)
      expect(result.first).to eq(order)
    end
  end

  describe "#grouped" do
    it "returns orders grouped by problem type" do
      create(:order, :pending, account: account, customer: customer, created_at: 5.days.ago)

      result = described_class.new(account.orders).grouped

      expect(result.keys).to contain_exactly(:pending_too_long, :validated_not_invoiced, :invoiced_overdue, :awaiting_shipment)
    end
  end
end
