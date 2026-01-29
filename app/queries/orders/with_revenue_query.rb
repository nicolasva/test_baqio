# frozen_string_literal: true

module Orders
  # Query object for revenue analysis based on paid orders.
  # Provides revenue metrics, period-based analysis, and product insights.
  #
  # @example Get total revenue
  #   Orders::WithRevenueQuery.new.total_revenue  # => 125000.00
  #
  # @example Revenue by month
  #   query = Orders::WithRevenueQuery.new
  #   query.revenue_by_period(group_by: :month)
  #   # => { "2024-01" => 15000, "2024-02" => 18000, ... }
  #
  # @example Top selling products
  #   query.top_products(limit: 5)
  #
  class WithRevenueQuery < ApplicationQuery
    def initialize(relation = default_relation)
      super(relation)
    end

    # Returns orders with paid invoices and revenue data.
    # Includes invoice_total and payment_date as virtual attributes.
    #
    # @return [ActiveRecord::Relation] orders with revenue data
    def call
      relation
        .joins(:invoice)
        .where(invoices: { status: "paid" })
        .select(
          "orders.*",
          "invoices.total_amount as invoice_total",
          "invoices.paid_at as payment_date"
        )
    end

    # Calculates total revenue from all paid orders.
    #
    # @return [Float] total revenue
    def total_revenue
      call.sum("invoices.total_amount")
    end

    # Groups revenue by time period.
    # Uses SQLite date functions for grouping.
    #
    # @param group_by [Symbol] grouping level (:day, :week, :month, :quarter, :year)
    # @return [Hash] period => revenue mapping
    def revenue_by_period(group_by: :month)
      grouping = case group_by
      when :day
        "DATE(invoices.paid_at)"
      when :week
        "strftime('%Y-%W', invoices.paid_at)"
      when :month
        "strftime('%Y-%m', invoices.paid_at)"
      when :quarter
        "strftime('%Y', invoices.paid_at) || '-Q' || ((CAST(strftime('%m', invoices.paid_at) AS INTEGER) - 1) / 3 + 1)"
      when :year
        "strftime('%Y', invoices.paid_at)"
      else
        "strftime('%Y-%m', invoices.paid_at)"
      end

      relation
        .joins(:invoice)
        .where(invoices: { status: "paid" })
        .group(Arel.sql(grouping))
        .order(Arel.sql(grouping))
        .sum("invoices.total_amount")
    end

    # Calculates average revenue per paid order.
    #
    # @return [Float] average order value
    def average_revenue
      total = paid_orders_count
      return 0 if total.zero?

      (total_revenue / total).round(2)
    end

    # Counts the number of paid orders.
    #
    # @return [Integer] count of paid orders
    def paid_orders_count
      relation
        .joins(:invoice)
        .where(invoices: { status: "paid" })
        .count
    end

    # Returns top selling products by revenue.
    #
    # @param limit [Integer] number of products to return
    # @return [Hash] product_name => total_revenue mapping
    def top_products(limit: 10)
      relation
        .joins(:invoice, :order_lines)
        .where(invoices: { status: "paid" })
        .group("order_lines.name")
        .order("SUM(order_lines.total_price) DESC")
        .limit(limit)
        .sum("order_lines.total_price")
    end

    private

    # @return [ActiveRecord::Relation] all orders
    def default_relation
      Order.all
    end
  end
end
