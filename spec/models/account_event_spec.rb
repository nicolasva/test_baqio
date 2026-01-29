# frozen_string_literal: true

# AccountEvent Model Spec
# =======================
# Tests for the AccountEvent (audit log) model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Validations (event_type, account, resource required)
# - Associations (account, resource)
# - Scopes (by_type, recent, today, this_week)
# - Instance methods (parsed_payload for JSON parsing)
# - Class methods (log for creating events with associated resources)
#
# Note: Payload is stored as JSON string, parsed_payload returns hash.
#

require "rails_helper"

RSpec.describe AccountEvent, type: :model do
  describe "factory" do
    it "creates a valid account_event" do
      event = build(:account_event)
      expect(event).to be_valid
    end

    it "creates event with payload" do
      event = create(:account_event, :with_payload)
      expect(event.payload).to be_present
    end
  end

  describe "validations" do
    it "requires an event_type" do
      event = build(:account_event, event_type: nil)
      expect(event).not_to be_valid
      expect(event.errors[:event_type]).to include("can't be blank")
    end

    it "requires an account" do
      event = build(:account_event, account: nil)
      expect(event).not_to be_valid
    end

    it "requires a resource" do
      event = build(:account_event, resource: nil)
      expect(event).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to account" do
      account = create(:account)
      event = create(:account_event, account: account)
      expect(event.account).to eq(account)
    end

    it "belongs to resource" do
      resource = create(:resource)
      event = create(:account_event, resource: resource)
      expect(event.resource).to eq(resource)
    end
  end

  describe "scopes" do
    describe ".by_type" do
      it "filters by event_type" do
        event1 = create(:account_event, event_type: "order.created")
        event2 = create(:account_event, event_type: "order.cancelled")

        expect(AccountEvent.by_type("order.created")).to include(event1)
        expect(AccountEvent.by_type("order.created")).not_to include(event2)
      end
    end

    describe ".recent" do
      it "orders by created_at desc" do
        old_event = create(:account_event, created_at: 2.days.ago)
        new_event = create(:account_event, created_at: 1.hour.ago)

        expect(AccountEvent.recent.first).to eq(new_event)
        expect(AccountEvent.recent.last).to eq(old_event)
      end
    end

    describe ".today" do
      it "returns only events from today" do
        today_event = create(:account_event)
        yesterday_event = create(:account_event, created_at: 1.day.ago)

        expect(AccountEvent.today).to include(today_event)
        expect(AccountEvent.today).not_to include(yesterday_event)
      end
    end

    describe ".this_week" do
      it "returns only events from this week" do
        this_week_event = create(:account_event)
        last_week_event = create(:account_event, created_at: 2.weeks.ago)

        expect(AccountEvent.this_week).to include(this_week_event)
        expect(AccountEvent.this_week).not_to include(last_week_event)
      end
    end
  end

  describe "instance methods" do
    describe "#parsed_payload" do
      it "returns empty hash when payload is nil" do
        event = create(:account_event, payload: nil)
        expect(event.parsed_payload).to eq({})
      end

      it "returns empty hash when payload is blank" do
        event = create(:account_event, payload: "")
        expect(event.parsed_payload).to eq({})
      end

      it "parses valid JSON payload" do
        event = create(:account_event, payload: '{"key": "value", "number": 42}')
        expect(event.parsed_payload).to eq({ key: "value", number: 42 })
      end

      it "returns empty hash for invalid JSON" do
        event = create(:account_event, payload: "not valid json")
        expect(event.parsed_payload).to eq({})
      end

      it "symbolizes keys" do
        event = create(:account_event, payload: '{"string_key": "value"}')
        expect(event.parsed_payload.keys).to all(be_a(Symbol))
      end
    end
  end

  describe "class methods" do
    describe ".log" do
      let(:account) { create(:account) }
      let(:customer) { create(:customer, account: account) }
      let(:order) { create(:order, account: account, customer: customer) }

      it "creates a new account event" do
        expect {
          AccountEvent.log(account: account, record: order, event_type: "order.created")
        }.to change(AccountEvent, :count).by(1)
      end

      it "creates associated resource" do
        expect {
          AccountEvent.log(account: account, record: order, event_type: "order.created")
        }.to change(Resource, :count).by(1)
      end

      it "sets correct event_type" do
        event = AccountEvent.log(account: account, record: order, event_type: "order.created")
        expect(event.event_type).to eq("order.created")
      end

      it "sets correct account" do
        event = AccountEvent.log(account: account, record: order, event_type: "order.created")
        expect(event.account).to eq(account)
      end

      it "converts payload to JSON" do
        event = AccountEvent.log(
          account: account,
          record: order,
          event_type: "order.created",
          payload: { foo: "bar" }
        )
        expect(event.payload).to eq('{"foo":"bar"}')
      end

      it "handles nil payload" do
        event = AccountEvent.log(account: account, record: order, event_type: "order.created", payload: nil)
        expect(event.payload).to be_nil
      end
    end
  end
end
