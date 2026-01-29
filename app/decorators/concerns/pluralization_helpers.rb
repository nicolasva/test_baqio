# frozen_string_literal: true

# Concern that provides pluralization helpers for decorators.
# Uses metaprogramming to generate count display methods with proper
# singular/plural word forms.
#
# This concern provides the pluralizes_count DSL method that creates
# methods returning strings like "1 item" or "5 items".
#
# @example Including in a decorator
#   class OrderDecorator < ApplicationDecorator
#     include PluralizationHelpers
#
#     pluralizes_count :lines_count, singular: "item", plural: "items"
#   end
#
# @example Using the generated methods
#   order.decorate.lines_count_text # => "3 items"
#
module PluralizationHelpers
  extend ActiveSupport::Concern

  class_methods do
    # Generates a pluralized count display method.
    # Creates a method that returns "{count} {word}" with correct singular/plural form.
    #
    # @param count_method [Symbol] method name that returns the count value
    # @param singular [String] word to use when count is 1
    # @param plural [String] word to use when count is not 1
    # @param method_name [Symbol, nil] custom name for the generated method
    #   Defaults to {count_method}_text (e.g., lines_count_text)
    #
    # @example Basic usage (auto-generated method name)
    #   pluralizes_count :orders_count, singular: "order", plural: "orders"
    #   # Generates: orders_count_text method
    #   # Returns: "1 order" or "5 orders"
    #
    # @example Custom method name
    #   pluralizes_count :lines_count, singular: "item", plural: "items", method_name: :lines_summary
    #   # Generates: lines_summary method
    #   # Returns: "1 item" or "3 items"
    #
    # @return [void]
    def pluralizes_count(count_method, singular:, plural:, method_name: nil)
      # Default method name is {count_method}_text
      method_name ||= :"#{count_method}_text"

      define_method(method_name) do
        count = send(count_method)
        # Use singular form for count of 1, plural otherwise
        "#{count} #{count == 1 ? singular : plural}"
      end
    end
  end
end
