# frozen_string_literal: true

# TrackingInfo Value Object Spec
# ==============================
# Tests for the TrackingInfo immutable value object.
#
# Covers:
# - Initialization (number, carrier, normalization, freeze)
# - Equality (==, hash for hash keys)
# - Predicates (present?, blank?)
# - tracking_url: generates carrier-specific tracking URLs
#   - UPS, DHL, Colissimo, FedEx, etc.
# - to_s: "Carrier - TrackingNumber" format
# - Class method: .empty
#

require "rails_helper"

RSpec.describe TrackingInfo do
  describe "#initialize" do
    it "creates tracking info with number and carrier" do
      tracking = TrackingInfo.new(number: "1Z999AA10123456784", carrier: "UPS")

      expect(tracking.number).to eq("1Z999AA10123456784")
      expect(tracking.carrier).to eq("UPS")
    end

    it "normalizes number to uppercase" do
      tracking = TrackingInfo.new(number: "abc123", carrier: nil)

      expect(tracking.number).to eq("ABC123")
    end

    it "normalizes carrier to uppercase" do
      tracking = TrackingInfo.new(number: "123", carrier: "ups")

      expect(tracking.carrier).to eq("UPS")
    end

    it "strips whitespace" do
      tracking = TrackingInfo.new(number: "  ABC123  ", carrier: "  UPS  ")

      expect(tracking.number).to eq("ABC123")
      expect(tracking.carrier).to eq("UPS")
    end

    it "handles nil values" do
      tracking = TrackingInfo.new(number: nil, carrier: nil)

      expect(tracking.number).to be_nil
      expect(tracking.carrier).to be_nil
    end

    it "is frozen after creation" do
      tracking = TrackingInfo.new(number: "123", carrier: "UPS")

      expect(tracking).to be_frozen
    end
  end

  describe "#==" do
    it "returns true for equal tracking info" do
      tracking1 = TrackingInfo.new(number: "123", carrier: "UPS")
      tracking2 = TrackingInfo.new(number: "123", carrier: "UPS")

      expect(tracking1 == tracking2).to be true
    end

    it "returns false for different numbers" do
      tracking1 = TrackingInfo.new(number: "123", carrier: "UPS")
      tracking2 = TrackingInfo.new(number: "456", carrier: "UPS")

      expect(tracking1 == tracking2).to be false
    end

    it "returns false for different carriers" do
      tracking1 = TrackingInfo.new(number: "123", carrier: "UPS")
      tracking2 = TrackingInfo.new(number: "123", carrier: "DHL")

      expect(tracking1 == tracking2).to be false
    end
  end

  describe "#hash" do
    it "returns same hash for equal objects" do
      tracking1 = TrackingInfo.new(number: "123", carrier: "UPS")
      tracking2 = TrackingInfo.new(number: "123", carrier: "UPS")

      expect(tracking1.hash).to eq(tracking2.hash)
    end

    it "can be used as hash key" do
      tracking = TrackingInfo.new(number: "123", carrier: "UPS")
      hash = { tracking => "value" }

      expect(hash[TrackingInfo.new(number: "123", carrier: "UPS")]).to eq("value")
    end
  end

  describe "#present?" do
    it "returns true when number is present" do
      tracking = TrackingInfo.new(number: "123", carrier: nil)

      expect(tracking).to be_present
    end

    it "returns false when number is blank" do
      tracking = TrackingInfo.new(number: nil, carrier: "UPS")

      expect(tracking).not_to be_present
    end
  end

  describe "#blank?" do
    it "returns true when number is blank" do
      tracking = TrackingInfo.new(number: nil, carrier: nil)

      expect(tracking).to be_blank
    end

    it "returns false when number is present" do
      tracking = TrackingInfo.new(number: "123", carrier: nil)

      expect(tracking).not_to be_blank
    end
  end

  describe "#tracking_url" do
    it "returns UPS tracking URL" do
      tracking = TrackingInfo.new(number: "1Z999AA10123456784", carrier: "UPS")

      expect(tracking.tracking_url).to eq("https://www.ups.com/track?tracknum=1Z999AA10123456784")
    end

    it "returns DHL tracking URL" do
      tracking = TrackingInfo.new(number: "1234567890", carrier: "DHL")

      expect(tracking.tracking_url).to include("dhl.com")
      expect(tracking.tracking_url).to include("1234567890")
    end

    it "returns Colissimo tracking URL" do
      tracking = TrackingInfo.new(number: "9V12345678901", carrier: "COLISSIMO")

      expect(tracking.tracking_url).to include("laposte.fr")
    end

    it "returns nil for unknown carrier" do
      tracking = TrackingInfo.new(number: "123", carrier: "UNKNOWN")

      expect(tracking.tracking_url).to be_nil
    end

    it "returns nil when number is blank" do
      tracking = TrackingInfo.new(number: nil, carrier: "UPS")

      expect(tracking.tracking_url).to be_nil
    end

    it "returns nil when carrier is blank" do
      tracking = TrackingInfo.new(number: "123", carrier: nil)

      expect(tracking.tracking_url).to be_nil
    end
  end

  describe "#to_s" do
    it "returns carrier and number" do
      tracking = TrackingInfo.new(number: "123", carrier: "UPS")

      expect(tracking.to_s).to eq("UPS - 123")
    end

    it "returns only number when no carrier" do
      tracking = TrackingInfo.new(number: "123", carrier: nil)

      expect(tracking.to_s).to eq("123")
    end

    it "returns empty string when blank" do
      tracking = TrackingInfo.new(number: nil, carrier: nil)

      expect(tracking.to_s).to eq("")
    end
  end

  describe ".empty" do
    it "returns empty tracking info" do
      tracking = TrackingInfo.empty

      expect(tracking.number).to be_nil
      expect(tracking.carrier).to be_nil
      expect(tracking).to be_blank
    end
  end
end
