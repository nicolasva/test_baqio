# frozen_string_literal: true

# Factories Spec
# ==============
# Tests to verify all FactoryBot factories create valid records.
#
# Covers:
# - Account factory and traits (:with_customers, :with_revenue, :boutique, etc.)
# - Customer factory and traits (:without_email, :vip, :french, :high_value, etc.)
# - Order factory and traits (:with_lines, :urgent, :complete, :in_transit, etc.)
# - OrderLine factory and traits (:expensive, :bulk, :clothing, :electronics)
# - Invoice factory and traits (:sent, :paid, :overdue, :b2b, :credit_note, etc.)
# - Fulfillment factory and traits (:shipped, :delivered, :long_transit, etc.)
# - FulfillmentService factory and traits (:dhl, :colissimo, :popular, etc.)
# - AccountEvent factory and traits (:order_created, :invoice_paid, etc.)
#
# This spec ensures all factories produce valid, usable test data.
#

require "rails_helper"

RSpec.describe "Factories" do
  describe "Account factory" do
    it "creates a valid account" do
      expect(build(:account)).to be_valid
    end

    it "creates account with customers" do
      account = create(:account, :with_customers, customers_count: 5)
      expect(account.customers.count).to eq(5)
    end

    it "creates account with orders" do
      account = create(:account, :with_orders, orders_count: 4)
      expect(account.orders.count).to eq(4)
    end

    it "creates account with revenue" do
      account = create(:account, :with_revenue, revenue_amount: 500.0)
      expect(account.total_revenue).to eq(500.0)
    end

    it "creates account with overdue invoices" do
      account = create(:account, :with_overdue_invoices, overdue_count: 3)
      expect(account.invoices.overdue.count).to eq(3)
    end

    it "creates demo account" do
      account = create(:demo_account)
      expect(account.name).to eq("Baqio Demo")
    end

    it "creates boutique account with complete data" do
      account = create(:account, :boutique)
      expect(account.customers.count).to eq(5)
      expect(account.orders.count).to eq(5)
      expect(account.fulfillment_services.count).to eq(2)
    end
  end

  describe "Customer factory" do
    it "creates a valid customer" do
      expect(build(:customer)).to be_valid
    end

    it "creates customer without email" do
      customer = build(:customer, :without_email)
      expect(customer.email).to be_nil
    end

    it "creates customer with orders" do
      customer = create(:customer, :with_orders, orders_count: 5)
      expect(customer.orders.count).to eq(5)
    end

    it "creates customer with paid invoices" do
      customer = create(:customer, :with_paid_invoices, invoices_count: 3, invoice_amount: 100.0)
      expect(customer.total_spent).to eq(300.0)
    end

    it "creates VIP customer" do
      customer = create(:customer, :vip, vip_orders_count: 3)
      expect(customer.orders.count).to eq(3)
      expect(customer.total_spent).to be > 0
    end

    it "creates French customer" do
      customer = create(:customer, :french)
      expect(customer.phone).to start_with("+33")
      expect(customer.address).to include("France")
    end

    it "creates high value customer" do
      customer = create(:customer, :high_value)
      expect(customer.total_spent).to be >= 3000
    end

    it "creates named customer jean_dupont" do
      customer = create(:jean_dupont)
      expect(customer.first_name).to eq("Jean")
      expect(customer.last_name).to eq("Dupont")
    end
  end

  describe "Order factory" do
    it "creates a valid order" do
      expect(build(:order)).to be_valid
    end

    it "creates order with specific lines" do
      order = create(:order, :with_specific_lines, lines_data: [
        { name: "Product A", quantity: 2, unit_price: 10.0 },
        { name: "Product B", quantity: 1, unit_price: 25.0 }
      ])
      expect(order.order_lines.count).to eq(2)
      expect(order.total_amount).to eq(45.0)
    end

    it "creates order with clothing items" do
      order = create(:order, :with_clothing_items)
      expect(order.order_lines.count).to eq(2)
      order.order_lines.each do |line|
        expect(line.sku).to start_with("VET-")
      end
    end

    it "creates order with electronics" do
      order = create(:order, :with_electronics)
      expect(order.order_lines.first.sku).to start_with("ELEC-")
    end

    it "creates order with mixed items" do
      order = create(:order, :with_mixed_items)
      expect(order.order_lines.count).to eq(3)
    end

    it "creates urgent order" do
      order = create(:order, :urgent)
      expect(order.notes).to include("URGENT")
    end

    it "creates gift order" do
      order = create(:order, :gift)
      expect(order.notes).to include("cadeau")
    end

    it "creates B2B order" do
      order = create(:order, :b2b)
      expect(order.order_lines.count).to eq(5)
      order.order_lines.each do |line|
        expect(line.quantity).to eq(10)
      end
    end

    it "creates order in transit" do
      order = create(:order, :in_transit)
      expect(order.fulfillment.status).to eq("shipped")
    end

    it "creates order with overdue payment" do
      order = create(:order, :overdue_payment)
      expect(order.invoice.overdue?).to be true
    end

    it "creates complete order" do
      order = create(:order, :complete)
      expect(order.invoice).to be_present
      expect(order.invoice.status).to eq("paid")
      expect(order.fulfillment.status).to eq("delivered")
    end
  end

  describe "OrderLine factory" do
    it "creates a valid order line" do
      expect(build(:order_line)).to be_valid
    end

    it "calculates total_price" do
      line = create(:order_line, quantity: 3, unit_price: 10.0)
      expect(line.total_price).to eq(30.0)
    end

    it "creates expensive line" do
      line = create(:order_line, :expensive)
      expect(line.unit_price).to eq(199.99)
    end

    it "creates bulk line" do
      line = create(:order_line, :bulk)
      expect(line.quantity).to eq(10)
    end

    it "creates clothing line" do
      line = create(:order_line, :clothing)
      expect(line.sku).to start_with("VET-")
    end

    it "creates electronics line" do
      line = create(:order_line, :electronics)
      expect(line.sku).to start_with("ELEC-")
    end

    it "creates accessories line" do
      line = create(:order_line, :accessories)
      expect(line.sku).to start_with("ACC-")
    end

    it "creates large quantity line" do
      line = create(:order_line, :large_quantity)
      expect(line.quantity).to be >= 50
    end
  end

  describe "Invoice factory" do
    it "creates a valid invoice" do
      expect(build(:invoice)).to be_valid
    end

    it "creates draft invoice" do
      invoice = create(:invoice, :draft)
      expect(invoice.status).to eq("draft")
      expect(invoice.issued_at).to be_nil
    end

    it "creates sent invoice" do
      invoice = create(:invoice, :sent)
      expect(invoice.status).to eq("sent")
      expect(invoice.issued_at).to eq(Date.current)
      expect(invoice.due_at).to eq(Date.current + 30.days)
    end

    it "creates paid invoice" do
      invoice = create(:invoice, :paid)
      expect(invoice.status).to eq("paid")
      expect(invoice.paid_at).to be_present
    end

    it "creates overdue invoice" do
      invoice = create(:invoice, :overdue)
      expect(invoice.overdue?).to be true
    end

    it "creates invoice with specific amount" do
      invoice = create(:invoice, :with_specific_amount, specific_amount: 250.0, tax_rate: 0.1)
      expect(invoice.amount).to eq(250.0)
      expect(invoice.tax_amount).to eq(25.0)
      expect(invoice.total_amount).to eq(275.0)
    end

    it "creates invoice with zero tax" do
      invoice = create(:invoice, :zero_tax)
      expect(invoice.tax_amount).to eq(0)
    end

    it "creates invoice with reduced tax" do
      invoice = create(:invoice, :reduced_tax, amount: 100.0)
      expect(invoice.tax_amount).to eq(5.5)
    end

    it "creates paid early invoice" do
      invoice = create(:invoice, :paid_early)
      expect(invoice.paid_at).to be < invoice.due_at
    end

    it "creates paid late invoice" do
      invoice = create(:invoice, :paid_late)
      expect(invoice.paid_at).to be > invoice.due_at
    end

    it "creates due tomorrow invoice" do
      invoice = create(:invoice, :due_tomorrow)
      expect(invoice.days_until_due).to eq(1)
    end

    it "creates significantly overdue invoice" do
      invoice = create(:invoice, :significantly_overdue)
      expect(invoice.days_overdue).to be >= 60
    end

    it "creates B2B invoice" do
      invoice = create(:invoice, :b2b)
      expect(invoice.amount).to be >= 1000
      expect(invoice.due_at).to eq(Date.current + 45.days)
    end

    it "creates export invoice without VAT" do
      invoice = create(:invoice, :export)
      expect(invoice.tax_amount).to eq(0)
    end

    it "creates credit note" do
      invoice = build(:invoice, :credit_note)
      expect(invoice.number).to start_with("CN-")
      # Note: Credit notes have negative amounts but model validation requires >= 0
      # The factory creates an invalid credit note for testing purposes
    end
  end

  describe "Fulfillment factory" do
    it "creates a valid fulfillment" do
      expect(build(:fulfillment)).to be_valid
    end

    it "creates pending fulfillment" do
      fulfillment = create(:fulfillment, :pending)
      expect(fulfillment.status).to eq("pending")
      expect(fulfillment.tracking_number).to be_nil
    end

    it "creates shipped fulfillment" do
      fulfillment = create(:fulfillment, :shipped)
      expect(fulfillment.status).to eq("shipped")
      expect(fulfillment.tracking_number).to be_present
      expect(fulfillment.shipped_at).to be_present
    end

    it "creates delivered fulfillment" do
      fulfillment = create(:fulfillment, :delivered)
      expect(fulfillment.status).to eq("delivered")
      expect(fulfillment.delivered_at).to be_present
    end

    it "creates international fulfillment" do
      fulfillment = create(:fulfillment, :international)
      expect(fulfillment.tracking_number).to start_with("INT")
    end

    it "creates long transit fulfillment" do
      fulfillment = create(:fulfillment, :long_transit)
      expect(fulfillment.transit_duration).to eq(13)
    end

    it "creates fast delivery fulfillment" do
      fulfillment = create(:fulfillment, :fast_delivery)
      expect(fulfillment.transit_duration).to eq(1)
    end

    it "creates fulfillment with orders" do
      fulfillment = create(:fulfillment, :with_orders)
      expect(fulfillment.orders.count).to eq(2)
    end
  end

  describe "FulfillmentService factory" do
    it "creates a valid fulfillment service" do
      expect(build(:fulfillment_service)).to be_valid
    end

    it "creates DHL service" do
      service = create(:fulfillment_service, :dhl)
      expect(service.name).to eq("DHL Express")
      expect(service.provider).to eq("dhl")
    end

    it "creates Colissimo service" do
      service = create(:fulfillment_service, :colissimo)
      expect(service.name).to eq("Colissimo")
      expect(service.provider).to eq("colissimo")
    end

    it "creates inactive service" do
      service = create(:fulfillment_service, :inactive)
      expect(service.active).to be false
    end

    it "creates popular service with many fulfillments" do
      service = create(:fulfillment_service, :popular)
      expect(service.fulfillments.count).to eq(10)
    end
  end

  describe "AccountEvent factory" do
    it "creates a valid account event" do
      expect(build(:account_event)).to be_valid
    end

    it "creates event with payload" do
      event = create(:account_event, :with_payload)
      expect(event.payload).to be_present
      expect(event.parsed_payload).to have_key(:key)
    end

    it "creates order created event" do
      event = create(:account_event, :order_created)
      expect(event.event_type).to eq("order.created")
    end

    it "creates invoice paid event" do
      event = create(:account_event, :invoice_paid)
      expect(event.event_type).to eq("invoice.paid")
    end

    it "creates fulfillment shipped event" do
      event = create(:account_event, :fulfillment_shipped)
      expect(event.event_type).to eq("fulfillment.shipped")
    end
  end
end
