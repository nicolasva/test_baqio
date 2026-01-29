# frozen_string_literal: true

# Invoices::RevenueQuery Spec
# ===========================
# Tests for the revenue analysis query.
#
# Covers:
# - call: paid invoices (with optional period filter)
# - total: total revenue including tax
# - total_excluding_tax: revenue without tax
# - total_tax: total tax amount collected
# - average_invoice_value: average invoice amount
# - comparison: period-over-period comparison
#   - current vs previous revenue
#   - difference and growth percentage
#

require "rails_helper"

RSpec.describe Invoices::RevenueQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  def create_paid_invoice(amount:, paid_at: Date.current)
    order = create(:order, :validated, account: account, customer: customer)
    create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: paid_at)
  end

  describe "#call" do
    it "returns only paid invoices" do
      create_paid_invoice(amount: 100)

      order = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :sent, order: order)

      result = described_class.new(account.invoices).call

      expect(result.count).to eq(1)
    end

    context "with period filter" do
      it "filters by this_month" do
        create_paid_invoice(amount: 100, paid_at: Date.current)
        create_paid_invoice(amount: 200, paid_at: 2.months.ago)

        result = described_class.new(account.invoices, period: :this_month).call

        expect(result.count).to eq(1)
      end
    end
  end

  describe "#total" do
    it "calculates total revenue" do
      create_paid_invoice(amount: 100)
      create_paid_invoice(amount: 200)

      result = described_class.new(account.invoices).total

      expect(result).to eq(300)
    end
  end

  describe "#total_excluding_tax" do
    it "calculates revenue without tax" do
      order = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :paid, order: order, amount: 100, tax_amount: 20)

      result = described_class.new(account.invoices).total_excluding_tax

      expect(result).to eq(100)
    end
  end

  describe "#total_tax" do
    it "calculates total tax" do
      order = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :paid, order: order, amount: 100, tax_amount: 20)

      result = described_class.new(account.invoices).total_tax

      expect(result).to eq(20)
    end
  end

  describe "#average_invoice_value" do
    it "calculates average invoice value" do
      create_paid_invoice(amount: 100)
      create_paid_invoice(amount: 200)
      create_paid_invoice(amount: 300)

      result = described_class.new(account.invoices).average_invoice_value

      expect(result).to eq(200)
    end

    it "returns 0 when no invoices" do
      result = described_class.new(account.invoices).average_invoice_value

      expect(result).to eq(0)
    end
  end

  describe "#comparison" do
    it "compares revenue between two periods" do
      create_paid_invoice(amount: 300, paid_at: Date.current)
      create_paid_invoice(amount: 200, paid_at: 1.month.ago)

      result = described_class.new(account.invoices).comparison(
        current_period: :this_month,
        previous_period: :last_month
      )

      expect(result[:current]).to eq(300)
      expect(result[:previous]).to eq(200)
      expect(result[:difference]).to eq(100)
      expect(result[:growth_percentage]).to eq(50.0)
    end
  end
end
