# frozen_string_literal: true

# FulfillmentDecorator Spec
# =========================
# Tests for the FulfillmentDecorator (presentation logic).
#
# Covers:
# - status_name: human-readable status names
# - status_badge: CSS class for status badges
# - service_name: fulfillment service name
# - carrier_with_tracking: "Carrier - TrackingNumber" format
# - transit_duration_text: "X days" pluralization
#

require "rails_helper"

RSpec.describe FulfillmentDecorator do
  let(:fulfillment_service) { create(:fulfillment_service, name: "DHL Express") }
  let(:fulfillment) { create(:fulfillment, fulfillment_service: fulfillment_service, status: "pending") }
  let(:decorated_fulfillment) { fulfillment.decorate }

  describe "#status_name" do
    it "returns English name for pending" do
      fulfillment.update!(status: "pending")
      expect(decorated_fulfillment.status_name).to eq("Pending")
    end

    it "returns English name for processing" do
      fulfillment.update!(status: "processing")
      expect(decorated_fulfillment.status_name).to eq("Processing")
    end

    it "returns English name for shipped" do
      fulfillment.update!(status: "shipped", tracking_number: "TRACK123", shipped_at: Time.current)
      expect(decorated_fulfillment.status_name).to eq("Shipped")
    end

    it "returns English name for delivered" do
      fulfillment.update!(status: "delivered", tracking_number: "TRACK123", shipped_at: 2.days.ago, delivered_at: Time.current)
      expect(decorated_fulfillment.status_name).to eq("Delivered")
    end

    it "returns English name for cancelled" do
      fulfillment.update!(status: "cancelled")
      expect(decorated_fulfillment.status_name).to eq("Cancelled")
    end
  end

  describe "#status_badge" do
    it "returns badge class for pending" do
      expect(decorated_fulfillment.status_badge).to eq("badge-secondary")
    end

    it "returns badge class for shipped" do
      fulfillment.update!(status: "shipped", tracking_number: "TRACK123", shipped_at: Time.current)
      expect(decorated_fulfillment.status_badge).to eq("badge-info")
    end

    it "returns badge class for delivered" do
      fulfillment.update!(status: "delivered", tracking_number: "TRACK123", shipped_at: 2.days.ago, delivered_at: Time.current)
      expect(decorated_fulfillment.status_badge).to eq("badge-success")
    end
  end

  describe "#service_name" do
    it "returns fulfillment service name" do
      expect(decorated_fulfillment.service_name).to eq("DHL Express")
    end
  end

  describe "#carrier_with_tracking" do
    it "returns carrier alone when no tracking number" do
      fulfillment.update!(carrier: "UPS")
      expect(decorated_fulfillment.carrier_with_tracking).to eq("UPS")
    end

    it "returns carrier with tracking number when present" do
      fulfillment.update!(carrier: "UPS", tracking_number: "1Z999AA10123456784")
      expect(decorated_fulfillment.carrier_with_tracking).to eq("UPS - 1Z999AA10123456784")
    end
  end

  describe "#transit_duration_text" do
    it "returns nil when not shipped" do
      expect(decorated_fulfillment.transit_duration_text).to be_nil
    end

    it "returns singular for 1 day" do
      fulfillment.update!(shipped_at: 1.day.ago, delivered_at: Time.current)
      expect(decorated_fulfillment.transit_duration_text).to eq("1 day")
    end

    it "returns plural for multiple days" do
      fulfillment.update!(shipped_at: 5.days.ago, delivered_at: 2.days.ago)
      expect(decorated_fulfillment.transit_duration_text).to eq("3 days")
    end
  end
end
