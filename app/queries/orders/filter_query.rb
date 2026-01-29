# frozen_string_literal: true

module Orders
  # Query object for filtering orders based on multiple criteria.
  # Provides a flexible way to search and filter orders by status,
  # customer, date range, amount, reference, and associations.
  #
  # @example Basic filtering
  #   Orders::FilterQuery.call(filters: { status: "pending" })
  #
  # @example Complex filtering
  #   Orders::FilterQuery.call(filters: {
  #     status: ["pending", "validated"],
  #     customer_id: 123,
  #     from_date: 1.month.ago,
  #     min_amount: 100,
  #     has_invoice: true,
  #     sort_by: :total_amount,
  #     sort_dir: :desc
  #   })
  #
  class FilterQuery < ApplicationQuery
    # Initializes the filter query with optional filters.
    #
    # @param relation [ActiveRecord::Relation] base relation to filter
    # @param filters [Hash] filter criteria with the following keys:
    #   - :status [String, Array<String>] order status(es)
    #   - :customer_id [Integer] filter by customer
    #   - :from_date [Date] start date for created_at
    #   - :to_date [Date] end date for created_at
    #   - :min_amount [Numeric] minimum total_amount
    #   - :max_amount [Numeric] maximum total_amount
    #   - :reference [String] partial reference match
    #   - :has_invoice [Boolean] filter by invoice presence
    #   - :has_fulfillment [Boolean] filter by fulfillment presence
    #   - :sort_by [Symbol] column to sort by (default: :created_at)
    #   - :sort_dir [Symbol] sort direction (default: :desc)
    def initialize(relation = default_relation, filters: {})
      super(relation)
      @filters = filters.to_h.symbolize_keys
    end

    # Applies all filters in sequence and returns the filtered relation.
    #
    # @return [ActiveRecord::Relation] filtered and sorted orders
    def call
      result = relation
      result = filter_by_status(result)
      result = filter_by_customer(result)
      result = filter_by_date_range(result)
      result = filter_by_amount_range(result)
      result = filter_by_reference(result)
      result = filter_by_has_invoice(result)
      result = filter_by_has_fulfillment(result)
      apply_sorting(result)
    end

    private

    # @return [ActiveRecord::Relation] all orders
    def default_relation
      Order.all
    end

    # Filters by order status. Accepts single status or array.
    def filter_by_status(rel)
      return rel unless @filters[:status].present?

      statuses = Array(@filters[:status])
      rel.where(status: statuses)
    end

    # Filters by customer ID.
    def filter_by_customer(rel)
      return rel unless @filters[:customer_id].present?

      rel.where(customer_id: @filters[:customer_id])
    end

    # Filters by date range using from_date and to_date.
    def filter_by_date_range(rel)
      rel = rel.where("orders.created_at >= ?", @filters[:from_date]) if @filters[:from_date].present?
      rel = rel.where("orders.created_at <= ?", @filters[:to_date].end_of_day) if @filters[:to_date].present?
      rel
    end

    # Filters by total_amount range.
    def filter_by_amount_range(rel)
      rel = rel.where("total_amount >= ?", @filters[:min_amount]) if @filters[:min_amount].present?
      rel = rel.where("total_amount <= ?", @filters[:max_amount]) if @filters[:max_amount].present?
      rel
    end

    # Filters by partial reference match (LIKE query).
    def filter_by_reference(rel)
      return rel unless @filters[:reference].present?

      rel.where("reference LIKE ?", "%#{@filters[:reference]}%")
    end

    # Filters by invoice presence using joins.
    def filter_by_has_invoice(rel)
      return rel if @filters[:has_invoice].nil?

      if @filters[:has_invoice]
        rel.joins(:invoice)
      else
        rel.left_joins(:invoice).where(invoices: { id: nil })
      end
    end

    # Filters by fulfillment presence.
    def filter_by_has_fulfillment(rel)
      return rel if @filters[:has_fulfillment].nil?

      if @filters[:has_fulfillment]
        rel.where.not(fulfillment_id: nil)
      else
        rel.where(fulfillment_id: nil)
      end
    end

    # Applies sorting to the result. Defaults to created_at DESC.
    def apply_sorting(rel)
      sort_by = @filters[:sort_by] || :created_at
      sort_dir = @filters[:sort_dir] || :desc

      rel.order(sort_by => sort_dir)
    end
  end
end
