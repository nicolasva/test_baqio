# frozen_string_literal: true

# Concern for query objects that categorize records into groups
# and need to collect all IDs across groups.
#
# Provides a DSL `has_groups` that generates:
# - `grouped` method returning a Hash of group_name => records
# - `all_ids` method collecting all plucked IDs from groups, flattened and unique
#
# @example Including in a query
#   class Orders::NeedingAttentionQuery < ApplicationQuery
#     include GroupedQuery
#
#     has_groups(
#       pending_too_long: :pending_too_long,
#       validated_not_invoiced: :validated_not_invoiced
#     )
#
#     def call
#       relation.where(id: all_ids)
#     end
#   end
#
module GroupedQuery
  extend ActiveSupport::Concern

  class_methods do
    # Declares the groups for this query.
    # Each key is a group name, each value is the method that returns the relation for that group.
    #
    # @param groups [Hash{Symbol => Symbol}] mapping of group_name to method_name
    def has_groups(groups)
      define_method(:_group_definitions) { groups }
      private :_group_definitions
    end
  end

  # Returns records grouped by category.
  #
  # @return [Hash{Symbol => ActiveRecord::Relation}] records by group
  def grouped
    _group_definitions.transform_values { |method_name| send(method_name) }
  end

  # Collects all unique IDs across all groups.
  #
  # @return [Array<Integer>] unique IDs from all groups
  def all_ids
    _group_definitions.values.flat_map { |method_name| send(method_name).pluck(:id) }.uniq
  end
end
