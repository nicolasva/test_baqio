# frozen_string_literal: true

# InvoiceDecorator Spec
# =====================
# Tests for the InvoiceDecorator (presentation logic).
#
# Covers:
# - status_name: human-readable status names
# - status_badge: CSS class for status badges
# - amount_formatted / tax_amount_formatted / total_amount_formatted
# - customer_name: delegated via order
# - order_reference: delegated reference number
# - due_status: overdue/due soon messaging
#

require "rails_helper"

RSpec.describe InvoiceDecorator do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:order) { create(:order, account: account, customer: customer) }
  let(:invoice) { create(:invoice, order: order, status: "draft", amount: 100.0, tax_amount: 20.0) }
  let(:decorated_invoice) { invoice.decorate }

  describe "#status_name" do
    it "returns English name for draft" do
      expect(decorated_invoice.status_name).to eq("Draft")
    end

    it "returns English name for sent" do
      invoice.update!(status: "sent", issued_at: Date.current, due_at: Date.current + 30.days)
      expect(decorated_invoice.status_name).to eq("Sent")
    end

    it "returns English name for paid" do
      invoice.update!(status: "paid", issued_at: Date.current, due_at: Date.current + 30.days, paid_at: Date.current)
      expect(decorated_invoice.status_name).to eq("Paid")
    end

    it "returns English name for cancelled" do
      invoice.update!(status: "cancelled")
      expect(decorated_invoice.status_name).to eq("Cancelled")
    end
  end

  describe "#status_badge" do
    it "returns badge class for draft" do
      expect(decorated_invoice.status_badge).to eq("badge-secondary")
    end

    it "returns badge class for sent" do
      invoice.update!(status: "sent", issued_at: Date.current, due_at: Date.current + 30.days)
      expect(decorated_invoice.status_badge).to eq("badge-info")
    end

    it "returns badge class for paid" do
      invoice.update!(status: "paid", issued_at: Date.current, due_at: Date.current + 30.days, paid_at: Date.current)
      expect(decorated_invoice.status_badge).to eq("badge-success")
    end
  end

  describe "#amount_formatted" do
    it "returns formatted amount" do
      expect(decorated_invoice.amount_formatted).to include("100")
    end
  end

  describe "#tax_amount_formatted" do
    it "returns formatted tax amount" do
      expect(decorated_invoice.tax_amount_formatted).to include("20")
    end

    it "returns 0 when tax is nil" do
      invoice.update!(tax_amount: nil)
      expect(decorated_invoice.tax_amount_formatted).to include("0")
    end
  end

  describe "#total_amount_formatted" do
    it "returns formatted total amount" do
      expect(decorated_invoice.total_amount_formatted).to include("120")
    end
  end

  describe "#customer_name" do
    it "returns customer display name through order" do
      expect(decorated_invoice.customer_name).to eq(customer.decorate.display_name)
    end
  end

  describe "#order_reference" do
    it "returns order reference" do
      expect(decorated_invoice.order_reference).to eq(order.reference)
    end
  end

  describe "#due_status" do
    context "when draft" do
      it "returns nil" do
        expect(decorated_invoice.due_status).to be_nil
      end
    end

    context "when sent and overdue" do
      it "returns overdue message" do
        invoice.update!(status: "sent", issued_at: 45.days.ago, due_at: 15.days.ago)
        expect(decorated_invoice.due_status.to_s).to include("Overdue")
      end
    end

    context "when sent and due soon" do
      it "returns due soon message" do
        invoice.update!(status: "sent", issued_at: 25.days.ago, due_at: 5.days.from_now)
        expect(decorated_invoice.due_status.to_s).to include("Due soon")
      end
    end
  end
end
