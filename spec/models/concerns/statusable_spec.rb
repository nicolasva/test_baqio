# frozen_string_literal: true

# Statusable Concern Spec
# =======================
# Tests for the Statusable concern (shared status functionality).
#
# Covers:
# - Order with statuses: pending, validated, invoiced, cancelled
# - Invoice with statuses: draft, sent, paid, cancelled
# - Fulfillment with statuses: pending, processing, shipped, delivered, cancelled
#
# Shared behavior:
# - Status validation (must be in STATUSES list)
# - Dynamic scopes for each status
# - with_status / without_status filtering
# - Status predicate methods (pending?, shipped?, etc.)
#
# Uses shared example "a statusable model" for common tests.
#

require "rails_helper"

RSpec.describe Statusable, type: :model do
  describe Order do
    subject { build(:order) }

    it_behaves_like "a statusable model", %i[pending validated invoiced cancelled]

    describe ".with_status" do
      let!(:pending_order) { create(:order, :pending) }
      let!(:validated_order) { create(:order, :validated) }
      let!(:cancelled_order) { create(:order, :cancelled) }

      it "returns orders with specified status" do
        expect(Order.with_status(:pending)).to include(pending_order)
        expect(Order.with_status(:pending)).not_to include(validated_order)
      end

      it "accepts multiple statuses as array" do
        expect(Order.with_status([:pending, :validated])).to include(pending_order, validated_order)
        expect(Order.with_status([:pending, :validated])).not_to include(cancelled_order)
      end
    end

    describe ".without_status" do
      let!(:pending_order) { create(:order, :pending) }
      let!(:cancelled_order) { create(:order, :cancelled) }

      it "excludes orders with specified status" do
        expect(Order.without_status(:cancelled)).to include(pending_order)
        expect(Order.without_status(:cancelled)).not_to include(cancelled_order)
      end
    end
  end

  describe Invoice do
    subject { build(:invoice) }

    it_behaves_like "a statusable model", %i[draft sent paid cancelled]
  end

  describe Fulfillment do
    subject { build(:fulfillment) }

    it_behaves_like "a statusable model", %i[pending processing shipped delivered cancelled]
  end
end
