# frozen_string_literal: true

# Order Model Spec
# ================
# Tests for the Order model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Status values (pending, validated, invoiced, cancelled)
# - Validations (reference uniqueness, status required)
# - Associations (account, customer, fulfillment, order_lines, invoice)
# - Scopes (recent, active, with_invoice, without_invoice, by status)
# - Callbacks (reference generation)
# - State transitions (cancel!, validate!, invoice!)
# - Instance methods (calculate_total, update_total!, add_line, empty?, lines_count)
#

require "rails_helper"

RSpec.describe Order, type: :model do
  describe "Test data creation" do
    it "can create a valid order for testing" do
      order = build(:order)
      expect(order).to be_valid
    end

    it "can create an order with product lines" do
      order = create(:order, :with_lines)
      expect(order.order_lines.count).to eq(3)
    end

    it "can create an order that is already validated" do
      order = build(:order, :validated)
      expect(order.status).to eq("validated")
    end
  end

  describe "Allowed status values" do
    it "only allows: pending, invoiced, validated, or cancelled" do
      expect(Order::STATUSES).to eq(%w[pending invoiced validated cancelled])
    end
  end

  describe "Data validation rules" do
    describe "Order reference number" do
      it "automatically generates a reference when none is provided" do
        order = build(:order, reference: nil)
        order.valid?
        expect(order.reference).to be_present
      end

      it "requires a reference number" do
        order = build(:order)
        order.reference = nil
        # Skip callbacks to test validation directly
        order.define_singleton_method(:generate_reference) { }
        expect(order).not_to be_valid
        expect(order.errors[:reference]).to include("can't be blank")
      end

      it "prevents duplicate references in the same account" do
        account = create(:account)
        customer = create(:customer, account: account)
        create(:order, account: account, customer: customer, reference: "ORD-001")
        duplicate = build(:order, account: account, customer: customer, reference: "ORD-001")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:reference]).to include("has already been taken")
      end

      it "allows the same reference in different accounts" do
        account1 = create(:account)
        account2 = create(:account)
        customer1 = create(:customer, account: account1)
        customer2 = create(:customer, account: account2)
        create(:order, account: account1, customer: customer1, reference: "ORD-001")
        order2 = build(:order, account: account2, customer: customer2, reference: "ORD-001")

        expect(order2).to be_valid
      end
    end

    describe "Order status" do
      it "requires a status to be set" do
        order = build(:order, status: nil)
        expect(order).not_to be_valid
        expect(order.errors[:status]).to include("can't be blank")
      end

      it "only accepts valid status values" do
        order = build(:order, status: "invalid")
        expect(order).not_to be_valid
        expect(order.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe "Relationships with other data" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }
    let(:order) { create(:order, account: account, customer: customer) }

    it "is linked to an account" do
      expect(order.account).to eq(account)
    end

    it "is linked to a customer" do
      expect(order.customer).to eq(customer)
    end

    describe "Shipment (fulfillment)" do
      it "can exist without a shipment" do
        order_without = create(:order, account: account, customer: customer, fulfillment: nil)
        expect(order_without).to be_valid
        expect(order_without.fulfillment).to be_nil
      end

      it "can be linked to a shipment" do
        fulfillment_service = create(:fulfillment_service, account: account)
        fulfillment = create(:fulfillment, fulfillment_service: fulfillment_service)
        order_with = create(:order, account: account, customer: customer, fulfillment: fulfillment)

        expect(order_with.fulfillment).to eq(fulfillment)
      end
    end

    describe "Product lines" do
      it "can have multiple product lines" do
        line = create(:order_line, order: order)
        expect(order.order_lines).to include(line)
      end

      it "deletes product lines when the order is deleted" do
        create(:order_line, order: order)
        expect { order.destroy }.to change(OrderLine, :count).by(-1)
      end
    end

    describe "Invoice" do
      it "can have one invoice" do
        invoice = create(:invoice, order: order)
        expect(order.invoice).to eq(invoice)
      end

      it "deletes the invoice when the order is deleted" do
        create(:invoice, order: order)
        expect { order.destroy }.to change(Invoice, :count).by(-1)
      end
    end
  end

  describe "Quick filters for searching orders" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }

    describe "Recent orders filter" do
      it "returns orders from newest to oldest" do
        old_order = create(:order, account: account, customer: customer, created_at: 2.days.ago)
        new_order = create(:order, account: account, customer: customer, created_at: 1.hour.ago)

        expect(Order.recent.first).to eq(new_order)
        expect(Order.recent.last).to eq(old_order)
      end
    end

    describe "Active orders filter" do
      it "excludes cancelled orders from results" do
        active = create(:order, :pending, account: account, customer: customer)
        cancelled = create(:order, :cancelled, account: account, customer: customer)

        expect(Order.active).to include(active)
        expect(Order.active).not_to include(cancelled)
      end
    end

    describe "Orders with invoice filter" do
      it "returns only orders that have been invoiced" do
        with_invoice = create(:order, account: account, customer: customer)
        without_invoice = create(:order, account: account, customer: customer)
        create(:invoice, order: with_invoice)

        expect(Order.with_invoice).to include(with_invoice)
        expect(Order.with_invoice).not_to include(without_invoice)
      end
    end

    describe "Orders without invoice filter" do
      it "returns only orders that have no invoice yet" do
        with_invoice = create(:order, account: account, customer: customer)
        without_invoice = create(:order, account: account, customer: customer)
        create(:invoice, order: with_invoice)

        expect(Order.without_invoice).to include(without_invoice)
        expect(Order.without_invoice).not_to include(with_invoice)
      end
    end

    describe "Filter by status" do
      it "provides a filter for each order status" do
        Order::STATUSES.each do |status|
          expect(Order).to respond_to(status)
        end
      end
    end
  end

  describe "Automatic actions when saving" do
    describe "Reference number generation" do
      it "auto-generates a unique reference on creation" do
        account = create(:account)
        customer = create(:customer, account: account)
        order = build(:order, account: account, customer: customer, reference: nil)
        order.valid?

        expect(order.reference).to be_present
        expect(order.reference).to match(/^ORD-\d{8}-[A-F0-9]{8}$/)
      end

      it "keeps the provided reference if one is given" do
        account = create(:account)
        customer = create(:customer, account: account)
        order = build(:order, account: account, customer: customer, reference: "CUSTOM-REF")
        order.valid?

        expect(order.reference).to eq("CUSTOM-REF")
      end
    end
  end

  describe "Available actions on an order" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }

    describe "Cancelling an order" do
      context "when the order is already cancelled" do
        let(:order) { create(:order, :cancelled, account: account, customer: customer) }

        it "returns false (no action needed)" do
          expect(order.cancel!).to be false
        end
      end

      context "when the order is pending" do
        let(:order) { create(:order, :pending, account: account, customer: customer) }

        it "changes the status to cancelled" do
          order.cancel!
          expect(order.reload.status).to eq("cancelled")
        end

        it "returns true to confirm success" do
          expect(order.cancel!).to be true
        end
      end

      context "when the order is validated" do
        let(:order) { create(:order, :validated, account: account, customer: customer) }

        it "uses a special cancellation process" do
          expect_any_instance_of(Order::Cancellation).to receive(:call).and_return(true)
          order.cancel!
        end
      end

      context "when the order has an invoice" do
        let(:order) { create(:order, :invoiced, account: account, customer: customer, total_amount: 100) }

        it "creates a credit note to reverse the invoice" do
          expect_any_instance_of(Invoice::Create).to receive(:call).and_return(double)
          order.cancel!
        end
      end
    end

    describe "Validating an order" do
      context "when the order is pending" do
        let(:order) { create(:order, :pending, account: account, customer: customer) }

        it "changes the status to validated" do
          order.validate!
          expect(order.reload.status).to eq("validated")
        end

        it "returns true to confirm success" do
          expect(order.validate!).to be_truthy
        end
      end

      context "when the order is not pending" do
        let(:order) { create(:order, :validated, account: account, customer: customer) }

        it "returns false (cannot validate again)" do
          expect(order.validate!).to be false
        end
      end
    end

    describe "Creating an invoice for an order" do
      context "when the order is validated and has no invoice" do
        let(:order) { create(:order, :validated, account: account, customer: customer, total_amount: 100) }

        it "creates a new invoice" do
          expect { order.invoice! }.to change(Invoice, :count).by(1)
        end

        it "returns a truthy value to confirm success" do
          expect(order.invoice!).to be_truthy
        end
      end

      context "when the order is not yet validated" do
        let(:order) { create(:order, :pending, account: account, customer: customer) }

        it "returns false (must validate first)" do
          expect(order.invoice!).to be false
        end
      end

      context "when the order already has an invoice" do
        let(:order) { create(:order, :validated, account: account, customer: customer) }

        before { create(:invoice, order: order) }

        it "returns false (cannot invoice twice)" do
          expect(order.invoice!).to be false
        end
      end
    end

    describe "Calculating the order total" do
      let(:order) { create(:order, account: account, customer: customer) }

      it "adds up the total price of all product lines" do
        create(:order_line, order: order, quantity: 2, unit_price: 10.0)
        create(:order_line, order: order, quantity: 1, unit_price: 15.0)

        expect(order.calculate_total).to eq(35.0)
      end

      it "returns 0 when the order has no products" do
        expect(order.calculate_total).to eq(0)
      end
    end

    describe "Updating the order total" do
      let(:order) { create(:order, account: account, customer: customer, total_amount: 0) }

      it "recalculates and saves the total from product lines" do
        create(:order_line, order: order, quantity: 2, unit_price: 10.0)
        order.update_total!

        expect(order.reload.total_amount).to eq(20.0)
      end
    end

    describe "Adding a product to an order" do
      let(:order) { create(:order, account: account, customer: customer) }

      it "creates a new product line" do
        expect {
          order.add_line(name: "Product", quantity: 2, unit_price: 10.0)
        }.to change(OrderLine, :count).by(1)
      end

      it "returns the newly created product line" do
        line = order.add_line(name: "Product", quantity: 2, unit_price: 10.0)
        expect(line).to be_a(OrderLine)
        expect(line.name).to eq("Product")
      end

      it "can include a SKU (product code)" do
        line = order.add_line(name: "Product", quantity: 1, unit_price: 10.0, sku: "SKU-001")
        expect(line.sku).to eq("SKU-001")
      end
    end

    describe "Checking if order is empty" do
      let(:order) { create(:order, account: account, customer: customer) }

      it "returns true when there are no products" do
        expect(order.empty?).to be true
      end

      it "returns false when there are products" do
        create(:order_line, order: order)
        expect(order.empty?).to be false
      end
    end

    describe "Counting products in an order" do
      let(:order) { create(:order, account: account, customer: customer) }

      it "returns the number of product lines" do
        create_list(:order_line, 3, order: order)
        expect(order.lines_count).to eq(3)
      end
    end
  end
end
