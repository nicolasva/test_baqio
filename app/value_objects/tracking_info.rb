# frozen_string_literal: true

# Value object representing shipment tracking information.
# Encapsulates tracking number and carrier with URL generation
# for major shipping carriers.
#
# Immutable and normalizes input (uppercase, trimmed).
#
# @example Creating tracking info
#   tracking = TrackingInfo.new(number: "1Z999AA10123456784", carrier: "UPS")
#   tracking.tracking_url  # => "https://www.ups.com/track?tracknum=1Z999AA10123456784"
#   tracking.to_s          # => "UPS - 1Z999AA10123456784"
#
# @example Empty tracking
#   TrackingInfo.empty.blank?  # => true
#
class TrackingInfo
  # @return [String, nil] the tracking number (uppercase)
  attr_reader :number
  # @return [String, nil] the carrier name (uppercase)
  attr_reader :carrier

  # URL templates for major shipping carriers.
  # Use %s as placeholder for tracking number.
  CARRIER_URLS = {
    "UPS" => "https://www.ups.com/track?tracknum=%s",
    "FEDEX" => "https://www.fedex.com/fedextrack/?trknbr=%s",
    "DHL" => "https://www.dhl.com/en/express/tracking.html?AWB=%s",
    "COLISSIMO" => "https://www.laposte.fr/outils/suivre-vos-envois?code=%s",
    "CHRONOPOST" => "https://www.chronopost.fr/tracking-no-cms/suivi-page?listeNumerosLT=%s",
    "TNT" => "https://www.tnt.com/express/en_gc/site/shipping-tools/tracking.html?searchType=CON&cons=%s",
    "GLS" => "https://gls-group.eu/track/%s"
  }.freeze

  # Creates a new TrackingInfo instance.
  #
  # @param number [String, nil] the tracking number
  # @param carrier [String, nil] the carrier name
  def initialize(number:, carrier: nil)
    @number = normalize_number(number)
    @carrier = normalize_carrier(carrier)
    freeze
  end

  # ============================================
  # Equality
  # ============================================

  # Checks equality based on number and carrier.
  #
  # @param other [TrackingInfo] the tracking info to compare
  # @return [Boolean] true if equal
  def ==(other)
    other.is_a?(TrackingInfo) &&
      number == other.number &&
      carrier == other.carrier
  end
  alias eql? ==

  # Hash code for use in hash tables.
  #
  # @return [Integer] hash code
  def hash
    [ number, carrier ].hash
  end

  # ============================================
  # Predicates
  # ============================================

  # Checks if tracking number is present.
  #
  # @return [Boolean] true if has tracking number
  def present?
    number.present?
  end

  # Checks if tracking number is blank.
  #
  # @return [Boolean] true if no tracking number
  def blank?
    !present?
  end

  # ============================================
  # URL Generation
  # ============================================

  # Generates tracking URL for known carriers.
  # Returns nil if carrier is unknown or tracking is blank.
  #
  # @return [String, nil] tracking URL or nil
  def tracking_url
    return nil unless present? && carrier.present?

    url_template = CARRIER_URLS[carrier]
    return nil unless url_template

    format(url_template, number)
  end

  # ============================================
  # Formatting
  # ============================================

  # Returns string representation.
  # Format: "CARRIER - NUMBER" or just "NUMBER" if no carrier.
  #
  # @return [String] formatted tracking info
  def to_s
    return "" if blank?
    return number if carrier.blank?

    "#{carrier} - #{number}"
  end

  # ============================================
  # Class Methods
  # ============================================

  # Creates an empty tracking info object.
  #
  # @return [TrackingInfo] empty tracking info
  def self.empty
    new(number: nil, carrier: nil)
  end

  private

  # Normalizes tracking number (uppercase, trimmed).
  def normalize_number(value)
    value.to_s.strip.upcase.presence&.freeze
  end

  # Normalizes carrier name (uppercase, trimmed).
  def normalize_carrier(value)
    value.to_s.strip.upcase.presence&.freeze
  end
end
