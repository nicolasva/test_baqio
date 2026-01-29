# frozen_string_literal: true

# Account model representing a business account in the system.
# An account is the top-level entity that owns customers, orders, and other resources.
# Multiple users can belong to a single account (multi-tenant architecture).
#
# @example Creating an account
#   account = Account.create!(name: "My Shop")
#
# @example Getting total revenue
#   account.total_revenue # => 15000.0
#
class Account < ApplicationRecord
  include InvoiceAggregatable

  # ============================================
  # Associations
  # ============================================

  # Events that occurred on this account (audit trail)
  has_many :account_events, dependent: :destroy

  # Customers belonging to this account
  has_many :customers, dependent: :destroy

  # Orders placed within this account
  has_many :orders, dependent: :destroy

  # Fulfillment services configured for this account (shipping providers)
  has_many :fulfillment_services, dependent: :destroy

  # All invoices through orders (for revenue calculations)
  has_many :invoices, through: :orders

  # ============================================
  # Validations
  # ============================================

  # Every account must have a name
  validates :name, presence: true

  # ============================================
  # Scopes
  # ============================================

  # Search accounts by name (case-insensitive partial match)
  # @param name [String] the search term
  # @return [ActiveRecord::Relation] matching accounts
  scope :by_name, ->(name) { where("name LIKE ?", "%#{name}%") }

  # ============================================
  # Instance Methods
  # ============================================

  # Returns all orders that have not been cancelled.
  # Useful for displaying active business activity.
  #
  # @return [ActiveRecord::Relation] non-cancelled orders
  def active_orders
    orders.where.not(status: "cancelled")
  end

  # Calculates the total revenue from all paid invoices.
  # Only includes invoices with status "paid".
  #
  # @return [Float] total revenue amount
  alias_method :total_revenue, :total_paid_amount
end
