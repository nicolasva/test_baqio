# frozen_string_literal: true

module Orders
  # Query object for dashboard analytics and order statistics.
  # Provides aggregated data for dashboards including order counts,
  # revenue metrics, and customer insights for a given time period.
  #
  # @example Get today's orders
  #   Orders::DashboardQuery.call(period: :today)
  #
  # @example Get dashboard statistics for this month
  #   query = Orders::DashboardQuery.new(period: :this_month)
  #   query.stats  # => { total_orders: 150, total_revenue: 25000, ... }
  #
  # @example Get recent orders with eager loading
  #   query = Orders::DashboardQuery.new(period: :this_week)
  #   query.recent(limit: 5)
  #
  class DashboardQuery < ApplicationQuery
    # Initializes the dashboard query with a time period.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param period [Symbol, Range] time period filter
    #   Supported symbols: :today, :yesterday, :this_week, :last_week,
    #   :this_month, :last_month, :this_quarter, :this_year
    #   Can also be a custom date Range
    def initialize(relation = default_relation, period: :today)
      super(relation)
      @period = period
    end

    # Returns orders for the period with eager-loaded associations.
    #
    # @return [ActiveRecord::Relation] orders with associations
    def call
      relation
        .includes(:customer, :invoice, :fulfillment, :order_lines)
        .where(created_at: date_range)
        .order(created_at: :desc)
    end

    # Computes comprehensive dashboard statistics.
    #
    # @return [Hash] statistics including:
    #   - :total_orders [Integer] count of orders
    #   - :total_revenue [Float] sum of paid invoice amounts
    #   - :average_order_value [Float] mean order total
    #   - :orders_by_status [Hash] counts grouped by status
    #   - :top_customers [Hash] most active customers
    def stats
      orders = call

      {
        total_orders: orders.count,
        total_revenue: total_revenue(orders),
        average_order_value: average_order_value(orders),
        orders_by_status: orders_by_status(orders),
        top_customers: top_customers(orders)
      }
    end

    # Returns recent orders with eager loading for display.
    #
    # @param limit [Integer] maximum number of orders to return
    # @return [ActiveRecord::Relation] limited orders
    def recent(limit: 10)
      call.limit(limit)
    end

    private

    # @return [ActiveRecord::Relation] all orders
    def default_relation
      Order.all
    end

    # Converts period symbol to date range.
    #
    # @return [Range] date range for the period
    def date_range
      case @period
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
      when :this_year
        Time.current.all_year
      when Range
        @period
      else
        Time.current.all_day
      end
    end

    # Calculates total revenue from paid invoices.
    def total_revenue(orders)
      orders.joins(:invoice)
        .where(invoices: { status: "paid" })
        .sum("invoices.total_amount")
    end

    # Calculates average order value.
    def average_order_value(orders)
      return 0 if orders.empty?

      orders.average(:total_amount).to_f.round(2)
    end

    # Groups orders by status with counts.
    def orders_by_status(orders)
      orders.group(:status).count
    end

    # Finds top customers by order count.
    def top_customers(orders, limit: 5)
      orders
        .joins(:customer)
        .group("customers.id", "customers.first_name", "customers.last_name")
        .order("COUNT(orders.id) DESC")
        .limit(limit)
        .count
    end
  end
end
