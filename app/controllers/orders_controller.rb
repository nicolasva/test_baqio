# frozen_string_literal: true

# Controller for managing orders in the application.
# Handles order listing with pagination and eager loading
# of associated records for optimal performance.
#
# @example Routes
#   GET /orders       -> OrdersController#index
#   GET /orders/:id   -> OrdersController#show (not yet implemented)
#
class OrdersController < ApplicationController
  # Lists all orders with pagination.
  # Eager loads customer and fulfillment associations to avoid N+1 queries.
  # Decorates orders for presentation in views.
  #
  # @return [void] renders orders/index view
  #
  # @example Request
  #   GET /orders?page=2
  #
  def index
    # Eager load associations to prevent N+1 queries:
    # - customer: for displaying customer name
    # - fulfillment -> fulfillment_service: for shipping info
    orders = Order.includes(:customer, fulfillment: :fulfillment_service)
                  .page(params[:page])
                  .per(50)

    respond_to do |format|
      format.html do
        # Decorate collection for presentation logic
        # PaginatingDecorator preserves Kaminari pagination methods
        render :index, locals: {
          orders: OrderDecorator.decorate_collection(orders)
        }
      end
    end
  end
end
