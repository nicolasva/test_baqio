# frozen_string_literal: true

# Base mailer class that all application mailers inherit from.
# Provides shared configuration for email sending including
# default sender address and email layout.
#
# @example Creating a mailer
#   class InvoiceMailer < ApplicationMailer
#     def invoice_email(invoice)
#       @invoice = invoice
#       mail(to: invoice.customer_email, subject: "Your Invoice")
#     end
#   end
#
# @example Sending an email
#   InvoiceMailer.invoice_email(@invoice).deliver_later
#   InvoiceMailer.invoice_email(@invoice).deliver_now
#
class ApplicationMailer < ActionMailer::Base
  # Default "From" address for all emails sent by the application.
  # Should be updated to a valid email address in production.
  default from: "from@example.com"

  # Use the mailer layout (app/views/layouts/mailer.html.erb)
  # for all email templates.
  layout "mailer"
end
