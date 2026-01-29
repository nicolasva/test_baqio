# frozen_string_literal: true

# Concern for filtering ActiveRecord relations by date range.
# Extracts the common from_date/to_date filtering pattern used
# across multiple query objects.
#
# @example Including in a query
#   class Orders::FilterQuery < ApplicationQuery
#     include DateFilterable
#
#     def call
#       result = relation
#       result = filter_by_date_range(result, table_name: "orders", from: @filters[:from_date], to: @filters[:to_date])
#       result
#     end
#   end
#
module DateFilterable
  extend ActiveSupport::Concern

  private

  # Filters a relation by date range on created_at.
  #
  # @param rel [ActiveRecord::Relation] the relation to filter
  # @param table_name [String] the table name to qualify the column
  # @param from [Date, Time, nil] start date (inclusive)
  # @param to [Date, Time, nil] end date (inclusive, uses end_of_day)
  # @return [ActiveRecord::Relation] filtered relation
  def filter_by_date_range(rel, table_name:, from:, to:)
    rel = rel.where("#{table_name}.created_at >= ?", from) if from.present?
    rel = rel.where("#{table_name}.created_at <= ?", to.end_of_day) if to.present?
    rel
  end
end
