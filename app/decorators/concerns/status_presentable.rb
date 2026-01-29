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

  class_methods do
    # Configures status presentation for the decorator.
    # Creates constants STATUS_NAMES and STATUS_BADGES, and defines
    # instance methods for displaying status information.
    #
    # @param statuses_config [Hash<Symbol, Hash>] configuration hash where:
    #   - Keys are status symbols (e.g., :pending, :validated)
    #   - Values are hashes with :name (display string) and :badge (CSS class)
    #
    # @example Basic usage
    #   has_status_presentation(
    #     pending: { name: "Pending", badge: "badge-warning" },
    #     cancelled: { name: "Cancelled", badge: "badge-danger" }
    #   )
    #
    # @return [void]
    def has_status_presentation(statuses_config)
      # Build lookup hashes from configuration
      status_names = {}
      status_badges = {}

      statuses_config.each do |status, config|
        status_key = status.to_s
        status_names[status_key] = config[:name]
        status_badges[status_key] = config[:badge]
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
