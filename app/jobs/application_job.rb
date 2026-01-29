# frozen_string_literal: true

# Base job class that all background jobs inherit from.
# Provides shared configuration for error handling, retries, and queues.
#
# ActiveJob is the Rails abstraction layer for background job processing.
# It can work with various backends (Solid Queue, Sidekiq, Resque, etc.).
#
# @example Creating a job
#   class SendInvoiceEmailJob < ApplicationJob
#     queue_as :mailers
#
#     def perform(invoice_id)
#       invoice = Invoice.find(invoice_id)
#       InvoiceMailer.invoice_email(invoice).deliver_now
#     end
#   end
#
# @example Enqueuing a job
#   SendInvoiceEmailJob.perform_later(invoice.id)
#   SendInvoiceEmailJob.set(wait: 5.minutes).perform_later(invoice.id)
#
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a database deadlock.
  # Deadlocks can occur when multiple transactions compete for locks.
  # retry_on ActiveRecord::Deadlocked

  # Discard jobs when the referenced record no longer exists.
  # Prevents errors when a record is deleted before the job runs.
  # discard_on ActiveJob::DeserializationError
end
