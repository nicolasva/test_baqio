# frozen_string_literal: true

module Invoices
  # Query object for generating accounts receivable aging reports.
  # Categorizes outstanding invoices by how many days overdue they are.
  # Standard aging buckets: Current, 1-30, 31-60, 61-90, 90+ days.
  #
  # @example Generate full aging report
  #   query = Invoices::AgingReportQuery.new
  #   query.report
  #   # => { current: { count: 5, total_amount: 5000, invoices: [...] }, ... }
  #
  # @example Get summary totals only
  #   query.summary
  #   # => { current: { count: 5, total_amount: 5000 }, ... }
  #
  # @example Get total overdue amount
  #   query.total_overdue_amount  # => 15000.00
  #
  class AgingReportQuery < ApplicationQuery
    # Standard aging buckets based on days overdue
    AGING_BUCKETS = {
      current: 0..0,        # Due today (not overdue)
      days_1_30: 1..30,     # 1-30 days overdue
      days_31_60: 31..60,   # 31-60 days overdue
      days_61_90: 61..90,   # 61-90 days overdue
      over_90: 91..Float::INFINITY  # Over 90 days overdue
    }.freeze

    def initialize(relation = default_relation)
      super(relation)
    end

    # Returns all sent (outstanding) invoices.
    #
    # @return [ActiveRecord::Relation] sent invoices
    def call
      relation.sent
    end

    # Generates complete aging report with invoice details.
    #
    # @return [Hash] aging buckets with counts, amounts, and invoices
    def report
      AGING_BUCKETS.transform_values do |range|
        invoices = invoices_in_range(range)
        {
          count: invoices.count,
          total_amount: invoices.sum(:total_amount),
          invoices: invoices
        }
      end
    end

    # Generates summary aging report without invoice details.
    # More efficient for dashboard displays.
    #
    # @return [Hash] aging buckets with only counts and amounts
    def summary
      AGING_BUCKETS.transform_values do |range|
        invoices = invoices_in_range(range)
        {
          count: invoices.count,
          total_amount: invoices.sum(:total_amount)
        }
      end
    end

    # Returns invoices due today or in the future (not overdue).
    #
    # @return [ActiveRecord::Relation] current invoices
    def current
      relation.sent.where("due_at >= ?", Date.current)
    end

    # Returns invoices 1-30 days overdue.
    #
    # @return [ActiveRecord::Relation] invoices in this aging bucket
    def overdue_1_30
      invoices_in_range(1..30)
    end

    # Returns invoices 31-60 days overdue.
    #
    # @return [ActiveRecord::Relation] invoices in this aging bucket
    def overdue_31_60
      invoices_in_range(31..60)
    end

    # Returns invoices 61-90 days overdue.
    #
    # @return [ActiveRecord::Relation] invoices in this aging bucket
    def overdue_61_90
      invoices_in_range(61..90)
    end

    # Returns invoices more than 90 days overdue.
    # These are typically considered bad debt candidates.
    #
    # @return [ActiveRecord::Relation] severely overdue invoices
    def overdue_over_90
      invoices_in_range(91..Float::INFINITY)
    end

    # Calculates total amount of all overdue invoices.
    #
    # @return [Float] total overdue amount
    def total_overdue_amount
      relation
        .sent
        .where("due_at < ?", Date.current)
        .sum(:total_amount)
    end

    private

    # @return [ActiveRecord::Relation] all invoices
    def default_relation
      Invoice.all
    end

    # Filters invoices by days overdue range.
    #
    # @param range [Range] number of days overdue
    # @return [ActiveRecord::Relation] invoices in the range
    def invoices_in_range(range)
      if range.first.zero? && range.last.zero?
        # Invoices due today
        relation.sent.where(due_at: Date.current)
      elsif range.last == Float::INFINITY
        # More than X days overdue
        relation.sent.where("due_at < ?", Date.current - range.first.days)
      else
        # Between X and Y days overdue
        start_date = Date.current - range.last.days
        end_date = Date.current - range.first.days
        relation.sent.where(due_at: start_date...end_date)
      end
    end
  end
end
