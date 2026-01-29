# frozen_string_literal: true

module Customers
  # Query object for identifying inactive or churned customers.
  # Helps with re-engagement campaigns and customer retention analysis.
  #
  # Inactive customers include:
  # - Customers who never placed an order
  # - Customers whose last order was before the threshold date
  #
  # @example Find all inactive customers (default 90 days)
  #   Customers::InactiveQuery.call
  #
  # @example Custom inactivity threshold
  #   Customers::InactiveQuery.call(inactive_since: 60.days.ago)
  #
  # @example Get inactivity statistics
  #   query = Customers::InactiveQuery.new
  #   query.stats  # => { total_inactive: 150, never_ordered: 30, ... }
  #
  # @example Segment by inactivity duration
  #   query.segmented
  #   # => { inactive_30_60_days: [...], inactive_60_90_days: [...], ... }
  #
  class InactiveQuery < ApplicationQuery
    include GroupedQuery

    has_groups(
      never_ordered: :never_ordered,
      no_recent_orders: :no_recent_orders
    )

    # Default inactivity threshold in days
    DEFAULT_INACTIVE_DAYS = 90

    # Initializes with inactivity threshold.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param inactive_since [Time] cutoff date for considering a customer inactive
    def initialize(relation = default_relation, inactive_since: DEFAULT_INACTIVE_DAYS.days.ago)
      super(relation)
      @inactive_since = inactive_since
    end

    # Returns all inactive customers (never ordered + no recent orders).
    #
    # @return [ActiveRecord::Relation] inactive customers
    def call
      relation.where(id: all_ids)
    end

    # Customers who have never placed an order.
    # Good candidates for onboarding campaigns.
    #
    # @return [ActiveRecord::Relation] customers with no orders
    def never_ordered
      relation
        .left_joins(:orders)
        .where(orders: { id: nil })
    end

    # Customers who ordered before but not recently.
    # Good candidates for win-back campaigns.
    #
    # @return [ActiveRecord::Relation] customers with old orders only
    def no_recent_orders
      relation
        .joins(:orders)
        .group("customers.id")
        .having("MAX(orders.created_at) < ?", @inactive_since)
    end

    # Customers with abandoned carts (pending orders older than 7 days).
    # Good candidates for cart recovery emails.
    #
    # @return [ActiveRecord::Relation] customers with abandoned orders
    def with_abandoned_carts
      relation
        .joins(:orders)
        .where(orders: { status: "pending" })
        .where("orders.created_at < ?", 7.days.ago)
        .distinct
    end

    # Computes inactivity statistics for reporting.
    #
    # @return [Hash] inactivity metrics
    def stats
      {
        total_inactive: call.count,
        never_ordered: never_ordered.count,
        no_recent_orders: no_recent_orders.count,
        with_abandoned_carts: with_abandoned_carts.count,
        potential_revenue_lost: potential_revenue_lost
      }
    end

    # Segments customers by inactivity duration.
    # Useful for targeting different re-engagement strategies.
    #
    # @return [Hash] customers grouped by inactivity period
    def segmented
      {
        inactive_30_60_days: inactive_between(30, 60),
        inactive_60_90_days: inactive_between(60, 90),
        inactive_90_180_days: inactive_between(90, 180),
        inactive_over_180_days: inactive_over(180)
      }
    end

    private

    # @return [ActiveRecord::Relation] all customers
    def default_relation
      Customer.all
    end


    # Finds customers inactive for a specific duration range.
    def inactive_between(min_days, max_days)
      relation
        .joins(:orders)
        .group("customers.id")
        .having(
          "MAX(orders.created_at) BETWEEN ? AND ?",
          max_days.days.ago,
          min_days.days.ago
        )
    end

    # Finds customers inactive for more than specified days.
    def inactive_over(days)
      relation
        .joins(:orders)
        .group("customers.id")
        .having("MAX(orders.created_at) < ?", days.days.ago)
    end

    # Estimates potential revenue lost from inactive customers.
    # Based on their historical average order value.
    def potential_revenue_lost
      inactive_customers = call.includes(orders: :invoice)

      inactive_customers.sum do |customer|
        customer.total_spent / [customer.orders_count, 1].max
      end.round(2)
    end
  end
end
