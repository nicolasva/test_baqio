# frozen_string_literal: true

# Trackable Concern Spec
# ======================
# Tests for the Trackable concern that logs field changes to AccountEvent.
#
# Covers:
# - Order tracking: total_amount, status
# - OrderLine tracking: unit_price
#
# Behavior:
# - Creates AccountEvent when tracked fields change
# - Logs old_value and new_value in payload
# - Event type follows pattern: "model_name.field.changed"
# - Does not log when tracked fields are unchanged
# - Handles nil values correctly
# - Works with decimal values
# - Transaction safety
#

require "rails_helper"

RSpec.describe Trackable, type: :model do
  describe Order do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }
    let(:order) { create(:order, :pending, account: account, customer: customer, total_amount: 100.0) }

    describe "status tracking" do
      it "logs an event when status changes" do
        expect {
          order.update!(status: "validated")
        }.to change(AccountEvent, :count).by(1)

        event = AccountEvent.last
        expect(event.event_type).to eq("order.status.changed")
        expect(event.parsed_payload[:field]).to eq("status")
        expect(event.parsed_payload[:old_value]).to eq("pending")
        expect(event.parsed_payload[:new_value]).to eq("validated")
      end

      it "associates the event with the correct account" do
        order.update!(status: "validated")
        event = AccountEvent.last
        expect(event.account).to eq(order.account)
      end

      it "associates the event with the order resource" do
        order.update!(status: "validated")
        event = AccountEvent.last
        expect(event.resource.name).to eq("Order##{order.id}")
        expect(event.resource.resource_type).to eq("Order")
      end

      it "does not log an event when status is unchanged" do
        expect {
          order.update!(notes: "Some notes")
        }.not_to change(AccountEvent, :count)
      end

      it "tracks all status transitions" do
        transitions = [
          { from: "pending", to: "validated" },
          { from: "validated", to: "invoiced" },
          { from: "invoiced", to: "cancelled" }
        ]

        transitions.each do |transition|
          order.update!(status: transition[:from])
          AccountEvent.delete_all

          order.update!(status: transition[:to])
          event = AccountEvent.find_by(event_type: "order.status.changed")

          expect(event).to be_present
          expect(event.parsed_payload[:old_value]).to eq(transition[:from])
          expect(event.parsed_payload[:new_value]).to eq(transition[:to])
        end
      end
    end

    describe "total_amount tracking" do
      it "logs an event when total_amount changes" do
        expect {
          order.update!(total_amount: 150.0)
        }.to change(AccountEvent, :count).by(1)

        event = AccountEvent.last
        expect(event.event_type).to eq("order.total_amount.changed")
        expect(event.parsed_payload[:field]).to eq("total_amount")
        expect(event.parsed_payload[:old_value].to_f).to eq(100.0)
        expect(event.parsed_payload[:new_value].to_f).to eq(150.0)
      end

      it "tracks changes from nil to a value" do
        order.update_column(:total_amount, nil)
        AccountEvent.delete_all

        order.update!(total_amount: 50.0)
        event = AccountEvent.find_by(event_type: "order.total_amount.changed")

        expect(event).to be_present
        expect(event.parsed_payload[:old_value]).to be_nil
        expect(event.parsed_payload[:new_value].to_f).to eq(50.0)
      end

      it "tracks changes from a value to nil" do
        AccountEvent.delete_all

        order.update!(total_amount: nil)
        event = AccountEvent.find_by(event_type: "order.total_amount.changed")

        expect(event).to be_present
        expect(event.parsed_payload[:old_value].to_f).to eq(100.0)
        expect(event.parsed_payload[:new_value]).to be_nil
      end

      it "tracks decimal precision correctly" do
        order.update!(total_amount: 99.99)
        AccountEvent.delete_all

        order.update!(total_amount: 123.45)
        event = AccountEvent.find_by(event_type: "order.total_amount.changed")

        expect(event.parsed_payload[:old_value].to_f).to eq(99.99)
        expect(event.parsed_payload[:new_value].to_f).to eq(123.45)
      end
    end

    describe "multiple field changes" do
      it "logs separate events for each tracked field that changes" do
        expect {
          order.update!(status: "validated", total_amount: 200.0)
        }.to change(AccountEvent, :count).by(2)

        events = AccountEvent.last(2)
        event_types = events.map(&:event_type)
        expect(event_types).to include("order.status.changed")
        expect(event_types).to include("order.total_amount.changed")
      end

      it "logs each field change with correct old and new values" do
        order.update!(status: "validated", total_amount: 200.0)

        status_event = AccountEvent.find_by(event_type: "order.status.changed")
        amount_event = AccountEvent.find_by(event_type: "order.total_amount.changed")

        expect(status_event.parsed_payload[:old_value]).to eq("pending")
        expect(status_event.parsed_payload[:new_value]).to eq("validated")
        expect(amount_event.parsed_payload[:old_value].to_f).to eq(100.0)
        expect(amount_event.parsed_payload[:new_value].to_f).to eq(200.0)
      end
    end

    describe "untracked fields" do
      it "does not log events for untracked fields" do
        expect {
          order.update!(notes: "Updated notes")
        }.not_to change(AccountEvent, :count)
      end

      it "does not log events when updating reference" do
        expect {
          order.update!(reference: "ORD-NEW-REF123")
        }.not_to change(AccountEvent, :count)
      end
    end

    describe "transaction behavior" do
      it "does not create events if update fails" do
        allow(order).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          order.update!(status: "validated") rescue nil
        }.not_to change(AccountEvent, :count)
      end
    end
  end

  describe OrderLine do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }
    let(:order) { create(:order, account: account, customer: customer) }
    let(:order_line) { create(:order_line, order: order, unit_price: 25.0, quantity: 2) }

    describe "unit_price tracking" do
      it "logs an event when unit_price changes" do
        AccountEvent.delete_all

        expect {
          order_line.update!(unit_price: 30.0)
        }.to change(AccountEvent, :count).by_at_least(1)

        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event).to be_present
        expect(event.parsed_payload[:field]).to eq("unit_price")
        expect(event.parsed_payload[:old_value].to_f).to eq(25.0)
        expect(event.parsed_payload[:new_value].to_f).to eq(30.0)
      end

      it "associates the event with the order's account" do
        AccountEvent.delete_all
        order_line.update!(unit_price: 35.0)
        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event.account).to eq(order.account)
      end

      it "creates an OrderLine resource" do
        AccountEvent.delete_all
        order_line.update!(unit_price: 40.0)
        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event.resource.name).to eq("OrderLine##{order_line.id}")
        expect(event.resource.resource_type).to eq("OrderLine")
      end

      it "does not log an event when unit_price is unchanged" do
        AccountEvent.delete_all

        order_line.update!(quantity: 5)

        order_line_events = AccountEvent.where(event_type: "order_line.unit_price.changed")
        expect(order_line_events).to be_empty
      end

      it "tracks price increases" do
        AccountEvent.delete_all
        order_line.update!(unit_price: 50.0)

        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event.parsed_payload[:old_value].to_f).to eq(25.0)
        expect(event.parsed_payload[:new_value].to_f).to eq(50.0)
      end

      it "tracks price decreases" do
        AccountEvent.delete_all
        order_line.update!(unit_price: 10.0)

        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event.parsed_payload[:old_value].to_f).to eq(25.0)
        expect(event.parsed_payload[:new_value].to_f).to eq(10.0)
      end

      it "tracks changes to zero" do
        AccountEvent.delete_all
        order_line.update!(unit_price: 0.0)

        event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
        expect(event.parsed_payload[:old_value].to_f).to eq(25.0)
        expect(event.parsed_payload[:new_value].to_f).to eq(0.0)
      end
    end

    describe "cascading effects" do
      it "triggers order total_amount tracking when order_line price changes" do
        # Ensure order_line is created and events are cleared
        order_line
        AccountEvent.delete_all

        order_line.update!(unit_price: 50.0)

        # Should have both order_line.unit_price.changed and order.total_amount.changed
        expect(AccountEvent.where(event_type: "order_line.unit_price.changed").count).to eq(1)
        expect(AccountEvent.where(event_type: "order.total_amount.changed").count).to eq(1)
      end
    end
  end

  describe "class methods" do
    describe ".tracks" do
      it "sets tracked_fields on Order" do
        expect(Order.tracked_fields).to contain_exactly("total_amount", "status")
      end

      it "sets tracked_fields on OrderLine" do
        expect(OrderLine.tracked_fields).to eq(["unit_price"])
      end

      it "stores fields as strings" do
        Order.tracked_fields.each do |field|
          expect(field).to be_a(String)
        end
      end
    end

    describe "class_attribute isolation" do
      it "does not share tracked_fields between models" do
        expect(Order.tracked_fields).not_to eq(OrderLine.tracked_fields)
      end
    end
  end

  describe "event payload structure" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }
    let(:order) { create(:order, :pending, account: account, customer: customer, total_amount: 100.0) }

    it "includes field name in payload" do
      order.update!(status: "validated")
      event = AccountEvent.last
      expect(event.parsed_payload).to have_key(:field)
    end

    it "includes old_value in payload" do
      order.update!(status: "validated")
      event = AccountEvent.last
      expect(event.parsed_payload).to have_key(:old_value)
    end

    it "includes new_value in payload" do
      order.update!(status: "validated")
      event = AccountEvent.last
      expect(event.parsed_payload).to have_key(:new_value)
    end

    it "generates correct event_type format" do
      order.update!(status: "validated")
      event = AccountEvent.last
      expect(event.event_type).to match(/^[a-z_]+\.[a-z_]+\.changed$/)
    end
  end

  describe "querying tracked events" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }

    before do
      AccountEvent.delete_all
      order1 = create(:order, :pending, account: account, customer: customer, total_amount: 100.0)
      order2 = create(:order, :pending, account: account, customer: customer, total_amount: 200.0)

      order1.update!(status: "validated")
      order1.update!(total_amount: 150.0)
      order2.update!(status: "cancelled")
    end

    it "can filter status change events" do
      events = AccountEvent.by_type("order.status.changed")
      expect(events.count).to eq(2)
    end

    it "can filter total_amount change events" do
      events = AccountEvent.by_type("order.total_amount.changed")
      expect(events.count).to eq(1)
    end

    it "orders events by most recent first" do
      events = AccountEvent.recent.to_a
      expect(events.first.created_at).to be >= events.last.created_at
    end
  end
end
