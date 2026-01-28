# frozen_string_literal: true

# FulfillmentService model representing a shipping/delivery provider.
# Each account can have multiple fulfillment services (e.g., DHL, UPS, local delivery).
# Fulfillments are created through these services.
#
# @example Creating a fulfillment service
#   service = FulfillmentService.create!(
#     account: account,
#     name: "DHL Express",
#     active: true
#   )
#
# @example Creating a fulfillment
#   fulfillment = service.fulfillments.create!(status: "pending")
#
class FulfillmentService < ApplicationRecord
  # ============================================
  # Associations
  # ============================================

  # The account this service belongs to
  belongs_to :account

  # Fulfillments (shipments) created through this service
  has_many :fulfillments, dependent: :destroy

  # ============================================
  # Validations
  # ============================================

  # Name is required
  validates :name, presence: true

  # Name must be unique within the account
  validates :name, uniqueness: { scope: :account_id }

  # ============================================
  # Scopes
  # ============================================

  # Services that are currently active
  scope :active, -> { where(active: true) }

  # Services that are currently inactive
  scope :inactive, -> { where(active: false) }

  # ============================================
  # Instance Methods
  # ============================================

  # Activates the fulfillment service.
  # Active services can be used to create new fulfillments.
  #
  # @return [Boolean] true if activation succeeded
  def activate!
    update!(active: true)
  end

  # Deactivates the fulfillment service.
  # Inactive services cannot be used for new fulfillments.
  #
  # @return [Boolean] true if deactivation succeeded
  def deactivate!
    update!(active: false)
  end

  # Returns the number of fulfillments for this service.
  #
  # @return [Integer] fulfillment count
  def fulfillments_count
    fulfillments.count
  end
end
