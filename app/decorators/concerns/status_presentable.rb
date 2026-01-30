# frozen_string_literal: true

# Concern that provides status presentation helpers for decorators.
# Uses metaprogramming to generate status-related display methods
# based on a configuration hash.
#
# This concern generates three methods for each decorator:
# - status_name: Human-readable status label
# - status_badge: CSS badge class for styling
# - status_with_badge: HTML span with badge styling
#
# @example Including in a decorator
#   class OrderDecorator < ApplicationDecorator
#     include StatusPresentable
#
#     has_status_presentation(
#       pending: { name: "Pending", badge: "badge-warning" },
#       validated: { name: "Validated", badge: "badge-success" },
#       cancelled: { name: "Cancelled", badge: "badge-danger" }
#     )
#   end
#
# @example Using the generated methods
#   order.decorate.status_name       # => "Pending"
#   order.decorate.status_badge      # => "badge-warning"
#   order.decorate.status_with_badge # => "<span class='badge badge-warning'>Pending</span>"
#
module StatusPresentable
  extend ActiveSupport::Concern

  # Common statuses shared across multiple decorators.
  # Merge into has_status_presentation to avoid repeating them.
  COMMON_STATUSES = {
    cancelled: "badge-danger"
  }.freeze

  class_methods do
    # Configures status presentation for the decorator.
    # Creates constants STATUS_NAMES and STATUS_BADGES, and defines
    # instance methods for displaying status information.
    #
    # Accepts two formats per status:
    # - String: badge class only, name auto-derived via capitalize
    # - Hash: explicit :name and :badge keys
    #
    # @param statuses_config [Hash<Symbol, String|Hash>] configuration hash where:
    #   - Keys are status symbols (e.g., :pending, :validated)
    #   - Values are either a badge class string or a hash with :name and :badge
    #
    # @example Simplified syntax (recommended)
    #   has_status_presentation(
    #     **StatusPresentable::COMMON_STATUSES,
    #     pending: "badge-warning",
    #     validated: "badge-success"
    #   )
    #
    # @example Hash syntax (for custom names)
    #   has_status_presentation(
    #     in_progress: { name: "In Progress", badge: "badge-info" }
    #   )
    #
    # @return [void]
    def has_status_presentation(statuses_config)
      # Build lookup hashes from configuration
      status_names = {}
      status_badges = {}

      statuses_config.each do |status, config|
        status_key = status.to_s
        if config.is_a?(Hash)
          status_names[status_key] = config[:name]
          status_badges[status_key] = config[:badge]
        else
          status_names[status_key] = status_key.capitalize
          status_badges[status_key] = config
        end
      end

      # Store as frozen constants on the decorator class
      const_set(:STATUS_NAMES, status_names.freeze) unless const_defined?(:STATUS_NAMES)
      const_set(:STATUS_BADGES, status_badges.freeze) unless const_defined?(:STATUS_BADGES)

      # Define method to get human-readable status name
      # Falls back to capitalized status string if not configured
      define_method(:status_name) do
        self.class::STATUS_NAMES[status] || status&.capitalize
      end

      # Define method to get CSS badge class for status
      # Falls back to badge-secondary if not configured
      define_method(:status_badge) do
        self.class::STATUS_BADGES[status] || "badge-secondary"
      end

      # Define method to render status as HTML badge
      # Delegates to ApplicationHelper#status_badge_tag
      define_method(:status_with_badge) do
        h.status_badge_tag(status_name, status_badge)
      end
    end
  end
end
