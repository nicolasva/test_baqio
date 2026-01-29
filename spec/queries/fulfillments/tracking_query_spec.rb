# frozen_string_literal: true

# Fulfillments::TrackingQuery Spec
# ================================
# Tests for the shipment tracking search query.
#
# Covers:
# - call: fulfillments with tracking numbers
# - by_tracking_number: exact match lookup
# - by_carrier: filter by carrier name (partial match)
# - active: in-transit shipments with tracking
# - recently_delivered: delivered within N days
# - for_customer: fulfillments for a specific customer
# - search: combined criteria search (tracking, carrier, status)
# - tracking_stats: statistics by carrier and status
#

require "rails_helper"

RSpec.describe Fulfillments::TrackingQuery do
  let(:account) { create(:account) }
  let(:service) { create(:fulfillment_service, account: account) }

  describe "#call" do
    it "returns fulfillments with tracking numbers" do
      with_tracking = create(:fulfillment, :shipped, fulfillment_service: service, tracking_number: "TRACK123")
      without_tracking = create(:fulfillment, :pending, fulfillment_service: service, tracking_number: nil)

      result = described_class.new(service.fulfillments).call

      expect(result).to include(with_tracking)
      expect(result).not_to include(without_tracking)
    end
  end

  describe "#by_tracking_number" do
    it "finds fulfillment by exact tracking number" do
      fulfillment = create(:fulfillment, :shipped, fulfillment_service: service, tracking_number: "ABC123456")

      result = described_class.new(service.fulfillments).by_tracking_number("ABC123456")

      expect(result).to eq(fulfillment)
    end

    it "returns nil when not found" do
      result = described_class.new(service.fulfillments).by_tracking_number("NONEXISTENT")

      expect(result).to be_nil
    end
  end

  describe "#by_carrier" do
    before do
      create(:fulfillment, :shipped, fulfillment_service: service, carrier: "DHL Express", tracking_number: "DHL001")
      create(:fulfillment, :shipped, fulfillment_service: service, carrier: "UPS", tracking_number: "UPS001")
      create(:fulfillment, :shipped, fulfillment_service: service, carrier: "DHL Standard", tracking_number: "DHL002")
    end

    it "filters by carrier name" do
      result = described_class.new(service.fulfillments).by_carrier("DHL")

      expect(result.count).to eq(2)
    end
  end

  describe "#active" do
    before do
      @shipped = create(:fulfillment, :shipped, fulfillment_service: service, tracking_number: "SHIP001")
      @processing = create(:fulfillment, :processing, fulfillment_service: service, tracking_number: "PROC001")
      @delivered = create(:fulfillment, :delivered, fulfillment_service: service, tracking_number: "DEL001")
      @pending = create(:fulfillment, :pending, fulfillment_service: service, tracking_number: "PEND001")
    end

    it "returns in-transit fulfillments with tracking" do
      result = described_class.new(service.fulfillments).active

      expect(result).to include(@shipped, @processing)
      expect(result).not_to include(@delivered, @pending)
    end
  end

  describe "#recently_delivered" do
    before do
      @recent = create(:fulfillment, :delivered, fulfillment_service: service,
        delivered_at: 3.days.ago, tracking_number: "REC001")
      @old = create(:fulfillment, :delivered, fulfillment_service: service,
        delivered_at: 15.days.ago, tracking_number: "OLD001")
    end

    it "returns deliveries within specified days" do
      result = described_class.new(service.fulfillments).recently_delivered(days: 7)

      expect(result).to include(@recent)
      expect(result).not_to include(@old)
    end
  end

  describe "#for_customer" do
    it "returns fulfillments for a specific customer" do
      customer = create(:customer, account: account)
      fulfillment = create(:fulfillment, :shipped, fulfillment_service: service, tracking_number: "CUST001")
      order = create(:order, account: account, customer: customer, fulfillment: fulfillment)

      other_customer = create(:customer, account: account)
      other_fulfillment = create(:fulfillment, :shipped, fulfillment_service: service, tracking_number: "OTHER001")
      create(:order, account: account, customer: other_customer, fulfillment: other_fulfillment)

      result = described_class.new(Fulfillment.all).for_customer(customer)

      expect(result).to include(fulfillment)
      expect(result).not_to include(other_fulfillment)
    end
  end

  describe "#search" do
    before do
      @f1 = create(:fulfillment, :shipped, fulfillment_service: service,
        tracking_number: "DHL123", carrier: "DHL", shipped_at: 5.days.ago)
      @f2 = create(:fulfillment, :delivered, fulfillment_service: service,
        tracking_number: "UPS456", carrier: "UPS", shipped_at: 10.days.ago)
    end

    it "searches by tracking number" do
      result = described_class.new(service.fulfillments).search(tracking_number: "DHL")

      expect(result).to include(@f1)
      expect(result).not_to include(@f2)
    end

    it "searches by carrier" do
      result = described_class.new(service.fulfillments).search(carrier: "UPS")

      expect(result).to include(@f2)
      expect(result).not_to include(@f1)
    end

    it "searches by status" do
      result = described_class.new(service.fulfillments).search(status: "delivered")

      expect(result).to include(@f2)
      expect(result).not_to include(@f1)
    end

    it "combines multiple criteria" do
      result = described_class.new(service.fulfillments).search(
        carrier: "DHL",
        status: "shipped"
      )

      expect(result).to include(@f1)
      expect(result.count).to eq(1)
    end
  end

  describe "#tracking_stats" do
    before do
      create(:fulfillment, :shipped, fulfillment_service: service,
        tracking_number: "TRACK1", carrier: "DHL")
      create(:fulfillment, :shipped, fulfillment_service: service,
        tracking_number: "TRACK2", carrier: "DHL")
      create(:fulfillment, :delivered, fulfillment_service: service,
        tracking_number: "TRACK3", carrier: "UPS")
    end

    it "returns tracking statistics" do
      stats = described_class.new(service.fulfillments).tracking_stats

      expect(stats[:total_with_tracking]).to eq(3)
      expect(stats[:by_carrier]).to include("DHL" => 2, "UPS" => 1)
      expect(stats[:by_status]).to include("shipped" => 2, "delivered" => 1)
    end
  end
end
