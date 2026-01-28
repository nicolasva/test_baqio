# frozen_string_literal: true

# Service object for cancelling orders.
# Handles the business logic of order cancellation including:
# - Validating cancellation is allowed
# - Updating order status
# - Logging audit events
#
# @example Cancelling an order
#   result = Order::Cancellation.new(order).call
#   if result
#     puts "Order cancelled successfully"
#   else
#     puts "Cannot cancel this order"
#   end
#
class Order::Cancellation < Service::Base 
  # @return [Order] the order to cancel

  # Initializes the service.
  #
  # @param order [Order] the order to cancel

  # Cancels the order.
  # Wraps the operation in a transaction to ensure data consistency.
  #
  # @return [Boolean] true if cancellation succeeded, false otherwise
  def call
    # Cannot cancel an already cancelled order
    return false if @order.cancelled?

    ActiveRecord::Base.transaction do
      @order.update!(status: "cancelled")
      log_event
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  # Logs an audit event for the cancellation.
  def log_event
    AccountEvent.log(
      account: @order.account,
      record: @order,
      event_type: "order.cancelled"
    )
  end
end
