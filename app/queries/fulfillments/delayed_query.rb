# frozen_string_literal: true

module Fulfillments
  # Query object for finding delayed or stuck fulfillments.
  # Identifies shipments that are taking longer than expected
  # at various stages of the fulfillment process.
  #
  # Delay categories:
  # - Stuck in pending: Not started processing after threshold
  # - Stuck in processing: Processing for too long
  # - Shipping delayed: In transit longer than expected
  #
  # @example Find all delayed fulfillments
  #   Fulfillments::DelayedQuery.call
  #
  # @example Custom thresholds
  #   Fulfillments::DelayedQuery.call(options: {
  #     processing_threshold: 3,  # days
  #     shipping_threshold: 10    # days
  #   })
  #
  # @example Get delay statistics
  #   query = Fulfillments::DelayedQuery.new
  #   query.stats  # => { total_delayed: 15, stuck_pending: 3, ... }
  #
  class DelayedQuery < ApplicationQuery
    include GroupedQuery
    include Averageable

    has_groups(
      stuck_pending: :stuck_in_pending,
      stuck_processing: :stuck_in_processing,
      shipping_delayed: :shipping_taking_too_long
    )

    # Default threshold for pending/processing stages (days)
    DEFAULT_PROCESSING_THRESHOLD = 2
    # Default threshold for shipping time (days)
    DEFAULT_SHIPPING_THRESHOLD = 7

    # Initializes with configurable thresholds.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param options [Hash] threshold options:
    #   - :processing_threshold [Integer] days before pending/processing is considered stuck
    #   - :shipping_threshold [Integer] days before shipping is considered delayed
    def initialize(relation = default_relation, options: {})
      super(relation)
      @processing_threshold = options[:processing_threshold] || DEFAULT_PROCESSING_THRESHOLD
      @shipping_threshold = options[:shipping_threshold] || DEFAULT_SHIPPING_THRESHOLD
    end

    # Returns all delayed fulfillments across all categories.
    #
    # @return [ActiveRecord::Relation] delayed fulfillments
    def call
      relation.where(id: all_ids)
    end

    # Fulfillments stuck in pending status.
    # These haven't started processing within the threshold.
    #
    # @return [ActiveRecord::Relation] stuck pending fulfillments
    def stuck_in_pending
      relation
        .pending
        .where("fulfillments.created_at < ?", @processing_threshold.days.ago)
        .order(created_at: :asc)
    end

    # Fulfillments stuck in processing status.
    # Processing has started but not completed within threshold.
    #
    # @return [ActiveRecord::Relation] stuck processing fulfillments
    def stuck_in_processing
      relation
        .processing
        .where("fulfillments.updated_at < ?", @processing_threshold.days.ago)
        .order(updated_at: :asc)
    end

    # Fulfillments shipped but taking too long to deliver.
    # May indicate carrier issues or lost packages.
    #
    # @return [ActiveRecord::Relation] delayed in-transit fulfillments
    def shipping_taking_too_long
      relation
        .shipped
        .where("shipped_at < ?", @shipping_threshold.days.ago)
        .order(shipped_at: :asc)
    end

    # Computes delay statistics for monitoring.
    # Loads all delayed fulfillments once and computes stats in memory.
    #
    # @return [Hash] delay metrics
    def stats
      delayed = call.to_a
      pending = delayed.select { |f| f.status == "pending" }
      oldest = pending.min_by(&:created_at)

      {
        total_delayed: delayed.size,
        stuck_pending: pending.size,
        stuck_processing: delayed.count { |f| f.status == "processing" },
        shipping_delayed: delayed.count { |f| f.status == "shipped" },
        oldest_pending: oldest && {
          id: oldest.id,
          created_at: oldest.created_at,
          days_pending: (Time.current - oldest.created_at).to_i / 1.day
        },
        average_delay: compute_average_delay(delayed)
      }
    end

    # Returns priority alerts sorted by urgency.
    # Pending issues are prioritized over shipping delays.
    #
    # @return [ActiveRecord::Relation] prioritized delayed fulfillments
    def priority_alerts
      call
        .includes(:fulfillment_service, orders: :customer)
        .order(Arel.sql("CASE status
          WHEN 'pending' THEN 1
          WHEN 'processing' THEN 2
          WHEN 'shipped' THEN 3
          ELSE 4 END"))
        .order(created_at: :asc)
        .limit(20)
    end

    # Groups shipping delays by carrier.
    # Helps identify problematic carriers.
    #
    # @return [Hash] carrier => count mapping
    def delays_by_carrier
      shipping_taking_too_long
        .group(:carrier)
        .count
    end

    private

    # @return [ActiveRecord::Relation] all fulfillments
    def default_relation
      Fulfillment.all
    end


    # Calculates average delay days from a pre-loaded array.
    def compute_average_delay(delayed)
      safe_average(delayed, precision: 1) do |f|
        case f.status
        when "pending" then (Time.current - f.created_at).to_i / 1.day
        when "processing" then (Time.current - f.updated_at).to_i / 1.day
        when "shipped" then (Time.current - f.shipped_at).to_i / 1.day
        else 0
        end
      end
    end
  end
end
