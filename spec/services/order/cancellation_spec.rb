# frozen_string_literal: true

# Order::Cancellation Service Spec
# ================================
# Tests for the order cancellation service.
#
# Covers:
# - Initialization (order)
# - Successful cancellation:
#   - Updates order status to cancelled
#   - Creates audit event (order.cancelled)
#   - Creates resource for event tracking
# - Edge cases:
#   - Validated order cancellation
#   - Pending order cancellation
#   - Already cancelled order (returns false)
#   - Update failure handling
# - Transaction behavior (rollback on failure)
#

require "rails_helper"

RSpec.describe Order::Cancellation, type: :service do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  describe "#initialize" do
    let(:order) { create(:order, account: account, customer: customer) }

    it "accepts order as keyword argument" do
      service = described_class.new(order: order)
      expect(service.instance_variable_get(:@order)).to eq(order)
    end
  end

  describe "#call" do
    subject(:service) { described_class.new(order: order) }

    context "with validated order" do
      let(:order) { create(:order, :validated, account: account, customer: customer) }

      it "updates order status to cancelled" do
        service.call
        expect(order.reload.status).to eq("cancelled")
      end

      it "returns true" do
        expect(service.call).to be true
      end

      it "creates an account event" do
        # One for order.cancelled, one for order.status.changed (from Trackable)
        expect { service.call }.to change(AccountEvent, :count).by(2)
      end

      it "creates account event with correct type" do
        service.call
        event = AccountEvent.last
        expect(event.event_type).to eq("order.cancelled")
        expect(event.account).to eq(account)
      end

      it "creates a resource for the order" do
        expect { service.call }.to change(Resource, :count).by(1)
      end

      it "creates resource with correct attributes" do
        service.call
        resource = Resource.last
        expect(resource.name).to eq("Order##{order.id}")
        expect(resource.resource_type).to eq("Order")
      end
    end

    context "with pending order" do
      let(:order) { create(:order, :pending, account: account, customer: customer) }

      it "updates order status to cancelled" do
        service.call
        expect(order.reload.status).to eq("cancelled")
      end

      it "returns true" do
        expect(service.call).to be true
      end
    end

    context "with already cancelled order" do
      let(:order) { create(:order, :cancelled, account: account, customer: customer) }

      it "returns false" do
        expect(service.call).to be false
      end

      it "does not create account event" do
        expect { service.call }.not_to change(AccountEvent, :count)
      end
    end

    context "when update fails" do
      let(:order) { create(:order, :validated, account: account, customer: customer) }

      before do
        allow(order).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "does not change order status" do
        service.call
        expect(order.reload.status).to eq("validated")
      end
    end

    context "transaction behavior" do
      let(:order) { create(:order, :validated, account: account, customer: customer) }

      it "wraps operations in a transaction" do
        allow(AccountEvent).to receive(:log).and_raise(ActiveRecord::RecordInvalid)

        expect { service.call }.not_to change { order.reload.status }
      end
    end
  end
end
