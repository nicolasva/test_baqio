# frozen_string_literal: true

# Invoices::AgingReportQuery Spec
# ===============================
# Tests for the accounts receivable aging report query.
#
# Covers:
# - call: all sent invoices (unpaid)
# - Aging buckets:
#   - current: not yet due
#   - overdue_1_30: 1-30 days overdue
#   - overdue_31_60: 31-60 days overdue
#   - overdue_over_90: 90+ days overdue
# - summary: counts and totals by bucket
# - total_overdue_amount: sum of all overdue invoices
#

require "rails_helper"

RSpec.describe Invoices::AgingReportQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  def create_invoice_with_due_date(due_at)
    order = create(:order, :validated, account: account, customer: customer)
    create(:invoice, :sent, order: order, due_at: due_at, issued_at: due_at - 30.days)
  end

  describe "#call" do
    it "returns only sent invoices" do
      order1 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :sent, order: order1)

      order2 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :draft, order: order2)

      result = described_class.new(account.invoices).call

      expect(result.count).to eq(1)
    end
  end

  describe "#current" do
    it "returns invoices not yet due" do
      create_invoice_with_due_date(5.days.from_now)
      create_invoice_with_due_date(5.days.ago)

      result = described_class.new(account.invoices).current

      expect(result.count).to eq(1)
    end
  end

  describe "#overdue_1_30" do
    it "returns invoices overdue by 1-30 days" do
      create_invoice_with_due_date(15.days.ago)
      create_invoice_with_due_date(45.days.ago)

      result = described_class.new(account.invoices).overdue_1_30

      expect(result.count).to eq(1)
    end
  end

  describe "#overdue_31_60" do
    it "returns invoices overdue by 31-60 days" do
      create_invoice_with_due_date(45.days.ago)
      create_invoice_with_due_date(15.days.ago)

      result = described_class.new(account.invoices).overdue_31_60

      expect(result.count).to eq(1)
    end
  end

  describe "#overdue_over_90" do
    it "returns invoices overdue by more than 90 days" do
      create_invoice_with_due_date(100.days.ago)
      create_invoice_with_due_date(45.days.ago)

      result = described_class.new(account.invoices).overdue_over_90

      expect(result.count).to eq(1)
    end
  end

  describe "#summary" do
    it "returns summary with counts and totals" do
      create_invoice_with_due_date(5.days.from_now)
      create_invoice_with_due_date(15.days.ago)
      create_invoice_with_due_date(45.days.ago)

      result = described_class.new(account.invoices).summary

      expect(result).to have_key(:current)
      expect(result).to have_key(:days_1_30)
      expect(result).to have_key(:days_31_60)
      expect(result[:days_1_30][:count]).to eq(1)
    end
  end

  describe "#total_overdue_amount" do
    it "calculates total amount of overdue invoices" do
      order1 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :sent, order: order1, amount: 100, tax_amount: 20, due_at: 15.days.ago)

      order2 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :sent, order: order2, amount: 200, tax_amount: 40, due_at: 30.days.ago)

      result = described_class.new(account.invoices).total_overdue_amount

      expect(result).to eq(360) # (100+20) + (200+40)
    end
  end
end
