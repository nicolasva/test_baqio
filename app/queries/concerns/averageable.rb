# frozen_string_literal: true

# Concern for computing safe averages with zero-division protection.
# Extracts the common pattern: return 0 if empty, compute ratio, round.
#
# @example
#   class Orders::DashboardQuery < ApplicationQuery
#     include Averageable
#
#     def average_order_value(orders)
#       safe_average(orders, :total_amount)
#     end
#   end
#
module Averageable
  extend ActiveSupport::Concern

  private

  # Computes a rounded average from a collection.
  #
  # Supports two modes:
  # - With a column name: uses ActiveRecord `.average(:column)`
  # - With a block: computes sum from block / count
  #
  # @param collection [ActiveRecord::Relation, Array] records to average
  # @param column [Symbol, nil] column name for AR `.average`
  # @param precision [Integer] decimal places (default: 2)
  # @yield [record] block returning a numeric value per record (alternative to column)
  # @return [Float] the rounded average, or 0 if collection is empty
  def safe_average(collection, column = nil, precision: 2, &block)
    return 0 if collection.empty?

    if block
      total = collection.sum(&block)
      (total.to_f / collection.count).round(precision)
    else
      collection.average(column).to_f.round(precision)
    end
  end
end
