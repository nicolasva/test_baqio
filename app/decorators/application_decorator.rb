# frozen_string_literal: true

# Base decorator class that all decorators inherit from.
# Provides common functionality for presentation logic:
# - Status presentation (badges, human-readable names)
# - Date and currency formatting
# - Pluralization helpers
#
# Uses Draper gem for decorator functionality.
#
# @example Creating a decorator
#   class OrderDecorator < ApplicationDecorator
#     delegate_all
#     formats_currency :total_amount
#   end
#
# @example Using a decorator
#   decorated = order.decorate
#   decorated.total_amount_formatted  # => "$150.00"
#
class ApplicationDecorator < Draper::Decorator
  # Include shared presentation modules
  include StatusPresentable      # Provides status_name and status_badge methods
  include FormattingHelpers      # Provides date and currency formatting
  include PluralizationHelpers   # Provides count text methods (e.g., "3 items")

  # Delegate all methods to the underlying model
  delegate_all

  # Format timestamps with the long format by default
  formats_date :created_at, :updated_at, format: :long

  # Use PaginatingDecorator for collections to support Kaminari pagination.
  # @return [Class] the collection decorator class
  def self.collection_decorator_class
    PaginatingDecorator
  end
end

# Collection decorator that preserves Kaminari pagination methods.
# Allows decorated collections to still work with pagination helpers.
#
# @example Using with pagination
#   @orders = Order.page(params[:page]).decorate
#   @orders.current_page  # => 1
#   @orders.total_pages   # => 5
#
class PaginatingDecorator < Draper::CollectionDecorator
  # Delegate Kaminari pagination methods to the underlying collection
  delegate :current_page, :total_pages, :limit_value, :total_count,
           :offset_value, :last_page?, :first_page?, :out_of_range?
end
