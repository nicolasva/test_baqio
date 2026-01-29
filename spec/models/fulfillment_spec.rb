# frozen_string_literal: true

# Fulfillment Model Spec
# ======================
# Tests for the Fulfillment (shipment) model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Status values (pending, processing, shipped, delivered, cancelled)
# - Validations (status required, tracking_number uniqueness)
# - Associations (fulfillment_service, orders, delegated account)
# - Scopes (in_transit, completed, active, by status)
# - Status check methods (pending?, shipped?, etc.)
# - State transitions (ship!, deliver!, cancel!)
# - Instance methods (can_ship?, in_transit?, completed?, transit_duration)
#

require "rails_helper"

RSpec.describe Fulfillment, type: :model do
  describe "Test data creation" do
    it "can create a valid shipment for testing" do
      fulfillment = build(:fulfillment)
      expect(fulfillment).to be_valid
    end

    it "can create a shipment that has been shipped" do
      fulfillment = build(:fulfillment, :shipped)
      expect(fulfillment.status).to eq("shipped")
      expect(fulfillment.tracking_number).to be_present
      expect(fulfillment.shipped_at).to be_present
    end

    it "can create a shipment that has been delivered" do
      fulfillment = build(:fulfillment, :delivered)
      expect(fulfillment.status).to eq("delivered")
      expect(fulfillment.delivered_at).to be_present
    end
  end

  describe "Allowed status values" do
    it "only allows: pending, processing, shipped, delivered, or cancelled" do
      expect(Fulfillment::STATUSES).to eq(%w[pending processing shipped delivered cancelled])
    end
  end

  describe "Data validation rules" do
    describe "Shipment status" do
      it "requires a status to be set" do
        fulfillment = build(:fulfillment, status: nil)
        expect(fulfillment).not_to be_valid
        expect(fulfillment.errors[:status]).to include("can't be blank")
      end

      it "only accepts valid status values" do
        fulfillment = build(:fulfillment, status: "invalid")
        expect(fulfillment).not_to be_valid
        expect(fulfillment.errors[:status]).to include("is not included in the list")
      end

      it "accepts all defined statuses" do
        Fulfillment::STATUSES.each do |status|
          fulfillment = build(:fulfillment, status: status)
          expect(fulfillment).to be_valid
        end
      end
    end

    describe "Tracking number" do
      it "allows shipments without a tracking number" do
        fulfillment = build(:fulfillment, tracking_number: nil)
        expect(fulfillment).to be_valid
      end

      it "prevents duplicate tracking numbers" do
        create(:fulfillment, tracking_number: "TRACK123")
        duplicate = build(:fulfillment, tracking_number: "TRACK123")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:tracking_number]).to include("has already been taken")
      end
    end
  end

  describe "Relationships with other data" do
    let(:fulfillment_service) { create(:fulfillment_service) }
    let(:fulfillment) { create(:fulfillment, fulfillment_service: fulfillment_service) }

    it "is linked to a delivery service" do
      expect(fulfillment.fulfillment_service).to eq(fulfillment_service)
    end

    describe "Orders" do
      it "can have multiple orders" do
        account = fulfillment_service.account
        customer = create(:customer, account: account)
        order = create(:order, fulfillment: fulfillment, account: account, customer: customer)

        expect(fulfillment.orders).to include(order)
      end

      it "unlinks orders when the shipment is deleted (orders keep existing)" do
        account = fulfillment_service.account
        customer = create(:customer, account: account)
        order = create(:order, fulfillment: fulfillment, account: account, customer: customer)

        fulfillment.destroy
        expect(order.reload.fulfillment_id).to be_nil
      end
    end

    describe "Account access" do
      it "can access the account through the delivery service" do
        expect(fulfillment.account).to eq(fulfillment_service.account)
      end
    end
  end

  describe "Quick filters for searching shipments" do
    let(:fulfillment_service) { create(:fulfillment_service) }

    describe "Shipments in transit" do
      it "returns only processing and shipped items" do
        processing = create(:fulfillment, :processing, fulfillment_service: fulfillment_service)
        shipped = create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
        pending = create(:fulfillment, :pending, fulfillment_service: fulfillment_service)
        delivered = create(:fulfillment, :delivered, fulfillment_service: fulfillment_service)

        in_transit = Fulfillment.in_transit

        expect(in_transit).to include(processing, shipped)
        expect(in_transit).not_to include(pending, delivered)
      end
    end

    describe "Completed shipments" do
      it "returns only delivered and cancelled items" do
        delivered = create(:fulfillment, :delivered, fulfillment_service: fulfillment_service)
        cancelled = create(:fulfillment, :cancelled, fulfillment_service: fulfillment_service)
        pending = create(:fulfillment, :pending, fulfillment_service: fulfillment_service)

        completed = Fulfillment.completed

        expect(completed).to include(delivered, cancelled)
        expect(completed).not_to include(pending)
      end
    end

    describe "Active shipments" do
      it "returns all shipments that are not yet completed" do
        pending = create(:fulfillment, :pending, fulfillment_service: fulfillment_service)
        processing = create(:fulfillment, :processing, fulfillment_service: fulfillment_service)
        shipped = create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
        delivered = create(:fulfillment, :delivered, fulfillment_service: fulfillment_service)

        active = Fulfillment.active

        expect(active).to include(pending, processing, shipped)
        expect(active).not_to include(delivered)
      end
    end

    describe "Filter by status" do
      it "provides a filter for each shipment status" do
        Fulfillment::STATUSES.each do |status|
          expect(Fulfillment).to respond_to(status)
        end
      end
    end
  end

  describe "Status check methods" do
    it "provides a yes/no check for each status" do
      fulfillment = build(:fulfillment)
      Fulfillment::STATUSES.each do |status|
        expect(fulfillment).to respond_to("#{status}?")
      end
    end

    it "returns true only for the current status" do
      fulfillment = build(:fulfillment, status: "pending")
      expect(fulfillment.pending?).to be true
      expect(fulfillment.shipped?).to be false
    end
  end

  describe "Available actions on a shipment" do
    let(:fulfillment_service) { create(:fulfillment_service) }

    describe "Shipping a package" do
      context "when the shipment is pending" do
        let(:fulfillment) { create(:fulfillment, :pending, fulfillment_service: fulfillment_service) }

        it "changes the status to shipped" do
          fulfillment.ship!(tracking_number: "TRACK123")
          expect(fulfillment.reload.status).to eq("shipped")
        end

        it "saves the tracking number" do
          fulfillment.ship!(tracking_number: "TRACK123")
          expect(fulfillment.reload.tracking_number).to eq("TRACK123")
        end

        it "saves the carrier if provided" do
          fulfillment.ship!(tracking_number: "TRACK123", carrier: "UPS")
          expect(fulfillment.reload.carrier).to eq("UPS")
        end

        it "records the shipping date" do
          freeze_time do
            fulfillment.ship!(tracking_number: "TRACK123")
            expect(fulfillment.reload.shipped_at).to eq(Time.current)
          end
        end

        it "returns true to confirm success" do
          expect(fulfillment.ship!(tracking_number: "TRACK123")).to be_truthy
        end
      end

      context "when the shipment is being processed" do
        let(:fulfillment) { create(:fulfillment, :processing, fulfillment_service: fulfillment_service) }

        it "can be shipped" do
          expect(fulfillment.ship!(tracking_number: "TRACK123")).to be_truthy
          expect(fulfillment.reload.status).to eq("shipped")
        end
      end

      context "when the shipment was already shipped" do
        let(:fulfillment) { create(:fulfillment, :shipped, fulfillment_service: fulfillment_service) }

        it "returns false (cannot ship again)" do
          expect(fulfillment.ship!(tracking_number: "NEW123")).to be false
        end

        it "does not change the status" do
          fulfillment.ship!(tracking_number: "NEW123")
          expect(fulfillment.reload.status).to eq("shipped")
        end
      end

      context "when the shipment was already delivered" do
        let(:fulfillment) { create(:fulfillment, :delivered, fulfillment_service: fulfillment_service) }

        it "returns false (too late to ship)" do
          expect(fulfillment.ship!(tracking_number: "TRACK123")).to be false
        end
      end
    end

    describe "Marking as delivered" do
      context "when the shipment has been shipped" do
        let(:fulfillment) { create(:fulfillment, :shipped, fulfillment_service: fulfillment_service) }

        it "changes the status to delivered" do
          fulfillment.deliver!
          expect(fulfillment.reload.status).to eq("delivered")
        end

        it "records the delivery date" do
          freeze_time do
            fulfillment.deliver!
            expect(fulfillment.reload.delivered_at).to eq(Time.current)
          end
        end

        it "returns true to confirm success" do
          expect(fulfillment.deliver!).to be_truthy
        end
      end

      context "when the shipment has not been shipped yet" do
        let(:fulfillment) { create(:fulfillment, :pending, fulfillment_service: fulfillment_service) }

        it "returns false (must ship first)" do
          expect(fulfillment.deliver!).to be false
        end

        it "does not change the status" do
          fulfillment.deliver!
          expect(fulfillment.reload.status).to eq("pending")
        end
      end
    end

    describe "Cancelling a shipment" do
      context "when the shipment is pending" do
        let(:fulfillment) { create(:fulfillment, :pending, fulfillment_service: fulfillment_service) }

        it "changes the status to cancelled" do
          fulfillment.cancel!
          expect(fulfillment.reload.status).to eq("cancelled")
        end

        it "returns true to confirm success" do
          expect(fulfillment.cancel!).to be_truthy
        end
      end

      context "when the shipment has been delivered" do
        let(:fulfillment) { create(:fulfillment, :delivered, fulfillment_service: fulfillment_service) }

        it "returns false (cannot cancel after delivery)" do
          expect(fulfillment.cancel!).to be false
        end

        it "does not change the status" do
          fulfillment.cancel!
          expect(fulfillment.reload.status).to eq("delivered")
        end
      end
    end

    describe "Checking if shipment can be shipped" do
      it "returns true when pending" do
        fulfillment = build(:fulfillment, :pending)
        expect(fulfillment.can_ship?).to be true
      end

      it "returns true when processing" do
        fulfillment = build(:fulfillment, :processing)
        expect(fulfillment.can_ship?).to be true
      end

      it "returns false when already shipped" do
        fulfillment = build(:fulfillment, :shipped)
        expect(fulfillment.can_ship?).to be false
      end
    end

    describe "Checking if shipment is in transit" do
      it "returns true when processing" do
        fulfillment = build(:fulfillment, :processing)
        expect(fulfillment.in_transit?).to be true
      end

      it "returns true when shipped" do
        fulfillment = build(:fulfillment, :shipped)
        expect(fulfillment.in_transit?).to be true
      end

      it "returns false when still pending" do
        fulfillment = build(:fulfillment, :pending)
        expect(fulfillment.in_transit?).to be false
      end
    end

    describe "Checking if shipment is completed" do
      it "returns true when delivered" do
        fulfillment = build(:fulfillment, :delivered)
        expect(fulfillment.completed?).to be true
      end

      it "returns true when cancelled" do
        fulfillment = build(:fulfillment, :cancelled)
        expect(fulfillment.completed?).to be true
      end

      it "returns false when pending" do
        fulfillment = build(:fulfillment, :pending)
        expect(fulfillment.completed?).to be false
      end
    end

    describe "Calculating transit time" do
      it "returns nothing when not yet shipped" do
        fulfillment = build(:fulfillment, :pending)
        expect(fulfillment.transit_duration).to be_nil
      end

      it "returns nothing when shipped but not yet delivered" do
        fulfillment = build(:fulfillment, :shipped)
        expect(fulfillment.transit_duration).to be_nil
      end

      it "returns the number of days between shipping and delivery" do
        fulfillment = build(:fulfillment,
          shipped_at: 5.days.ago,
          delivered_at: 2.days.ago
        )
        expect(fulfillment.transit_duration).to eq(3)
      end
    end
  end
end
