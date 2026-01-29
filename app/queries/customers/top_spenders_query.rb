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
    # More detailed than call but loads all records into memory.
    #
    # @return [Array<Hash>] customer data with statistics
    def with_stats
      call.map do |customer|
        {
          customer: customer,
          total_spent: customer.total_spent,
          orders_count: customer.orders_count,
          average_order_value: average_order_value(customer)
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
    # Useful for understanding revenue concentration.
    #
    # @return [Float] percentage of revenue from top customers
    def revenue_percentage
      top_revenue = call.sum(&:total_spent)
      total_revenue = relation.sum(&:total_spent)

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
      case @period
      when Range
        query.where(invoices: { paid_at: @period })
      when :this_month
        query.where(invoices: { paid_at: Time.current.all_month })
      when :this_quarter
        query.where(invoices: { paid_at: Time.current.all_quarter })
      when :this_year
        query.where(invoices: { paid_at: Time.current.all_year })
      when :last_month
        query.where(invoices: { paid_at: 1.month.ago.all_month })
      when :last_year
        query.where(invoices: { paid_at: 1.year.ago.all_year })
      else
        query
      end
    end

    # Calculates average order value for a customer.
    def average_order_value(customer)
      return 0 if customer.orders_count.zero?

      (customer.total_spent / customer.orders_count).round(2)
    end
  end
end
