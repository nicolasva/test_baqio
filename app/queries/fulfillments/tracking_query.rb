# frozen_string_literal: true

module Fulfillments
  # Query object for tracking and searching fulfillments.
  # Provides methods for looking up shipments by tracking number,
  # carrier, or customer, and for monitoring active shipments.
  #
  # @example Find by tracking number
  #   Fulfillments::TrackingQuery.new.by_tracking_number("1Z999AA10123456784")
  #
  # @example Search with multiple criteria
  #   query = Fulfillments::TrackingQuery.new
  #   query.search(
  #     carrier: "UPS",
  #     status: "shipped",
  #     from_date: 1.week.ago
  #   )
  #
  # @example Get tracking statistics
  #   query.tracking_stats
  #   # => { total_with_tracking: 150, active_shipments: 25, by_carrier: {...}, by_status: {...} }
  #
  class TrackingQuery < ApplicationQuery
    def initialize(relation = default_relation)
      super(relation)
    end

    # Returns fulfillments with tracking numbers, eager-loading associations.
    #
    # @return [ActiveRecord::Relation] fulfillments with tracking info
    def call
      relation
        .includes(:fulfillment_service, orders: [:customer, :order_lines])
        .where.not(tracking_number: [nil, ""])
    end

    # Finds a fulfillment by exact tracking number.
    #
    # @param number [String] the tracking number to find
    # @return [Fulfillment, nil] matching fulfillment or nil
    def by_tracking_number(number)
      relation.find_by(tracking_number: number)
    end

    # Finds fulfillments by carrier (partial match).
    #
    # @param carrier [String] carrier name to search
    # @return [ActiveRecord::Relation] matching fulfillments
    def by_carrier(carrier)
      relation
        .where("carrier LIKE ?", "%#{carrier}%")
        .where.not(tracking_number: [nil, ""])
    end

    # Returns active shipments (in transit with tracking).
    #
    # @return [ActiveRecord::Relation] in-transit fulfillments
    def active
      relation
        .in_transit
        .where.not(tracking_number: [nil, ""])
        .order(shipped_at: :desc)
    end

    # Returns recently delivered shipments.
    #
    # @param days [Integer] number of days to look back
    # @return [ActiveRecord::Relation] recently delivered fulfillments
    def recently_delivered(days: 7)
      relation
        .delivered
        .where("delivered_at >= ?", days.days.ago)
        .order(delivered_at: :desc)
    end

    # Returns fulfillment history for a specific order.
    #
    # @param order [Order] the order to get fulfillments for
    # @return [ActiveRecord::Relation] fulfillments for the order
    def for_order(order)
      relation
        .joins(:orders)
        .where(orders: { id: order.id })
    end

    # Returns fulfillment history for a specific customer.
    #
    # @param customer [Customer] the customer to get fulfillments for
    # @return [ActiveRecord::Relation] fulfillments for the customer
    def for_customer(customer)
      relation
        .joins(orders: :customer)
        .where(customers: { id: customer.id })
        .order(created_at: :desc)
    end

    # Multi-criteria search for fulfillments.
    #
    # @param params [Hash] search parameters:
    #   - :tracking_number [String] partial tracking number match
    #   - :carrier [String] partial carrier name match
    #   - :status [String] fulfillment status
    #   - :from_date [Date] shipped on or after
    #   - :to_date [Date] shipped on or before
    # @return [ActiveRecord::Relation] matching fulfillments
    def search(params = {})
      result = call

      if params[:tracking_number].present?
        result = result.where("tracking_number LIKE ?", "%#{params[:tracking_number]}%")
      end

      if params[:carrier].present?
        result = result.where("carrier LIKE ?", "%#{params[:carrier]}%")
      end

      if params[:status].present?
        result = result.where(status: params[:status])
      end

      if params[:from_date].present?
        result = result.where("shipped_at >= ?", params[:from_date])
      end

      if params[:to_date].present?
        result = result.where("shipped_at <= ?", params[:to_date].end_of_day)
      end

      result.order(shipped_at: :desc)
    end

    # Computes tracking statistics for monitoring.
    #
    # @return [Hash] tracking metrics
    def tracking_stats
      {
        total_with_tracking: call.count,
        active_shipments: active.count,
        by_carrier: call.group(:carrier).count,
        by_status: call.group(:status).count
      }
    end

    private

    # @return [ActiveRecord::Relation] all fulfillments
    def default_relation
      Fulfillment.all
    end
  end
end
