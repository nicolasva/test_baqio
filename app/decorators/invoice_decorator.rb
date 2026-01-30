# frozen_string_literal: true

# Decorator for Invoice model presentation logic.
# Provides formatted display values, status presentation, and due date information.
#
# @example Using the decorator
#   invoice = Invoice.find(1).decorate
#   invoice.status_name     # => "Sent"
#   invoice.status_badge    # => "badge-info"
#   invoice.due_status      # => "<span class='text-danger'>Overdue (5 days)</span>"
#   invoice.amount_formatted # => "$100.00"
#
class InvoiceDecorator < ApplicationDecorator
  # Delegate all model methods to the underlying invoice
  delegate_all

  # ============================================
  # Status Configuration
  # ============================================

  # Define status presentation (name and badge class for each status)
  has_status_presentation(
    draft: { name: "Draft", badge: "badge-secondary" },
    sent: { name: "Sent", badge: "badge-info" },
    paid: { name: "Paid", badge: "badge-success" },
    cancelled: { name: "Cancelled", badge: "badge-danger" }
  )

  # ============================================
  # Formatting Configuration
  # ============================================

  # Format dates with short format
  formats_date :issued_at, :due_at, :paid_at, format: :short

  # Format amounts as currency
  formats_currency :amount, :total_amount

  # Format tax_amount with 0 as default
  formats_currency :tax_amount, default: 0

  # ============================================
  # Due Date Methods
  # ============================================

  # Delegates to InvoicesHelper#due_status.
  #
  # @return [String, nil] HTML span with status or nil if not applicable
  def due_status
    h.due_status(object)
  end

  # ============================================
  # Related Data Methods
  # ============================================

  # Returns the customer's display name.
  # Accesses customer through the order relationship.
  #
  # @return [String, nil] customer name or nil
  def customer_name
    decorated_customer&.display_name
  end

  # Returns the order reference number.
  #
  # @return [String, nil] order reference or nil
  def order_reference
    order&.reference
  end

  private

  def decorated_customer
    @decorated_customer ||= order&.customer&.decorate
  end
end
