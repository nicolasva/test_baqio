# frozen_string_literal: true

# Order Workflow Integration Spec
# ===============================
# End-to-end tests for the complete order lifecycle.
#
# Covers:
# - Complete order lifecycle:
#   1. Create order with lines → 2. Validate → 3. Invoice
#   4. Send invoice → 5. Ship → 6. Deliver → 7. Mark paid
# - Order cancellation scenarios:
#   - Pending order direct cancellation
#   - Validated order (creates event)
#   - Invoiced order (creates credit note)
# - Customer statistics (total_spent, orders_count)
# - Account revenue calculation
# - Fulfillment tracking (transit_duration, status filters)
# - Invoice payment tracking (overdue, due_soon)
#

require "rails_helper"

RSpec.describe "Order Workflow Integration", type: :model do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:fulfillment_service) { create(:fulfillment_service, :colissimo, account: account) }

  describe "complete order lifecycle" do
    it "processes an order from creation to delivery" do
      # 1. Create order with lines
      order = create(:order, :pending, account: account, customer: customer)
      create(:order_line, order: order, name: "T-shirt", quantity: 2, unit_price: 25.0)
      create(:order_line, order: order, name: "Jean", quantity: 1, unit_price: 50.0)
      order.update_total!

      expect(order.status).to eq("pending")
      expect(order.total_amount).to eq(100.0)
      expect(order.order_lines.count).to eq(2)

      # 2. Validate order
      order.validate!
      expect(order.status).to eq("validated")

      # 3. Invoice order
      order.invoice!
      expect(order.status).to eq("invoiced")
      expect(order.invoice).to be_present
      expect(order.invoice.status).to eq("draft")

      # 4. Send invoice
      order.invoice.send_to_customer!
      expect(order.invoice.status).to eq("sent")
      expect(order.invoice.due_at).to eq(Date.current + 30.days)

      # 5. Create and ship fulfillment
      fulfillment = create(:fulfillment, :pending, fulfillment_service: fulfillment_service)
      order.update!(fulfillment: fulfillment)
      fulfillment.ship!(tracking_number: "COL123456789", carrier: "Colissimo")
      expect(fulfillment.status).to eq("shipped")
      expect(fulfillment.tracking_number).to eq("COL123456789")

      # 6. Deliver fulfillment
      fulfillment.deliver!
      expect(fulfillment.status).to eq("delivered")
      expect(fulfillment.delivered_at).to be_present

      # 7. Mark invoice as paid
      order.invoice.mark_as_paid!
      expect(order.invoice.status).to eq("paid")
      expect(order.invoice.paid_at).to eq(Date.current)

      # 8. Verify final state
      order.reload
      expect(order.status).to eq("invoiced")
      expect(order.invoice.status).to eq("paid")
      expect(order.fulfillment.status).to eq("delivered")
    end
  end

  describe "order cancellation scenarios" do
    context "when order is pending" do
      it "cancels the order directly" do
        order = create(:order, :pending, account: account, customer: customer)

        expect(order.cancel!).to be true
        expect(order.status).to eq("cancelled")
      end
    end

    context "when order is validated" do
      it "cancels the order and creates an event" do
        order = create(:order, :validated, account: account, customer: customer)

        # One for order.cancelled, one for order.status.changed (from Trackable)
        expect { order.cancel! }.to change { AccountEvent.count }.by(2)
        expect(order.status).to eq("cancelled")
        expect(AccountEvent.find_by(event_type: "order.cancelled")).to be_present
      end
    end

    context "when order is invoiced" do
      it "creates a credit note and cancels the order" do
        order = create(:order, :invoiced, account: account, customer: customer, total_amount: 100.0)
        create(:invoice, :sent, order: order, amount: 100.0)

        expect { order.cancel! }.to change { Invoice.count }.by(1)
        expect(order.status).to eq("cancelled")

        credit_note = Invoice.last
        expect(credit_note.number).to start_with("CN-")
      end
    end
  end

  describe "customer statistics" do
    it "calculates total spent correctly" do
      # Create multiple orders with paid invoices
      3.times do |i|
        order = create(:order, :validated, account: account, customer: customer, total_amount: (i + 1) * 100.0)
        create(:invoice, :paid, order: order, amount: (i + 1) * 100.0, tax_amount: 0)
      end

      # 100 + 200 + 300 = 600
      expect(customer.total_spent).to eq(600.0)
    end

    it "does not count unpaid invoices in total spent" do
      paid_order = create(:order, :validated, account: account, customer: customer, total_amount: 100.0)
      create(:invoice, :paid, order: paid_order, amount: 100.0, tax_amount: 0)

      unpaid_order = create(:order, :validated, account: account, customer: customer, total_amount: 200.0)
      create(:invoice, :sent, order: unpaid_order, amount: 200.0, tax_amount: 0)

      expect(customer.total_spent).to eq(100.0)
    end

    it "counts all orders for customer" do
      create_list(:order, 5, account: account, customer: customer)
      expect(customer.orders_count).to eq(5)
    end
  end

  describe "account revenue calculation" do
    it "calculates total revenue from paid invoices" do
      customer1 = create(:customer, account: account)
      customer2 = create(:customer, account: account)

      [customer1, customer2].each do |c|
        order = create(:order, :validated, account: account, customer: c, total_amount: 250.0)
        create(:invoice, :paid, order: order, amount: 250.0, tax_amount: 0)
      end

      expect(account.total_revenue).to eq(500.0)
    end

    it "excludes cancelled orders from active count" do
      create(:order, :pending, account: account, customer: customer)
      create(:order, :validated, account: account, customer: customer)
      create(:order, :cancelled, account: account, customer: customer)

      expect(account.active_orders.count).to eq(2)
    end
  end

  describe "fulfillment tracking" do
    it "calculates transit duration correctly" do
      fulfillment = create(:fulfillment, :pending, fulfillment_service: fulfillment_service)

      # Ship 5 days ago
      fulfillment.update!(status: "shipped", shipped_at: 5.days.ago, tracking_number: "TEST123")

      # Deliver today
      fulfillment.update!(status: "delivered", delivered_at: Time.current)

      expect(fulfillment.transit_duration).to eq(5)
    end

    it "filters fulfillments by status" do
      create(:fulfillment, :pending, fulfillment_service: fulfillment_service)
      create(:fulfillment, :processing, fulfillment_service: fulfillment_service)
      create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
      create(:fulfillment, :delivered, fulfillment_service: fulfillment_service)

      expect(Fulfillment.in_transit.count).to eq(2)
      expect(Fulfillment.completed.count).to eq(1)
      expect(Fulfillment.active.count).to eq(3)
    end
  end

  describe "invoice payment tracking" do
    it "identifies overdue invoices" do
      order = create(:order, :validated, account: account, customer: customer)
      invoice = create(:invoice, :sent, order: order, issued_at: 45.days.ago, due_at: 15.days.ago)

      expect(invoice.overdue?).to be true
      expect(invoice.days_overdue).to eq(15)
    end

    it "identifies invoices due soon" do
      order = create(:order, :validated, account: account, customer: customer)
      invoice = create(:invoice, :sent, order: order, issued_at: 25.days.ago, due_at: 5.days.from_now)

      expect(invoice.overdue?).to be false
      expect(invoice.days_until_due).to eq(5)
    end

    it "filters overdue and due soon invoices" do
      # Create various invoices
      order1 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :overdue, order: order1)

      order2 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :due_soon, order: order2)

      order3 = create(:order, :validated, account: account, customer: customer)
      create(:invoice, :paid, order: order3)

      expect(Invoice.overdue.count).to eq(1)
      expect(Invoice.due_soon.count).to eq(1)
    end
  end
end
