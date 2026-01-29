# frozen_string_literal: true

# Decorator for Order model presentation logic.
# Provides formatted display values and status presentation for views.
#
# @example Using the decorator
#   order = Order.find(1).decorate
#   order.status_name       # => "Pending"
#   order.status_badge      # => "badge-warning"
#   order.lines_summary     # => "3 items"
#   order.total_price       # => "$150.00"
#
class OrderDecorator < ApplicationDecorator
  # Delegate all model methods to the underlying order
  delegate_all

  # ============================================
  # Status Configuration
  # ============================================

  # Define status presentation (name and badge class for each status)
  has_status_presentation(
    pending: { name: "Pending", badge: "badge-warning" },
    invoiced: { name: "Invoiced", badge: "badge-info" },
    validated: { name: "Validated", badge: "badge-success" },
    cancelled: { name: "Cancelled", badge: "badge-danger" }
  )

  # ============================================
  # Formatting Configuration
  # ============================================

  # Format total_amount as currency (creates total_amount_formatted method)
  formats_currency :total_amount

  # Create lines_summary method that returns "X item(s)"
  pluralizes_count :lines_count, singular: "item", plural: "items", method_name: :lines_summary

  # ============================================
  # Customer Methods
  # ============================================

  # Returns the customer's display name.
  # Decorates the customer to get proper display name.
  #
  # @return [String, nil] customer name or nil
  def customer_name
    customer&.decorate&.display_name
  end

  # ============================================
  # Fulfillment Methods
  # ============================================

  # Returns the fulfillment status name.
  #
  # @return [String, nil] fulfillment status or nil if no fulfillment
  def fulfillment_status
    return nil unless fulfillment

    fulfillment.decorate.status_name
  end

  # Returns the fulfillment service name.
  #
  # @return [String, nil] service name or nil if no fulfillment
  def fulfillment_service_name
    return nil unless fulfillment

    fulfillment.decorate.service_name
  end

  # ============================================
  # Totals Methods
  # ============================================

  # Returns the total quantity of all items in the order.
  #
  # @return [Integer] sum of all line quantities
  def total_quantity
    order_lines.sum(:quantity)
  end

  # Returns the formatted total price.
  # Alias for total_amount_formatted for convenience.
  #
  # @return [String] formatted total price
  def total_price
    total_amount_formatted
  end

  # Returns the raw total amount (unformatted).
  # Returns 0 if total_amount is nil.
  #
  # @return [Float] total amount
  def total_price_raw
    object.total_amount || 0
  end

  # ============================================
  # Link Helpers
  # ============================================

  # Returns a link to the order detail page.
  #
  # @return [String] HTML link to order
  def reference_link
    h.link_to(reference, h.order_path(object))
  end
end
