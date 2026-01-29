# frozen_string_literal: true

# Value object representing a monetary amount with currency.
# Immutable, comparable, and supports arithmetic operations.
#
# Uses BigDecimal internally for precision with financial calculations.
# All operations return new Money instances (immutable pattern).
#
# @example Creating money objects
#   price = Money.new(100, "EUR")
#   price = Money.new("99.99")         # Uses default EUR currency
#   cents = Money.from_cents(9999)     # Create from cents
#
# @example Arithmetic
#   total = price1 + price2
#   discount = price * 0.1
#   unit_price = total / quantity
#
# @example Comparison
#   price1 > price2           # true/false
#   price.zero?               # Check if zero
#   price.positive?           # Check if positive
#
# @example Formatting
#   price.to_s                # "100.00 EUR"
#   price.formatted_amount    # "100.00"
#
class Money
  include Comparable

  # @return [BigDecimal] the monetary amount
  attr_reader :amount
  # @return [String] the ISO currency code (e.g., "EUR", "USD")
  attr_reader :currency

  # Default currency when none specified
  DEFAULT_CURRENCY = "EUR"

  # Creates a new Money instance.
  #
  # @param amount [Numeric, String, BigDecimal] the monetary amount
  # @param currency [String] the currency code (default: EUR)
  def initialize(amount, currency = DEFAULT_CURRENCY)
    @amount = parse_amount(amount)
    @currency = currency.to_s.upcase.freeze
    freeze
  end

  # ============================================
  # Arithmetic Operations
  # ============================================

  # Adds two money objects. Must have same currency.
  #
  # @param other [Money] the money to add
  # @return [Money] new money with summed amount
  # @raise [ArgumentError] if currencies don't match
  def +(other)
    ensure_same_currency!(other)
    Money.new(amount + other.amount, currency)
  end

  # Subtracts two money objects. Must have same currency.
  #
  # @param other [Money] the money to subtract
  # @return [Money] new money with difference
  # @raise [ArgumentError] if currencies don't match
  def -(other)
    ensure_same_currency!(other)
    Money.new(amount - other.amount, currency)
  end

  # Multiplies money by a scalar value.
  #
  # @param multiplier [Numeric] the multiplier
  # @return [Money] new money with multiplied amount
  def *(multiplier)
    Money.new(amount * BigDecimal(multiplier.to_s), currency)
  end

  # Divides money by a scalar value.
  #
  # @param divisor [Numeric] the divisor
  # @return [Money] new money with divided amount
  # @raise [ZeroDivisionError] if divisor is zero
  def /(divisor)
    raise ZeroDivisionError, "Cannot divide by zero" if divisor.zero?
    Money.new(amount / BigDecimal(divisor.to_s), currency)
  end

  # Returns negated money (unary minus).
  #
  # @return [Money] new money with negated amount
  def -@
    Money.new(-amount, currency)
  end

  # ============================================
  # Comparison
  # ============================================

  # Spaceship operator for Comparable module.
  # Only compares if same currency.
  #
  # @param other [Money] the money to compare
  # @return [Integer, nil] -1, 0, 1, or nil if not comparable
  def <=>(other)
    return nil unless other.is_a?(Money) && currency == other.currency
    amount <=> other.amount
  end

  # Equality check. Both amount and currency must match.
  #
  # @param other [Money] the money to compare
  # @return [Boolean] true if equal
  def ==(other)
    other.is_a?(Money) && amount == other.amount && currency == other.currency
  end
  alias eql? ==

  # Hash code for use in hash tables.
  #
  # @return [Integer] hash code
  def hash
    [ amount, currency ].hash
  end

  # ============================================
  # Predicates
  # ============================================

  # Checks if amount is zero.
  #
  # @return [Boolean] true if zero
  def zero?
    amount.zero?
  end

  # Checks if amount is positive.
  #
  # @return [Boolean] true if positive
  def positive?
    amount.positive?
  end

  # Checks if amount is negative.
  #
  # @return [Boolean] true if negative
  def negative?
    amount.negative?
  end

  # ============================================
  # Formatting
  # ============================================

  # Returns string representation with currency.
  #
  # @return [String] formatted money (e.g., "100.00 EUR")
  def to_s
    "#{formatted_amount} #{currency}"
  end

  # Converts to float (may lose precision).
  #
  # @return [Float] amount as float
  def to_f
    amount.to_f
  end

  # Returns the amount as BigDecimal.
  #
  # @return [BigDecimal] the raw amount
  def to_d
    amount
  end

  # Returns amount formatted with 2 decimal places.
  #
  # @return [String] formatted amount (e.g., "100.00")
  def formatted_amount
    format("%.2f", amount)
  end

  # ============================================
  # Class Methods
  # ============================================

  # Creates a zero money object.
  #
  # @param currency [String] the currency code
  # @return [Money] zero money
  def self.zero(currency = DEFAULT_CURRENCY)
    new(0, currency)
  end

  # Creates money from cents (integer amount).
  #
  # @param cents [Integer] amount in cents
  # @param currency [String] the currency code
  # @return [Money] money object
  def self.from_cents(cents, currency = DEFAULT_CURRENCY)
    new(BigDecimal(cents.to_s) / 100, currency)
  end

  private

  # Converts input to BigDecimal for precise calculations.
  def parse_amount(value)
    case value
    when BigDecimal
      value
    when nil
      BigDecimal("0")
    else
      BigDecimal(value.to_s)
    end
  end

  # Validates that currencies match for arithmetic.
  def ensure_same_currency!(other)
    raise ArgumentError, "Currency mismatch: #{currency} vs #{other.currency}" unless currency == other.currency
  end
end
