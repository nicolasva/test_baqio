# frozen_string_literal: true

module InvoicesHelper
  # Returns a formatted due status indicator for an invoice.
  # Shows different messages based on due date status:
  # - Overdue: red text with days overdue
  # - Due soon (within 7 days): warning text
  # - Otherwise: muted text with days remaining
  #
  # @param invoice [Invoice] the invoice to check
  # @return [String, nil] HTML span with status or nil if not applicable
  def due_status(invoice)
    return nil unless invoice.due_at && invoice.sent?

    if invoice.overdue?
      content_tag(:span, "Overdue (#{invoice.days_overdue} days)", class: "text-danger")
    elsif invoice.days_until_due <= 7
      content_tag(:span, "Due soon (#{invoice.days_until_due} days)", class: "text-warning")
    else
      content_tag(:span, "#{invoice.days_until_due} days remaining", class: "text-muted")
    end
  end
end
