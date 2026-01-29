# frozen_string_literal: true

# AccountEvent model for tracking audit events within an account.
# Provides an audit trail of important actions (order cancellations, invoice creation, etc.).
# Events are linked to both an account and a resource (the affected record).
#
# @example Logging an event
#   AccountEvent.log(
#     account: order.account,
#     record: order,
#     event_type: "order.cancelled",
#     payload: { reason: "Customer request" }
#   )
#
# @example Querying events
#   AccountEvent.by_type("order.cancelled").today
#
class AccountEvent < ApplicationRecord
  # ============================================
  # Associations
  # ============================================

  # The account where this event occurred
  belongs_to :account

  # The resource (record) that was affected by this event
  belongs_to :resource

  # ============================================
  # Validations
  # ============================================

  # Event type is required (e.g., "order.cancelled", "invoice.created")
  validates :event_type, presence: true

  # ============================================
  # Scopes
  # ============================================

  # Filter events by type
  # @param type [String] the event type to filter by
  scope :by_type, ->(type) { where(event_type: type) }

  # Order by most recent first
  scope :recent, -> { order(created_at: :desc) }

  # Events that occurred today
  scope :today, -> { where(created_at: Time.current.all_day) }

  # Events that occurred this week
  scope :this_week, -> { where(created_at: Time.current.all_week) }

  # ============================================
  # Instance Methods
  # ============================================

  # Parses the JSON payload and returns it as a hash with symbol keys.
  # Returns an empty hash if payload is blank or invalid JSON.
  #
  # @return [Hash] parsed payload data
  def parsed_payload
    return {} if payload.blank?

    JSON.parse(payload, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

  # ============================================
  # Class Methods
  # ============================================

  # Creates a new event for a record.
  # Automatically creates or finds the associated resource.
  #
  # @param account [Account] the account where the event occurred
  # @param record [ApplicationRecord] the affected record
  # @param event_type [String] the type of event (e.g., "order.cancelled")
  # @param payload [Hash, nil] optional additional data to store
  # @return [AccountEvent] the created event
  def self.log(account:, record:, event_type:, payload: nil)
    create!(
      account: account,
      resource: Resource.for(record),
      event_type: event_type,
      payload: payload&.to_json
    )
  end
end
