# frozen_string_literal: true

module Fulfillments
  # Query object for analyzing fulfillment performance metrics.
  # Calculates delivery times, on-time rates, and carrier/service comparisons.
  #
  # @example Get all delivered fulfillments
  #   Fulfillments::PerformanceQuery.call
  #
  # @example Get this month's deliveries
  #   Fulfillments::PerformanceQuery.call(period: :this_month)
  #
  # @example Get comprehensive metrics
  #   query = Fulfillments::PerformanceQuery.new(period: :this_quarter)
  #   query.metrics
  #   # => { total_delivered: 500, average_transit_time: 3.2, on_time_delivery_rate: 95.5, ... }
  #
  # @example Compare carrier performance
  #   query.performance_by_carrier
  #   # => [{ carrier: "UPS", total_deliveries: 200, avg_transit_days: 2.8 }, ...]
  #
  class PerformanceQuery < ApplicationQuery
    include PeriodFilterable
    # Initializes with optional period filter.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param period [Symbol, Range, nil] time period for delivered_at
    #   Symbols: :this_week, :this_month, :this_quarter, :last_month
    #   Or a custom Date/Time Range
    def initialize(relation = default_relation, period: nil)
      super(relation)
      @period = period
    end

    # Returns delivered fulfillments, optionally filtered by period.
    #
    # @return [ActiveRecord::Relation] delivered fulfillments
    def call
      result = relation.delivered
      result = filter_by_period(result) if @period
      result
    end

    # Computes comprehensive performance metrics.
    #
    # @return [Hash] performance statistics
    def metrics
      delivered = call

      {
        total_delivered: delivered.count,
        average_transit_time: average_transit_time(delivered),
        on_time_delivery_rate: on_time_delivery_rate(delivered),
        by_carrier: performance_by_carrier,
        by_service: performance_by_service
      }
    end

    # Calculates average transit time in days.
    #
    # @param fulfillments [ActiveRecord::Relation] fulfillments to analyze
    # @return [Float] average days from shipped to delivered
    def average_transit_time(fulfillments = call)
      transit_times = fulfillments.map(&:transit_duration).compact
      return 0 if transit_times.empty?

      (transit_times.sum.to_f / transit_times.size).round(1)
    end

    # Calculates percentage of deliveries within target days.
    #
    # @param fulfillments [ActiveRecord::Relation] fulfillments to analyze
    # @param target_days [Integer] maximum acceptable transit days
    # @return [Float] percentage of on-time deliveries
    def on_time_delivery_rate(fulfillments = call, target_days: 5)
      return 0 if fulfillments.empty?

      on_time = fulfillments.count { |f| f.transit_duration.to_i <= target_days }
      ((on_time.to_f / fulfillments.count) * 100).round(1)
    end

    # Analyzes performance by shipping carrier.
    # Uses SQLite JULIANDAY for date difference calculation.
    #
    # @return [Array<Hash>] carrier performance data
    def performance_by_carrier
      performance_by_dimension(
        scope: relation.delivered.where.not(carrier: [nil, ""]),
        group_by: :carrier,
        label_key: :carrier,
        label_attr: :carrier
      )
    end

    # Analyzes performance by fulfillment service.
    #
    # @return [Array<Hash>] service performance data
    def performance_by_service
      performance_by_dimension(
        scope: relation.delivered.joins(:fulfillment_service),
        group_by: ["fulfillment_services.id", "fulfillment_services.name"],
        label_key: :service_name,
        label_attr: :service_name,
        extra_select: "fulfillment_services.name as service_name"
      )
    end

    # Groups deliveries by transit time buckets.
    # Useful for distribution analysis and histograms.
    #
    # @return [Hash] transit time bucket => count mapping
    def transit_time_distribution
      delivered = call
      return {} if delivered.empty?

      distribution = {
        "1 day" => 0,
        "2-3 days" => 0,
        "4-5 days" => 0,
        "6-7 days" => 0,
        "8+ days" => 0
      }

      delivered.each do |f|
        days = f.transit_duration.to_i
        case days
        when 0..1 then distribution["1 day"] += 1
        when 2..3 then distribution["2-3 days"] += 1
        when 4..5 then distribution["4-5 days"] += 1
        when 6..7 then distribution["6-7 days"] += 1
        else distribution["8+ days"] += 1
        end
      end

      distribution
    end

    private

    # @return [ActiveRecord::Relation] all fulfillments
    def default_relation
      Fulfillment.all
    end

    # Applies period filter to delivered_at.
    def filter_by_period(rel)
      rel.where(delivered_at: resolve_period(@period))
    end

    # Groups delivered fulfillments by a dimension and computes delivery stats.
    #
    # @param scope [ActiveRecord::Relation] base scope (already filtered/joined)
    # @param group_by [Symbol, Array<String>] column(s) to group by
    # @param label_key [Symbol] key name in the output hash
    # @param label_attr [Symbol] attribute name on the record for the label value
    # @param extra_select [String, nil] additional SQL select expression
    # @return [Array<Hash>] performance data per dimension
    def performance_by_dimension(scope:, group_by:, label_key:, label_attr:, extra_select: nil)
      selects = Array(group_by) + [
        "COUNT(*) as total_deliveries",
        "AVG(JULIANDAY(#{scope.table_name}.delivered_at) - JULIANDAY(#{scope.table_name}.shipped_at)) as avg_transit_days"
      ]
      selects.push(extra_select) if extra_select

      scope
        .group(*Array(group_by))
        .select(*selects)
        .map do |record|
          {
            label_key => record.send(label_attr),
            total_deliveries: record.total_deliveries,
            avg_transit_days: record.avg_transit_days&.round(1)
          }
        end
    end
  end
end
