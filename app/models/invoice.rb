# frozen_string_literal: true

# Invoice model representing a billing document for an order.
# Invoices go through a lifecycle: draft -> sent -> paid -> (cancelled)
# Each invoice is linked to exactly one order.
#
# @example Creating and sending an invoice
#   invoice = Invoice::Create.new(order).call
#   invoice.send_to_customer!
#   invoice.mark_as_paid!
#
# @example Invoice statuses
#   - draft: Invoice created but not sent
#   - sent: Invoice sent to customer, awaiting payment
#   - paid: Payment received
#   - cancelled: Invoice was cancelled
#
class Invoice < ApplicationRecord
  include Statusable      # Provides status management methods
  include Referenceable   # Provides automatic reference generation

  # ============================================
  # Associations
  # ============================================

  # The order this invoice belongs to
  belongs_to :order

  # ============================================
  # Status Configuration
  # ============================================

  # Define valid statuses for invoices
  has_statuses :draft, :sent, :paid, :cancelled

  # Auto-generate invoice number with "INV" prefix (e.g., "INV-20240115-A1B2C3")
  generates_reference :number, prefix: "INV"

  # ============================================
  # Validations
  # ============================================

  # Invoice number must exist and be globally unique
  validates :number, presence: true, uniqueness: true

  # Amount must be present and non-negative
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # ============================================
  # Callbacks
  # ============================================

  # Calculate total amount (amount + tax) before saving
  before_validation :calculate_total_amount

  # ============================================
  # Scopes
  # ============================================

  # Order by most recent first
  scope :recent, -> { order(created_at: :desc) }

  # Invoices that are sent but past due date
  scope :overdue, -> { sent.where("due_at < ?", Date.current) }

  # Invoices that are due within a specified number of days
  # @param days [Integer] number of days to look ahead (default: 7)
  scope :due_soon, ->(days = 7) { sent.where(due_at: Date.current..(Date.current + days.days)) }

  # ============================================
  # Delegations
  # ============================================

  # Delegate account and customer access through order
  delegate :account, :customer, to: :order

  # ============================================
  # Status Transition Methods
  # ============================================

  # Sends the invoice to the customer.
  # Sets the issue date to today and due date to 30 days from now.
  #
  # @return [Boolean] true if sent successfully, false if not in draft status
  def send_to_customer!
    return false unless draft?

    update!(status: "sent", issued_at: Date.current, due_at: Date.current + 30.days)
  end

  # Marks the invoice as paid.
  #
  # @param paid_date [Date] the payment date (default: today)
  # @return [Boolean] true if marked as paid, false if not in sent status
  def mark_as_paid!(paid_date = Date.current)
    return false unless sent?

    update!(status: "paid", paid_at: paid_date)
  end

  # Cancels the invoice.
  # Cannot cancel an already paid invoice.
  #
  # @return [Boolean] true if cancelled, false if already paid
  def cancel!
    return false if paid?

    update!(status: "cancelled")
  end

  # ============================================
  # Due Date Methods
  # ============================================

  # Checks if the invoice is overdue.
  # An invoice is overdue if it's sent and past the due date.
  #
  # @return [Boolean] true if overdue
  def overdue?
    sent? && due_at.present? && due_at < Date.current
  end

  # Returns the number of days until the due date.
  # Returns nil if no due date is set.
  #
  # @return [Integer, nil] days until due or nil
  def days_until_due
    return nil unless due_at

    (due_at - Date.current).to_i
  end

  # Returns the number of days the invoice is overdue.
  # Returns 0 if not overdue.
  #
  # @return [Integer] days overdue
  def days_overdue
    return 0 unless overdue?

    (Date.current - due_at).to_i
  end

  private

  # Calculates the total amount including tax.
  # Called before validation.
  def calculate_total_amount
    self.total_amount = (amount || 0) + (tax_amount || 0)
  end
end
