# frozen_string_literal: true

# Statusable concern provides status management functionality to models.
# Automatically creates scopes and predicate methods for each status.
#
# @example Including in a model
#   class Order < ApplicationRecord
#     include Statusable
#     has_statuses :pending, :validated, :invoiced, :cancelled
#   end
#
# @example Using status methods
#   order.pending?                    # => true/false
#   order.validated?                  # => true/false
#   Order.pending                     # => ActiveRecord::Relation
#   Order.with_status(:pending)       # => ActiveRecord::Relation
#   Order.without_status(:cancelled)  # => ActiveRecord::Relation
#
module Statusable
  extend ActiveSupport::Concern

  class_methods do
    # Defines valid statuses for the model.
    # Creates:
    # - A STATUSES constant with all valid status values
    # - Validation ensuring status is one of the defined values
    # - A scope for each status (e.g., Order.pending)
    # - A predicate method for each status (e.g., order.pending?)
    # - with_status and without_status scopes for flexible filtering
    #
    # @param statuses [Array<Symbol>] the valid status values
    def has_statuses(*statuses)
      # Convert all statuses to strings and freeze the array
      statuses = statuses.map(&:to_s).freeze

      # Define the STATUSES constant if not already defined
      const_set(:STATUSES, statuses) unless const_defined?(:STATUSES)

      # Add validation: status must be present and one of the defined values
      validates :status, presence: true, inclusion: { in: statuses }

      # Create scope and predicate method for each status
      statuses.each do |status|
        # Scope: Order.pending returns orders with status "pending"
        scope status.to_sym, -> { where(status: status) }

        # Predicate: order.pending? returns true if status is "pending"
        define_method(:"#{status}?") do
          self.status == status
        end
      end

      # Generic scope to filter by any status
      # @example Order.with_status(:pending)
      scope :with_status, ->(status) { where(status: status) }

      # Generic scope to exclude a status
      # @example Order.without_status(:cancelled)
      scope :without_status, ->(status) { where.not(status: status) }
    end
  end
end
