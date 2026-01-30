# frozen_string_literal: true

module Customers
  # Query object for finding top spending customers.
  # Ranks customers by total revenue from paid invoices.
  #
  # @example Get top 10 spenders
  #   Customers::TopSpendersQuery.call
  #
  # @example Get top 5 spenders this month
  #   Customers::TopSpendersQuery.call(limit: 5, period: :this_month)
  #
  # @example Get detailed statistics
  #   query = Customers::TopSpendersQuery.new(limit: 10)
  #   query.with_stats
  #   # => [{ customer: #<Customer>, total_spent: 5000, orders_count: 15, average_order_value: 333.33 }]
  #
  # @example Revenue concentration analysis
  #   query.revenue_percentage  # => 45.5 (top customers represent 45.5% of revenue)
  #
  class TopSpendersQuery < ApplicationQuery
    include PeriodFilterable

    # Initializes with limit and optional period filter.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param limit [Integer] number of top customers to return
    # @param period [Symbol, Range, nil] time period filter for purchases
    def initialize(relation = default_relation, limit: 10, period: nil)
      super(relation)
      @limit = limit
      @period = period
    end

    # Returns top spending customers ordered by total revenue.
    #
    # @return [ActiveRecord::Relation] customers with total_spent virtual attribute
    def call
      base_query
        .order(Arel.sql("SUM(invoices.total_amount) DESC"))
        .limit(@limit)
    end

    # Returns top customers with computed statistics.
    # Uses virtual attributes from the SQL query to avoid N+1 queries.
    #
    # @return [Array<Hash>] customer data with statistics
    def with_stats
      call.map do |customer|
        spent = customer.read_attribute("total_spent").to_f
        count = customer.read_attribute("orders_count").to_i
        {
          customer: customer,
          total_spent: spent,
          orders_count: count,
          average_order_value: count.zero? ? 0 : (spent / count).round(2)
        }
      end
    end

    # Returns only IDs for efficient subqueries.
    #
    # @return [Array<Integer>] customer IDs
    def ids
      call.map(&:id)
    end

    # Calculates what percentage of total revenue comes from top customers.
    # Uses virtual attributes and a single SQL query to avoid N+1.
    #
    # @return [Float] percentage of revenue from top customers
    def revenue_percentage
      top_revenue = call.sum { |c| c.read_attribute("total_spent").to_f }
      total_revenue = relation
        .joins(orders: :invoice)
        .where(invoices: { status: "paid" })
        .sum("invoices.total_amount")

      return 0 if total_revenue.zero?

      ((top_revenue / total_revenue) * 100).round(2)
    end

    private

    # @return [ActiveRecord::Relation] all customers
    def default_relation
      Customer.all
    end

    # Builds base query with aggregations.
    def base_query
      query = relation
        .joins(orders: :invoice)
        .where(invoices: { status: "paid" })
        .group("customers.id")
        .select(
          "customers.*",
          "SUM(invoices.total_amount) as total_spent",
          "COUNT(DISTINCT orders.id) as orders_count"
        )

      query = filter_by_period(query) if @period
      query
    end

    # Applies period filter to purchases.
    def filter_by_period(query)
      query.where(invoices: { paid_at: resolve_period(@period) })
    end

  end
end
