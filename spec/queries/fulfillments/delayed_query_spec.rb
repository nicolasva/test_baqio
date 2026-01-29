# frozen_string_literal: true

# Fulfillments::DelayedQuery Spec
# ===============================
# Tests for the delayed shipments detection query.
#
# Covers:
# - call: all delayed fulfillments
# - stuck_in_pending: pending > 2 days
# - stuck_in_processing: processing with no update > 2 days
# - shipping_taking_too_long: shipped > 7 days without delivery
# - grouped: fulfillments grouped by delay type
# - stats: delay statistics (total, by type)
# - Custom processing_threshold option
#

require "rails_helper"

RSpec.describe Fulfillments::DelayedQuery do
  let(:account) { create(:account) }
  let(:service) { create(:fulfillment_service, account: account) }

  describe "#call" do
    it "returns all delayed fulfillments" do
      stuck_pending = create(:fulfillment, :pending, fulfillment_service: service, created_at: 5.days.ago)
      create(:fulfillment, :pending, fulfillment_service: service, created_at: 1.day.ago)

      result = described_class.new(service.fulfillments).call

      expect(result).to include(stuck_pending)
      expect(result.count).to eq(1)
    end
  end

  describe "#stuck_in_pending" do
    it "returns fulfillments stuck in pending status" do
      stuck = create(:fulfillment, :pending, fulfillment_service: service, created_at: 5.days.ago)
      create(:fulfillment, :pending, fulfillment_service: service, created_at: 1.day.ago)

      result = described_class.new(service.fulfillments).stuck_in_pending

      expect(result).to include(stuck)
      expect(result.count).to eq(1)
    end
  end

  describe "#stuck_in_processing" do
    it "returns fulfillments stuck in processing status" do
      stuck = create(:fulfillment, :processing, fulfillment_service: service)
      stuck.update_column(:updated_at, 5.days.ago)

      create(:fulfillment, :processing, fulfillment_service: service)

      result = described_class.new(service.fulfillments).stuck_in_processing

      expect(result).to include(stuck)
      expect(result.count).to eq(1)
    end
  end

  describe "#shipping_taking_too_long" do
    it "returns shipments in transit too long" do
      delayed = create(:fulfillment, :shipped, fulfillment_service: service, shipped_at: 10.days.ago)
      create(:fulfillment, :shipped, fulfillment_service: service, shipped_at: 2.days.ago)

      result = described_class.new(service.fulfillments).shipping_taking_too_long

      expect(result).to include(delayed)
      expect(result.count).to eq(1)
    end
  end

  describe "#grouped" do
    it "returns fulfillments grouped by delay type" do
      create(:fulfillment, :pending, fulfillment_service: service, created_at: 5.days.ago)

      result = described_class.new(service.fulfillments).grouped

      expect(result.keys).to contain_exactly(:stuck_pending, :stuck_processing, :shipping_delayed)
    end
  end

  describe "#stats" do
    it "returns delay statistics" do
      create(:fulfillment, :pending, fulfillment_service: service, created_at: 5.days.ago)
      create(:fulfillment, :shipped, fulfillment_service: service, shipped_at: 10.days.ago)

      result = described_class.new(service.fulfillments).stats

      expect(result[:total_delayed]).to eq(2)
      expect(result[:stuck_pending]).to eq(1)
      expect(result[:shipping_delayed]).to eq(1)
    end
  end

  describe "with custom thresholds" do
    it "uses custom processing threshold" do
      create(:fulfillment, :pending, fulfillment_service: service, created_at: 3.days.ago)

      # Default threshold (2 days) - should be included
      result_default = described_class.new(service.fulfillments).stuck_in_pending
      expect(result_default.count).to eq(1)

      # Custom threshold (5 days) - should not be included
      result_custom = described_class.new(service.fulfillments, options: { processing_threshold: 5 }).stuck_in_pending
      expect(result_custom.count).to eq(0)
    end
  end
end
