# frozen_string_literal: true

# Resource model representing a reference to another record in the system.
# Used by AccountEvent to track which record an event relates to.
# This allows for a polymorphic-like association without direct foreign keys.
#
# @example Creating a resource reference
#   resource = Resource.for(order)  # Creates "Order#123"
#
# @example Querying by resource type
#   Resource.orders  # All order resources
#
class Resource < ApplicationRecord
  # ============================================
  # Constants
  # ============================================

  # Valid resource types that can be tracked
  RESOURCE_TYPES = %w[Order Invoice Customer Fulfillment OrderLine].freeze

  # ============================================
  # Associations
  # ============================================

  # Events associated with this resource
  has_many :account_events, dependent: :destroy

  # ============================================
  # Validations
  # ============================================

  # Name is required (format: "ClassName#ID")
  validates :name, presence: true

  # Resource type must be one of the allowed types
  validates :resource_type, presence: true, inclusion: { in: RESOURCE_TYPES }

  # ============================================
  # Scopes
  # ============================================

  # Filter by resource type
  # @param type [String] the resource type
  scope :by_type, ->(type) { where(resource_type: type) }

  # Resources for orders
  scope :orders, -> { by_type("Order") }

  # Resources for invoices
  scope :invoices, -> { by_type("Invoice") }

  # Resources for customers
  scope :customers, -> { by_type("Customer") }

  # Resources for fulfillments
  scope :fulfillments, -> { by_type("Fulfillment") }

  # ============================================
  # Class Methods
  # ============================================

  # Finds or creates a resource reference for a given record.
  # Creates a unique identifier based on class name and ID.
  #
  # @param record [ApplicationRecord] the record to create a reference for
  # @return [Resource] the found or created resource
  def self.for(record)
    find_or_create_by!(
      name: "#{record.class.name}##{record.id}",
      resource_type: record.class.name
    )
  end
end
