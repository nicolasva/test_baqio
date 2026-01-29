# frozen_string_literal: true

# Invoices::NeedingFollowUpQuery Spec
# ===================================
# Tests for the collection prioritization query.
#
# Covers:
# - call: all invoices needing follow-up
# - Priority levels:
#   - critical: 60+ days overdue
#   - high_priority: 30-60 days overdue
#   - medium_priority: 1-30 days overdue
#   - low_priority: due within 7 days
# - due_today: invoices due today
# - grouped_by_priority: invoices grouped by priority level
# - stats: overdue statistics (total, due this week, average days overdue)
#

require "rails_helper"

RSpec.describe Invoices::NeedingFollowUpQuery do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  def create_invoice_with_due_date(due_at, status: :sent)
    order = create(:order, :validated, account: account, customer: customer)
    create(:invoice, status, order: order, due_at: due_at, issued_at: due_at - 30.days)
  end

  describe "#call" do
    it "returns all invoices needing follow up" do
      create_invoice_with_due_date(5.days.from_now) # low priority
      create_invoice_with_due_date(15.days.ago)      # medium priority
      create_invoice_with_due_date(45.days.ago)      # high priority

      result = described_class.new(account.invoices).call

      expect(result.count).to eq(3)
    end
  end

  describe "#critical" do
    it "returns invoices overdue by more than 60 days" do
      critical = create_invoice_with_due_date(70.days.ago)
      create_invoice_with_due_date(30.days.ago)

      result = described_class.new(account.invoices).critical

      expect(result).to include(critical)
      expect(result.count).to eq(1)
    end
  end

  describe "#high_priority" do
    it "returns invoices overdue by 30-60 days" do
      high = create_invoice_with_due_date(45.days.ago)
      create_invoice_with_due_date(15.days.ago)
      create_invoice_with_due_date(70.days.ago)

      result = described_class.new(account.invoices).high_priority

      expect(result).to include(high)
      expect(result.count).to eq(1)
    end
  end

  describe "#medium_priority" do
    it "returns invoices overdue by 1-30 days" do
      medium = create_invoice_with_due_date(15.days.ago)
      create_invoice_with_due_date(45.days.ago)

      result = described_class.new(account.invoices).medium_priority

      expect(result).to include(medium)
      expect(result.count).to eq(1)
    end
  end

  describe "#low_priority" do
    it "returns invoices due within 7 days" do
      low = create_invoice_with_due_date(5.days.from_now)
      create_invoice_with_due_date(15.days.from_now)

      result = described_class.new(account.invoices).low_priority

      expect(result).to include(low)
      expect(result.count).to eq(1)
    end
  end

  describe "#due_today" do
    it "returns invoices due today" do
      due_today = create_invoice_with_due_date(Date.current)
      create_invoice_with_due_date(5.days.from_now)

      result = described_class.new(account.invoices).due_today

      expect(result).to include(due_today)
      expect(result.count).to eq(1)
    end
  end

  describe "#grouped_by_priority" do
    it "returns invoices grouped by priority" do
      create_invoice_with_due_date(70.days.ago)  # critical
      create_invoice_with_due_date(45.days.ago)  # high
      create_invoice_with_due_date(15.days.ago)  # medium
      create_invoice_with_due_date(5.days.from_now) # low

      result = described_class.new(account.invoices).grouped_by_priority

      expect(result[:critical].count).to eq(1)
      expect(result[:high].count).to eq(1)
      expect(result[:medium].count).to eq(1)
      expect(result[:low].count).to eq(1)
    end
  end

  describe "#stats" do
    before do
      create_invoice_with_due_date(15.days.ago)
      create_invoice_with_due_date(30.days.ago)
      create_invoice_with_due_date(5.days.from_now)
    end

    it "returns statistics" do
      stats = described_class.new(account.invoices).stats

      expect(stats[:total_overdue]).to eq(2)
      expect(stats[:due_this_week]).to be >= 0
      expect(stats[:average_days_overdue]).to be > 0
    end
  end
end
