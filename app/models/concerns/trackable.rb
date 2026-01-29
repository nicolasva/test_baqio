# frozen_string_literal: true

# Trackable concern for automatic field change tracking.
# Logs changes to specified fields as AccountEvent records.
#
# @example Tracking order status changes
#   class Order < ApplicationRecord
#     include Trackable
#     tracks :total_amount, :status
#   end
#
# @example Generated event
#   {
#     event_type: "order.status.changed",
#     payload: { field: "status", old_value: "pending", new_value: "validated" }
#   }
#
module Trackable
  extend ActiveSupport::Concern

  included do
    class_attribute :tracked_fields, default: []

    before_update :capture_tracked_changes
    after_update :log_tracked_changes
  end

  class_methods do
    # Declares which fields should be tracked for changes.
    #
    # @param fields [Array<Symbol>] the field names to track
    def tracks(*fields)
      self.tracked_fields = fields.map(&:to_s)
    end
  end

  private

  # Captures changes to tracked fields before the update is saved.
  # Stores old and new values for fields that have changed.
  def capture_tracked_changes
    @tracked_changes = {}
    tracked_fields.each do |field|
      if send("#{field}_changed?")
        @tracked_changes[field] = {
          old_value: send("#{field}_was"),
          new_value: send(field)
        }
      end
    end
  end

  # Logs captured changes as AccountEvent records after the update is saved.
  # Creates one event per changed field.
  def log_tracked_changes
    return if @tracked_changes.blank?

    @tracked_changes.each do |field, values|
      AccountEvent.log(
        account: account,
        record: self,
        event_type: "#{self.class.name.underscore}.#{field}.changed",
        payload: {
          field: field,
          old_value: values[:old_value],
          new_value: values[:new_value]
        }
      )
    end
  end
end
