# frozen_string_literal: true

# Referenceable concern provides automatic reference/number generation.
# Generates unique identifiers with a prefix, date, and random suffix.
#
# @example Including in a model
#   class Order < ApplicationRecord
#     include Referenceable
#     generates_reference :reference, prefix: "ORD"
#   end
#
# @example Generated references
#   order.reference  # => "ORD-20240115-A1B2C3D4"
#   invoice.number   # => "INV-20240115-E5F6G7H8"
#
module Referenceable
  extend ActiveSupport::Concern

  class_methods do
    # Configures automatic reference generation for an attribute.
    # The reference is generated on create if the attribute is blank.
    #
    # Format: PREFIX-YYYYMMDD-RANDOM
    # - PREFIX: The provided prefix (e.g., "ORD", "INV")
    # - YYYYMMDD: Current date
    # - RANDOM: 8 random hexadecimal characters (uppercase)
    #
    # @param attribute [Symbol] the attribute to store the reference in
    # @param prefix [String] the prefix to use (e.g., "ORD" for orders)
    #
    # @example
    #   generates_reference :reference, prefix: "ORD"
    #   # Generates: "ORD-20240115-A1B2C3D4"
    #
    #   generates_reference :number, prefix: "INV"
    #   # Generates: "INV-20240115-E5F6G7H8"
    #
    def generates_reference(attribute, prefix:)
      # Run generation before validation, only on create, only if blank
      before_validation :"generate_#{attribute}", on: :create, if: -> { send(attribute).blank? }

      # Define the generation method
      define_method(:"generate_#{attribute}") do
        # Build reference: PREFIX-YYYYMMDD-RANDOMHEX
        self.send(:"#{attribute}=", "#{prefix}-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}")
      end

      # Make the generation method private
      private :"generate_#{attribute}"
    end
  end
end
