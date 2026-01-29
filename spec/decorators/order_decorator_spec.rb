# frozen_string_literal: true

# OrderDecorator Spec
# ===================
# Tests for the OrderDecorator (presentation logic).
#
# Covers:
# - status_name: human-readable status names
# - status_badge: CSS class for status badges
# - customer_name: delegated customer display name
# - fulfillment_status: shipment status via fulfillment
# - fulfillment_service_name: carrier/service name
# - total_quantity: sum of line quantities
# - total_price / total_price_raw: formatted and raw amounts
# - lines_summary: "X items" pluralization
#

require "rails_helper"

RSpec.describe OrderDecorator do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, first_name: "Jean", last_name: "Dupont") }
  let(:order) { create(:order, account: account, customer: customer, status: "pending", total_amount: 150.0) }
  let(:decorated_order) { order.decorate }

  describe "#status_name" do
    it "returns English name for pending" do
      order.update!(status: "pending")
      expect(decorated_order.status_name).to eq("Pending")
    end

    it "returns English name for validated" do
      order.update!(status: "validated")
      expect(decorated_order.status_name).to eq("Validated")
    end

    it "returns English name for invoiced" do
      order.update!(status: "invoiced")
      expect(decorated_order.status_name).to eq("Invoiced")
    end

    it "returns English name for cancelled" do
      order.update!(status: "cancelled")
      expect(decorated_order.status_name).to eq("Cancelled")
    end
  end

  describe "#status_badge" do
    it "returns badge class for pending" do
      order.update!(status: "pending")
      expect(decorated_order.status_badge).to eq("badge-warning")
    end

    it "returns badge class for validated" do
      order.update!(status: "validated")
      expect(decorated_order.status_badge).to eq("badge-success")
    end
  end

  describe "#customer_name" do
    it "returns customer display name" do
      expect(decorated_order.customer_name).to eq("Jean Dupont")
    end

    it "returns nil when no customer" do
      allow(order).to receive(:customer).and_return(nil)
      expect(decorated_order.customer_name).to be_nil
    end
  end

  describe "#fulfillment_status" do
    it "returns fulfillment status name when present" do
      fulfillment_service = create(:fulfillment_service, account: account)
      fulfillment = create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
      order.update!(fulfillment: fulfillment)

      expect(decorated_order.fulfillment_status).to eq("Shipped")
    end

    it "returns nil when no fulfillment" do
      expect(decorated_order.fulfillment_status).to be_nil
    end
  end

  describe "#fulfillment_service_name" do
    it "returns fulfillment service name when present" do
      fulfillment_service = create(:fulfillment_service, account: account, name: "DHL Express")
      fulfillment = create(:fulfillment, fulfillment_service: fulfillment_service)
      order.update!(fulfillment: fulfillment)

      expect(decorated_order.fulfillment_service_name).to eq("DHL Express")
    end

    it "returns nil when no fulfillment" do
      expect(decorated_order.fulfillment_service_name).to be_nil
    end
  end

  describe "#total_quantity" do
    it "returns sum of quantities from order lines" do
      create(:order_line, order: order, quantity: 3)
      create(:order_line, order: order, quantity: 5)
      expect(decorated_order.total_quantity).to eq(8)
    end

    it "returns 0 when no lines" do
      expect(decorated_order.total_quantity).to eq(0)
    end
  end

  describe "#total_price" do
    it "returns formatted total_amount" do
      expect(decorated_order.total_price).to include("150")
    end
  end

  describe "#total_price_raw" do
    it "returns total_amount" do
      expect(decorated_order.total_price_raw).to eq(150.0)
    end

    it "returns 0 when total_amount is nil" do
      order.update!(total_amount: nil)
      expect(decorated_order.total_price_raw).to eq(0)
    end
  end

  describe "#lines_summary" do
    it "returns singular for 1 line" do
      create(:order_line, order: order)
      expect(decorated_order.lines_summary).to eq("1 item")
    end

    it "returns plural for multiple lines" do
      create_list(:order_line, 3, order: order)
      expect(decorated_order.lines_summary).to eq("3 items")
    end
  end
end
