# frozen_string_literal: true

# Concern for converting period symbols to date ranges.
# Extracts the common period-to-date-range conversion logic
# used across dashboard, revenue, and top spenders queries.
#
# @example Including in a query
#   class Orders::DashboardQuery < ApplicationQuery
#     include PeriodFilterable
#
#     def call
#       relation.where(created_at: resolve_period(:this_month))
#     end
#   end
#
module PeriodFilterable
  extend ActiveSupport::Concern

  private

  # Converts a period symbol or Range to a date/time Range.
  #
  # @param period [Symbol, Range] the period to resolve
  #   Supported symbols: :today, :yesterday, :this_week, :last_week,
  #   :this_month, :last_month, :this_quarter, :last_quarter,
  #   :this_year, :last_year
  #   Also accepts a raw Range which is returned as-is.
  # @return [Range] date/time range for the period
  def resolve_period(period)
    case period
    when :today
      Time.current.all_day
    when :yesterday
      1.day.ago.all_day
    when :this_week
      Time.current.all_week
    when :last_week
      1.week.ago.all_week
    when :this_month
      Time.current.all_month
    when :last_month
      1.month.ago.all_month
    when :this_quarter
      Time.current.all_quarter
    when :last_quarter
      1.quarter.ago.all_quarter
    when :this_year
      Time.current.all_year
    when :last_year
      1.year.ago.all_year
    when Range
      period
    else
      Time.current.all_day
    end
  end
end
