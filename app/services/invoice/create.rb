# frozen_string_literal: true

# Service object for creating invoices (debit or credit notes).
# Handles the business logic of invoice creation including:
# - Generating unique invoice numbers
# - Updating order status
# - Logging audit events
#
# @example Creating a regular invoice
#   invoice = Invoice::Create.new(order).call
#
# @example Creating a credit note (refund)
#   credit_note = Invoice::Create.new(order, type: :credit).call
#
class Invoice::Create < Service::Base
  # Initializes the service.
  #
  # @param order [Order] the order to invoice
  # @param type [Symbol] :debit for regular invoice, :credit for credit note
  # Creates the invoice.
  # For debit invoices, fails if order already has an invoice.
  # For credit notes, always creates a new invoice.
  #
  # @return [Invoice, nil] the created invoice or nil if creation failed
  def call
    @type = @type.to_sym
    # Don't create duplicate debit invoices
    return nil if !credit? && @order.invoice.present?

    invoice = build_invoice
    return nil unless invoice.save

    update_order_status
    log_event(invoice)

    invoice
  end

  private

  # Builds the invoice record with default values.
  # @return [Invoice] unsaved invoice instance
  def build_invoice
    Invoice.new(
      order: @order,
      number: generate_invoice_number,
      status: "draft",
      amount: @order.total_amount || 0,
      tax_amount: 0
    )
  end

  # Generates a unique invoice number.
  # Format: PREFIX-YYYYMMDD-RANDOMHEX
  # - CN prefix for credit notes
  # - INV prefix for regular invoices
  #
  # @return [String] the generated invoice number
  def generate_invoice_number
    prefix = credit? ? "CN" : "INV"
    "#{prefix}-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  # Updates the order status based on invoice type.
  # - Credit note: marks order as cancelled
  # - Regular invoice: marks order as invoiced
  def update_order_status
    new_status = credit? ? "cancelled" : "invoiced"
    @order.update!(status: new_status)
  end

  # Logs an audit event for the invoice creation.
  # @param invoice [Invoice] the created invoice
  def log_event(invoice)
    AccountEvent.log(
      account: @order.account,
      record: invoice,
      event_type: "invoice.#{@type}.created"
    )
  end

  # Checks if this is a credit note.
  # @return [Boolean] true if creating a credit note
  def credit?
    @type == :credit
  end
end
