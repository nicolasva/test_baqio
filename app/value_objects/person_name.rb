# frozen_string_literal: true

# Value object representing a person's name with first and last components.
# Provides various formatting options for display purposes.
#
# Immutable and handles nil/blank values gracefully.
#
# @example Creating a person name
#   name = PersonName.new(first_name: "John", last_name: "Doe")
#   name.full_name      # => "John Doe"
#   name.reversed_name  # => "Doe, John"
#   name.initials       # => "JD"
#
# @example Parsing from string
#   name = PersonName.parse("John Doe")
#   name.first_name  # => "John"
#   name.last_name   # => "Doe"
#
# @example Empty name
#   PersonName.empty.blank?  # => true
#
class PersonName < ApplicationValueObject
  value_attributes :first_name, :last_name

  # @return [String, nil] the first name
  attr_reader :first_name
  # @return [String, nil] the last name
  attr_reader :last_name

  # Creates a new PersonName instance.
  #
  # @param first_name [String, nil] the first/given name
  # @param last_name [String, nil] the last/family name
  def initialize(first_name:, last_name:)
    @first_name = normalize(first_name)
    @last_name = normalize(last_name)
    freeze
  end

  # ============================================
  # Formatting
  # ============================================

  # Returns full name in natural order (First Last).
  #
  # @return [String, nil] full name or nil if blank
  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence
  end

  # Returns full name in reversed order (Last, First).
  # Useful for alphabetical sorting or formal contexts.
  #
  # @return [String, nil] reversed name or nil if blank
  def reversed_name
    [ last_name, first_name ].compact_blank.join(", ").presence
  end

  # Returns initials from the name.
  #
  # @return [String, nil] initials (e.g., "JD") or nil if blank
  def initials
    return nil if blank?

    [ first_name, last_name ]
      .compact_blank
      .map { |name| name[0]&.upcase }
      .join
  end

  # Returns string representation (full name).
  #
  # @return [String] full name or empty string
  def to_s
    full_name || ""
  end

  # ============================================
  # Class Methods
  # ============================================

  # Creates an empty person name object.
  #
  # @return [PersonName] empty name
  def self.empty
    new(first_name: nil, last_name: nil)
  end

  # Parses a full name string into first and last name.
  # Splits on first whitespace: "John Michael Doe" => first: "John", last: "Michael Doe"
  #
  # @param full_name [String, nil] the full name to parse
  # @return [PersonName] parsed name
  def self.parse(full_name)
    return empty if full_name.blank?

    parts = full_name.to_s.strip.split(/\s+/, 2)
    new(first_name: parts[0], last_name: parts[1])
  end

  private

  # Normalizes name component (trimmed, frozen).
  def normalize(value)
    value.to_s.strip.presence&.freeze
  end
end
