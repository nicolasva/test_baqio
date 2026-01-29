# frozen_string_literal: true

module Invoices
  # Query object for revenue analysis and reporting.
  # Calculates revenue metrics from paid invoices with support
  # for period filtering, comparisons, and breakdowns.
  #
  # @example Get total revenue for this month
  #   Invoices::RevenueQuery.new(period: :this_month).total  # => 25000.00
  #
  # @example Compare revenue between periods
  #   query = Invoices::RevenueQuery.new
  #   query.comparison(
  #     current_period: :this_month,
  #     previous_period: :last_month
  #   )
  #   # => { current: 25000, previous: 20000, difference: 5000, growth_percentage: 25.0 }
  #
  # @example Monthly breakdown
  #   query.by_month(year: 2024)
  #   # => { "01" => 15000, "02" => 18000, ... }
  #
  class RevenueQuery < ApplicationQuery
    # Initializes with optional period filter.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param period [Symbol, Range, nil] time period filter
    #   Symbols: :today, :this_week, :this_month, :this_quarter, :this_year,
    #            :last_month, :last_quarter, :last_year
    #   Or a custom Date/Time Range
    def initialize(relation = default_relation, period: nil)
      super(relation)
      @period = period
    end

    # Returns paid invoices, optionally filtered by period.
    #
    # @return [ActiveRecord::Relation] paid invoices
    def call
      result = relation.paid
      result = filter_by_period(result) if @period
      result
    end

    # Total revenue including tax.
    #
    # @return [Float] total revenue (total_amount)
    def total
      call.sum(:total_amount)
    end

    # Total revenue excluding tax.
    #
    # @return [Float] revenue before tax (amount)
    def total_excluding_tax
      call.sum(:amount)
    end

    # Total tax collected.
    #
    # @return [Float] sum of tax_amount
    def total_tax
      call.sum(:tax_amount)
    end

    # Revenue breakdown by month for a given year.
    # Uses SQLite strftime for date extraction.
    #
    # @param year [Integer] the year to analyze
    # @return [Hash] month_number => revenue mapping
    def by_month(year: Date.current.year)
      relation
        .paid
        .where("strftime('%Y', paid_at) = ?", year.to_s)
        .group(Arel.sql("strftime('%m', paid_at)"))
        .order(Arel.sql("strftime('%m', paid_at)"))
        .sum(:total_amount)
    end

    # Revenue breakdown by quarter for a given year.
    #
    # @param year [Integer] the year to analyze
    # @return [Hash] quarter_number => revenue mapping
    def by_quarter(year: Date.current.year)
      relation
        .paid
        .where("strftime('%Y', paid_at) = ?", year.to_s)
        .group(Arel.sql("(CAST(strftime('%m', paid_at) AS INTEGER) - 1) / 3 + 1"))
        .order(Arel.sql("(CAST(strftime('%m', paid_at) AS INTEGER) - 1) / 3 + 1"))
        .sum(:total_amount)
    end

    # Compares revenue between two periods with growth calculation.
    #
    # @param current_period [Symbol, Range] current period to measure
    # @param previous_period [Symbol, Range] period to compare against
    # @return [Hash] comparison metrics
    def comparison(current_period:, previous_period:)
      current_revenue = self.class.new(relation, period: current_period).total
      previous_revenue = self.class.new(relation, period: previous_period).total

      growth = if previous_revenue.zero?
        current_revenue.positive? ? 100.0 : 0.0
      else
        ((current_revenue - previous_revenue) / previous_revenue * 100).round(2)
      end

      {
        current: current_revenue,
        previous: previous_revenue,
        difference: current_revenue - previous_revenue,
        growth_percentage: growth
      }
    end

    # Calculates average invoice value.
    #
    # @return [Float] average revenue per invoice
    def average_invoice_value
      invoices = call
      return 0 if invoices.empty?

      (invoices.sum(:total_amount) / invoices.count).round(2)
    end

    # Revenue breakdown by customer.
    #
    # @param limit [Integer] number of customers to return
    # @return [Hash] customer => revenue mapping
    def by_customer(limit: 10)
      relation
        .paid
        .joins(order: :customer)
        .group("customers.id", "customers.first_name", "customers.last_name")
        .order("SUM(invoices.total_amount) DESC")
        .limit(limit)
        .sum(:total_amount)
    end

    private

    # @return [ActiveRecord::Relation] all invoices
    def default_relation
      Invoice.all
    end

    # Applies period filter to relation.
    def filter_by_period(rel)
      case @period
      when Range
        rel.where(paid_at: @period)
      when :today
        rel.where(paid_at: Time.current.all_day)
      when :this_week
        rel.where(paid_at: Time.current.all_week)
      when :this_month
        rel.where(paid_at: Time.current.all_month)
      when :this_quarter
        rel.where(paid_at: Time.current.all_quarter)
      when :this_year
        rel.where(paid_at: Time.current.all_year)
      when :last_month
        rel.where(paid_at: 1.month.ago.all_month)
      when :last_quarter
        rel.where(paid_at: 1.quarter.ago.all_quarter)
      when :last_year
        rel.where(paid_at: 1.year.ago.all_year)
      else
        rel
      end
    end
  end
end
