# frozen_string_literal: true

module OrdersHelper
  # Returns the order reference as a link to the orders page.
  #
  # @param order [Order] the order record
  # @return [String] HTML link with order reference
  def order_reference_link(order)
    link_to(order.reference, orders_path)
  end
end
