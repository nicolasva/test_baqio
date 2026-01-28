# frozen_string_literal: true

# Order model representing a sales order in the system.
# An order goes through a lifecycle: pending -> validated -> invoiced -> (cancelled)
# Orders contain order lines (items) and can be associated with a fulfillment (shipment).
#
# @example Creating and processing an order
#   order = Order.create!(account: account, customer: customer)
#   order.add_line(name: "T-shirt", quantity: 2, unit_price: 25.0)
#   order.validate!
#   order.invoice!
#
# @example Order statuses
#   - pending: Order created but not yet confirmed
#   - validated: Order confirmed and ready for invoicing
#   - invoiced: Invoice has been generated
#   - cancelled: Order was cancelled
#
class Order < ApplicationRecord
  include Statusable      # Provides status management methods
  include Referenceable   # Provides automatic reference generation
  include Trackable       # Tracks changes to specified fields

  # Track changes to these fields for audit trail
  tracks :total_amount, :status

  # ============================================
  # Associations
  # ============================================

  # The account this order belongs to
  belongs_to :account

  # The customer who placed this order
  belongs_to :customer

  # Optional shipment associated with this order
  belongs_to :fulfillment, optional: true

  # Line items in this order
  has_many :order_lines, dependent: :destroy

  # The invoice generated for this order (if any)
  has_one :invoice, dependent: :destroy

  # ============================================
  # Status Configuration
  # ============================================

  # Define valid statuses for orders
  has_statuses :pending, :invoiced, :validated, :cancelled

  # Auto-generate reference with "ORD" prefix (e.g., "ORD-20240115-A1B2C3")
  generates_reference :reference, prefix: "ORD"

  # ============================================
  # Validations
  # ============================================

  # Reference must exist and be unique within the account
  validates :reference, presence: true, uniqueness: { scope: :account_id }

  # ============================================
  # Scopes
  # ============================================

  # Order by most recent first
  scope :recent, -> { order(created_at: :desc) }

  # Only orders that are not cancelled
  scope :active, -> { without_status(:cancelled) }

  # Orders that have an invoice
  scope :with_invoice, -> { joins(:invoice) }

  # Orders that do not have an invoice yet
  scope :without_invoice, -> { left_joins(:invoice).where(invoices: { id: nil }) }

  # ============================================
  # Status Transition Methods
  # ============================================

  # Cancels the order. Behavior depends on current status:
  # - If invoiced: Creates a credit note to refund
  # - If validated: Logs cancellation event
  # - Otherwise: Simply marks as cancelled
  #
  # @return [Boolean] true if cancellation succeeded, false otherwise
  def cancel!
    return false if cancelled?

    case status
    when "invoiced"
      # Create credit note for refund
      Invoice::Create.call(order: self, type: :credit)
    when "validated"
      # Log cancellation event
      Order::Cancellation.call(order: self)
    else
      # Simple status update
      update!(status: "cancelled")
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Validates a pending order, making it ready for invoicing.
  #
  # @return [Boolean] true if validation succeeded, false if not pending
  def validate!
    return false unless pending?

    update!(status: "validated")
  end

  # Creates an invoice for a validated order.
  #
  # @return [Boolean] true if invoice was created, false otherwise
  def invoice!
    return false unless validated?
    return false if invoice.present?

    Invoice::Create.call(order: self, type: :debit)
  end

  # ============================================
  # Line Items Methods
  # ============================================

  # Calculates the total price by summing all order lines.
  #
  # @return [Float] total price
  def calculate_total
    order_lines.sum(:total_price)
  end

  # Recalculates and saves the total amount.
  # Called automatically when order lines change.
  #
  # @return [Boolean] true if update succeeded
  def update_total!
    update!(total_amount: calculate_total)
  end

  # Adds a new line item to the order.
  #
  # @param name [String] product name
  # @param quantity [Integer] quantity ordered
  # @param unit_price [Float] price per unit
  # @param sku [String, nil] optional SKU code
  # @return [OrderLine] the created line
  def add_line(name:, quantity:, unit_price:, sku: nil)
    order_lines.create!(
      name: name,
      quantity: quantity,
      unit_price: unit_price,
      sku: sku
    )
  end

  # Checks if the order has no line items.
  #
  # @return [Boolean] true if order has no lines
  def empty?
    order_lines.none?
  end

  # Returns the number of line items in this order.
  #
  # @return [Integer] number of lines
  def lines_count
    order_lines.size
  end
end
