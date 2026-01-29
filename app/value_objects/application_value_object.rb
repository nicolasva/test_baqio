# frozen_string_literal: true

# Base class for value objects providing common equality and predicate behavior.
#
# Subclasses declare their identity attributes via `value_attributes`,
# which generates `==`, `eql?`, and `hash` based on those attributes.
#
# By default, `present?` and `blank?` are also generated (true if any
# attribute is present). Subclasses can opt out with `skip_presence: true`.
#
# @example Basic usage
#   class PersonName < ApplicationValueObject
#     value_attributes :first_name, :last_name
#   end
#
# @example Skipping presence methods
#   class Money < ApplicationValueObject
#     value_attributes :amount, :currency, skip_presence: true
#   end
#
class ApplicationValueObject
  class << self
    # Declares the attributes that define this value object's identity.
    # Generates `==`, `eql?`, and `hash` based on these attributes.
    # Optionally generates `present?` and `blank?`.
    #
    # @param attrs [Array<Symbol>] attribute names
    # @param skip_presence [Boolean] if true, does not define present?/blank?
    def value_attributes(*attrs, skip_presence: false)
      @_value_attrs = attrs.freeze

      define_method(:_value_attributes) { attrs }
      private :_value_attributes

      define_method(:==) do |other|
        other.is_a?(self.class) &&
          attrs.all? { |attr| send(attr) == other.send(attr) }
      end

      alias_method :eql?, :==

      define_method(:hash) do
        attrs.map { |attr| send(attr) }.hash
      end

      return if skip_presence

      define_method(:present?) do
        attrs.any? { |attr| send(attr).present? }
      end

      define_method(:blank?) do
        !present?
      end
    end
  end
end
