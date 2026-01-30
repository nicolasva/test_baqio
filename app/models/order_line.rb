# frozen_string_literal: true

# OrderLine model representing a line item in an order.
# Each line has a product name, quantity, and price.
# The total price is automatically calculated from quantity * unit_price.
#
# @example Adding items to an order
#   order.order_lines.create!(
#     name: "Blue T-shirt",
#     quantity: 2,
#     unit_price: 29.99,
#     sku: "TSHIRT-BLUE-M"
#   )
#
# @example Adjusting quantities
#   line.increase_quantity(3)  # Add 3 more items
#   line.decrease_quantity(1)  # Remove 1 item
#
class OrderLine < ApplicationRecord
  include Trackable       # Tracks changes to specified fields

  # Track changes to unit_price for audit trail
  tracks :unit_price

  # ============================================
  # Associations
  # ============================================

  # The order this line belongs to
  belongs_to :order

  # ============================================
  # Validations
  # ============================================

  # Product name is required
  validates :name, presence: true

  # Quantity must be a positive integer
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Unit price must be non-negative
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # ============================================
  # Callbacks
  # ============================================

  # Calculate total price before saving
  before_validation :calculate_total_price

  # Update order total when total_price changes or line is destroyed
  after_save :update_order_total, if: :saved_change_to_total_price?
  after_destroy :update_order_total

  # ============================================
  # Scopes
  # ============================================

  # Find lines by SKU code
  # @param sku [String] the SKU to search for
  scope :by_sku, ->(sku) { where(sku: sku) }

  # Order by most expensive items first
  scope :expensive_first, -> { order(total_price: :desc) }

  # ============================================
  # Delegations
  # ============================================

  # Access account through order
  delegate :account, to: :order

  # ============================================
  # Instance Methods
  # ============================================

  # Increases the quantity by a specified amount.
  #
  # @param amount [Integer] amount to add (default: 1)
  # @return [Boolean] true if update succeeded
  def increase_quantity(amount = 1)
    update!(quantity: quantity + amount)
  end

  # Decreases the quantity by a specified amount.
  # If quantity would become zero or negative, destroys the line instead.
  #
  # @param amount [Integer] amount to subtract (default: 1)
  # @return [Boolean] true if update/destroy succeeded
  def decrease_quantity(amount = 1)
    new_quantity = quantity - amount
    return destroy! if new_quantity <= 0

    update!(quantity: new_quantity)
  end

  private

  # Calculates the total price from quantity and unit price.
  # Called before validation.
  def calculate_total_price
    self.total_price = (quantity || 0) * (unit_price || 0)
  end

  # Updates the parent order's total amount.
  # Called after save and destroy.
  def update_order_total
    order&.update_total!
  end
end
