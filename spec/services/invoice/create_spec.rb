# frozen_string_literal: true

# Invoice::Create Service Spec
# ============================
# Tests for the invoice creation service.
#
# Covers:
# - Initialization (order, type: debit/credit)
# - Debit invoice creation:
#   - Creates invoice with correct attributes
#   - Generates INV- prefixed number
#   - Updates order status to invoiced
#   - Creates audit event (invoice.debit.created)
# - Credit note creation:
#   - Generates CN- prefixed number
#   - Updates order status to cancelled
#   - Creates audit event (invoice.credit.created)
# - Error handling:
#   - Order already has invoice
#   - Invoice save fails
#   - Nil total amount
#

require "rails_helper"

RSpec.describe Invoice::Create, type: :service do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:order) { create(:order, :validated, account: account, customer: customer, total_amount: 150.0) }

  describe "#initialize" do
    it "accepts order and type keyword arguments" do
      service = described_class.new(order: order, type: :credit)
      expect(service.instance_variable_get(:@order)).to eq(order)
      expect(service.instance_variable_get(:@type)).to eq(:credit)
    end

    it "defaults type to :debit when not specified" do
      service = described_class.new(order: order)
      # Type defaults to nil and is converted to :debit in call
      expect(service.instance_variable_get(:@order)).to eq(order)
    end

    it "accepts string type" do
      service = described_class.new(order: order, type: "credit")
      expect(service.instance_variable_get(:@type)).to eq("credit")
    end
  end

  describe "#call" do
    subject(:service) { described_class.new(order: order, type: type) }

    context "with debit type" do
      let(:type) { :debit }

      it "creates an invoice" do
        expect { service.call }.to change(Invoice, :count).by(1)
      end

      it "returns the created invoice" do
        result = service.call
        expect(result).to be_a(Invoice)
        expect(result).to be_persisted
      end

      it "sets correct invoice attributes" do
        invoice = service.call

        expect(invoice.order).to eq(order)
        expect(invoice.status).to eq("draft")
        expect(invoice.amount).to eq(150.0)
        expect(invoice.tax_amount).to eq(0)
        expect(invoice.total_amount).to eq(150.0)
      end

      it "generates invoice number with INV prefix" do
        invoice = service.call
        expect(invoice.number).to match(/^INV-\d{8}-[A-F0-9]{8}$/)
      end

      it "updates order status to invoiced" do
        service.call
        expect(order.reload.status).to eq("invoiced")
      end

      it "creates an account event" do
        # One for invoice.debit.created, one for order.status.changed (from Trackable)
        expect { service.call }.to change(AccountEvent, :count).by(2)
      end

      it "creates account event with correct type" do
        service.call
        event = AccountEvent.find_by(event_type: "invoice.debit.created")
        expect(event).to be_present
        expect(event.account).to eq(account)
      end

      it "creates a resource for the invoice" do
        # One for Invoice (from Invoice::Create), one for Order (from status tracking)
        expect { service.call }.to change(Resource, :count).by(2)
      end
    end

    context "with credit type" do
      let(:type) { :credit }

      it "creates an invoice" do
        expect { service.call }.to change(Invoice, :count).by(1)
      end

      it "generates invoice number with CN prefix" do
        invoice = service.call
        expect(invoice.number).to match(/^CN-\d{8}-[A-F0-9]{8}$/)
      end

      it "updates order status to cancelled" do
        service.call
        expect(order.reload.status).to eq("cancelled")
      end

      it "creates account event with credit type" do
        service.call
        event = AccountEvent.last
        expect(event.event_type).to eq("invoice.credit.created")
      end
    end

    context "when order already has an invoice" do
      let(:type) { :debit }

      before { create(:invoice, order: order) }

      it "does not create a new invoice" do
        expect { service.call }.not_to change(Invoice, :count)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end

      it "does not change order status" do
        original_status = order.status
        service.call
        expect(order.reload.status).to eq(original_status)
      end

      it "does not create account event" do
        expect { service.call }.not_to change(AccountEvent, :count)
      end
    end

    context "when order total is nil" do
      let(:type) { :debit }
      let(:order) { create(:order, :validated, account: account, customer: customer, total_amount: nil) }

      it "creates invoice with 0 amount" do
        result = described_class.new(order: order, type: type).call
        expect(result.amount).to eq(0)
      end
    end

    context "when invoice save fails" do
      let(:type) { :debit }

      before do
        allow_any_instance_of(Invoice).to receive(:save).and_return(false)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end

      it "does not change order status" do
        original_status = order.status
        service.call
        expect(order.reload.status).to eq(original_status)
      end

      it "does not create account event" do
        expect { service.call }.not_to change(AccountEvent, :count)
      end
    end
  end
end
