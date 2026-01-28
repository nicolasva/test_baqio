# frozen_string_literal: true

# Fulfillment model representing a shipment for order(s).
# Tracks the shipping lifecycle from pending to delivered.
# A fulfillment belongs to a fulfillment service (shipping provider).
#
# @example Shipping workflow
#   fulfillment = Fulfillment.create!(fulfillment_service: service)
#   fulfillment.ship!(tracking_number: "1Z999AA10123456784", carrier: "UPS")
#   fulfillment.deliver!
#
# @example Fulfillment statuses
#   - pending: Shipment created but not yet processed
#   - processing: Shipment is being prepared
#   - shipped: Package has been shipped
#   - delivered: Package has been delivered
#   - cancelled: Shipment was cancelled
#
class Fulfillment < ApplicationRecord
  include Statusable  # Provides status management methods

  # ============================================
  # Associations
  # ============================================

  # The fulfillment service (shipping provider) handling this shipment
  belongs_to :fulfillment_service

  # Orders associated with this fulfillment
  # When fulfillment is deleted, orders are not deleted (nullify)
  has_many :orders, dependent: :nullify

  # ============================================
  # Status Configuration
  # ============================================

  # Define valid statuses for fulfillments
  has_statuses :pending, :processing, :shipped, :delivered, :cancelled

  # ============================================
  # Validations
  # ============================================

  # Tracking number must be unique if provided
  validates :tracking_number, uniqueness: true, allow_blank: true

  # ============================================
  # Scopes
  # ============================================

  # Shipments currently in transit (processing or shipped)
  scope :in_transit, -> { where(status: %w[processing shipped]) }

  # Shipments that have reached a final state (delivered or cancelled)
  scope :completed, -> { where(status: %w[delivered cancelled]) }

  # Shipments that are still active (not delivered or cancelled)
  scope :active, -> { where.not(status: %w[delivered cancelled]) }

  # ============================================
  # Delegations
  # ============================================

  # Access account through fulfillment service
  delegate :account, to: :fulfillment_service

  # ============================================
  # Status Transition Methods
  # ============================================

  # Ships the package with tracking information.
  # Can only ship if status is pending or processing.
  #
  # @param tracking_number [String] the tracking number from carrier
  # @param carrier [String, nil] optional carrier name
  # @return [Boolean] true if shipped successfully, false otherwise
  def ship!(tracking_number:, carrier: nil)
    return false unless can_ship?

    update!(
      status: "shipped",
      tracking_number: tracking_number,
      carrier: carrier,
      shipped_at: Time.current
    )
  end

  # Marks the shipment as delivered.
  # Can only deliver if status is shipped.
  #
  # @return [Boolean] true if marked as delivered, false otherwise
  def deliver!
    return false unless shipped?

    update!(status: "delivered", delivered_at: Time.current)
  end

  # Cancels the shipment.
  # Cannot cancel a delivered shipment.
  #
  # @return [Boolean] true if cancelled, false if already delivered
  def cancel!
    return false if delivered?

    update!(status: "cancelled")
  end

  # ============================================
  # Status Query Methods
  # ============================================

  # Checks if the shipment can be shipped.
  # Must be in pending or processing status.
  #
  # @return [Boolean] true if can ship
  def can_ship?
    pending? || processing?
  end

  # Checks if the shipment is currently in transit.
  # True if processing or shipped.
  #
  # @return [Boolean] true if in transit
  def in_transit?
    processing? || shipped?
  end

  # Checks if the shipment has reached a final state.
  # True if delivered or cancelled.
  #
  # @return [Boolean] true if completed
  def completed?
    delivered? || cancelled?
  end

  # ============================================
  # Metrics Methods
  # ============================================

  # Calculates the transit duration in days.
  # Returns nil if shipped_at or delivered_at is not set.
  #
  # @return [Integer, nil] number of days in transit or nil
  def transit_duration
    return nil unless shipped_at && delivered_at

    (delivered_at.to_date - shipped_at.to_date).to_i
  end
end
