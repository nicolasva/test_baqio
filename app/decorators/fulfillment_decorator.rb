# frozen_string_literal: true

# Decorator for Fulfillment model presentation logic.
# Provides formatted display values and status presentation for shipments.
#
# @example Using the decorator
#   fulfillment = Fulfillment.find(1).decorate
#   fulfillment.status_name          # => "Shipped"
#   fulfillment.status_badge         # => "badge-info"
#   fulfillment.carrier_with_tracking # => "UPS - 1Z999AA10123456784"
#   fulfillment.transit_duration_text # => "3 days"
#
class FulfillmentDecorator < ApplicationDecorator
  # Delegate all model methods to the underlying fulfillment
  delegate_all

  # ============================================
  # Status Configuration
  # ============================================

  # Define status presentation (name and badge class for each status)
  has_status_presentation(
    **StatusPresentable::COMMON_STATUSES,
    pending: "badge-secondary",
    processing: "badge-warning",
    shipped: "badge-info",
    delivered: "badge-success"
  )

  # ============================================
  # Formatting Configuration
  # ============================================

  # Format shipping dates with short format
  formats_date :shipped_at, :delivered_at, format: :short

  # ============================================
  # Service Methods
  # ============================================

  # Returns the fulfillment service name.
  #
  # @return [String, nil] service name or nil
  def service_name
    fulfillment_service&.name
  end

  # ============================================
  # Tracking Methods
  # ============================================

  # Returns the carrier name with tracking number.
  # If tracking number is present, formats as "Carrier - TrackingNumber".
  #
  # @return [String, nil] carrier with tracking or just carrier
  def carrier_with_tracking
    return carrier unless tracking_number.present?

    "#{carrier} - #{tracking_number}"
  end

  # Returns the tracking number for display.
  # Can be extended to return a link to the carrier's tracking page.
  #
  # @return [String, nil] tracking number or nil
  def tracking_link
    return nil unless tracking_number.present?

    tracking_number
  end

  # ============================================
  # Duration Methods
  # ============================================

  # Returns the transit duration as formatted text.
  # Handles singular/plural correctly ("1 day" vs "3 days").
  #
  # @return [String, nil] formatted duration or nil if not delivered
  def transit_duration_text
    days = transit_duration
    return nil unless days

    "#{days} #{days == 1 ? 'day' : 'days'}"
  end
end
