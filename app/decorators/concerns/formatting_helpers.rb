# frozen_string_literal: true

# Concern that provides date and currency formatting helpers for decorators.
# Uses metaprogramming to generate formatted display methods for model attributes.
#
# This concern provides two DSL methods:
# - formats_date: Creates formatted date/time display methods
# - formats_currency: Creates formatted currency display methods
#
# @example Including in a decorator
#   class InvoiceDecorator < ApplicationDecorator
#     include FormattingHelpers
#
#     formats_date :issued_at, :due_at, format: :short
#     formats_currency :amount, :tax_amount, default: 0
#   end
#
# @example Using the generated methods
#   invoice.decorate.issued_at_formatted # => "Jan 15"
#   invoice.decorate.amount_formatted    # => "$100.00"
#
module FormattingHelpers
  extend ActiveSupport::Concern

  class_methods do
    # Generates formatted date methods for the specified attributes.
    # Creates methods named {attribute}_formatted that return localized date strings.
    #
    # @param attributes [Array<Symbol>] attribute names to create formatters for
    # @param format [Symbol] Rails I18n date format (default: :short)
    #   Common formats: :short, :long, :default
    #
    # @example Single attribute
    #   formats_date :created_at
    #   # Generates: created_at_formatted method
    #
    # @example Multiple attributes with custom format
    #   formats_date :issued_at, :due_at, :paid_at, format: :long
    #   # Generates: issued_at_formatted, due_at_formatted, paid_at_formatted
    #
    # @return [void]
    def formats_date(*attributes, format: :short)
      attributes.each do |attr|
        define_method(:"#{attr}_formatted") do
          value = object.send(attr)
          return nil unless value

          # Use Rails I18n localization helper
          h.l(value, format: format)
        end
      end
    end

    # Generates formatted currency methods for the specified attributes.
    # Creates methods named {attribute}_formatted that return currency strings.
    #
    # @param attributes [Array<Symbol>] attribute names to create formatters for
    # @param default [Numeric, nil] default value to use when attribute is nil
    #
    # @example Basic usage
    #   formats_currency :total_amount
    #   # Generates: total_amount_formatted method
    #
    # @example Multiple attributes with default
    #   formats_currency :amount, :tax_amount, default: 0
    #   # nil values will be formatted as "$0.00"
    #
    # @return [void]
    def formats_currency(*attributes, default: nil)
      attributes.each do |attr|
        define_method(:"#{attr}_formatted") do
          value = object.send(attr)
          # Apply default if value is nil and default is specified
          value = default if value.nil? && !default.nil?
          # Use Rails number_to_currency helper
          h.number_to_currency(value)
        end
      end
    end
  end
end
