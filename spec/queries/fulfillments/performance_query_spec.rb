# frozen_string_literal: true

# Fulfillments::PerformanceQuery Spec
# ===================================
# Tests for the shipping performance metrics query.
#
# Covers:
# - call: delivered fulfillments only
# - average_transit_time: average days from shipped to delivered
# - on_time_delivery_rate: percentage delivered within 5 days
# - metrics: complete performance dashboard
#   - total_delivered, average_transit_time, on_time_rate
#   - by_carrier and by_service breakdowns
# - transit_time_distribution: deliveries grouped by transit time buckets
#   - 1 day, 2-3 days, 4-5 days, 6-7 days, 8+ days
#

require "rails_helper"

RSpec.describe Fulfillments::PerformanceQuery do
  let(:account) { create(:account) }
  let(:service) { create(:fulfillment_service, account: account) }

  describe "#call" do
    it "returns only delivered fulfillments" do
      create(:fulfillment, :delivered, fulfillment_service: service)
      create(:fulfillment, :shipped, fulfillment_service: service)
      create(:fulfillment, :pending, fulfillment_service: service)

      result = described_class.new(service.fulfillments).call

      expect(result.count).to eq(1)
    end
  end

  describe "#average_transit_time" do
    it "calculates average transit time" do
      # 2 days transit
      create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 5.days.ago,
        delivered_at: 3.days.ago
      )

      # 4 days transit
      create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 6.days.ago,
        delivered_at: 2.days.ago
      )

      result = described_class.new(service.fulfillments).average_transit_time

      expect(result).to eq(3.0) # (2 + 4) / 2
    end

    it "returns 0 when no delivered fulfillments" do
      result = described_class.new(service.fulfillments).average_transit_time

      expect(result).to eq(0)
    end
  end

  describe "#on_time_delivery_rate" do
    it "calculates on-time delivery rate" do
      # On time (3 days)
      create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 5.days.ago,
        delivered_at: 2.days.ago
      )

      # On time (4 days)
      create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 6.days.ago,
        delivered_at: 2.days.ago
      )

      # Late (7 days)
      create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 10.days.ago,
        delivered_at: 3.days.ago
      )

      result = described_class.new(service.fulfillments).on_time_delivery_rate

      expect(result).to eq(66.7) # 2/3 * 100
    end
  end

  describe "#metrics" do
    before do
      create(:fulfillment, :delivered, fulfillment_service: service,
        shipped_at: 3.days.ago,
        delivered_at: 1.day.ago,
        carrier: "DHL"
      )
    end

    it "returns complete performance metrics" do
      result = described_class.new(service.fulfillments).metrics

      expect(result).to have_key(:total_delivered)
      expect(result).to have_key(:average_transit_time)
      expect(result).to have_key(:on_time_delivery_rate)
      expect(result).to have_key(:by_carrier)
      expect(result).to have_key(:by_service)
    end
  end

  describe "#transit_time_distribution" do
    it "groups deliveries by transit time buckets" do
      # 1 day transit
      create(:fulfillment, fulfillment_service: service,
        status: "delivered", shipped_at: 2.days.ago, delivered_at: 1.day.ago)

      # 3 days transit
      create(:fulfillment, fulfillment_service: service,
        status: "delivered", shipped_at: 5.days.ago, delivered_at: 2.days.ago)

      # 5 days transit
      create(:fulfillment, fulfillment_service: service,
        status: "delivered", shipped_at: 7.days.ago, delivered_at: 2.days.ago)

      result = described_class.new(service.fulfillments).transit_time_distribution

      expect(result["1 day"]).to eq(1)
      expect(result["2-3 days"]).to eq(1)
      expect(result["4-5 days"]).to eq(1)
    end
  end
end
