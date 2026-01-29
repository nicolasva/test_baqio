# frozen_string_literal: true

module Customers
  # Query object for searching and filtering customers.
  # Supports text search across multiple fields and various filters.
  #
  # @example Simple text search
  #   Customers::SearchQuery.call(params: { q: "john" })
  #
  # @example Complex filtering
  #   Customers::SearchQuery.call(params: {
  #     q: "john",
  #     has_orders: true,
  #     has_email: true,
  #     min_spent: 1000,
  #     sort_by: :name,
  #     sort_dir: :asc
  #   })
  #
  class SearchQuery < ApplicationQuery
    # Initializes with search parameters.
    #
    # @param relation [ActiveRecord::Relation] base relation
    # @param params [Hash] search and filter parameters:
    #   - :q [String] text search across name, email, phone
    #   - :has_orders [Boolean] filter by order presence
    #   - :has_email [Boolean] filter by email presence
    #   - :min_spent [Numeric] minimum total spent
    #   - :max_spent [Numeric] maximum total spent
    #   - :from_date [Date] created after this date
    #   - :to_date [Date] created before this date
    #   - :sort_by [Symbol] column to sort (:name, :orders_count, or any column)
    #   - :sort_dir [Symbol] direction (:asc or :desc)
    def initialize(relation = default_relation, params: {})
      super(relation)
      @params = params.to_h.symbolize_keys
    end

    # Applies all search criteria and returns filtered customers.
    #
    # @return [ActiveRecord::Relation] filtered and sorted customers
    def call
      result = relation
      result = search_by_query(result)
      result = filter_by_has_orders(result)
      result = filter_by_has_email(result)
      result = filter_by_total_spent(result)
      result = filter_by_created_at(result)
      apply_sorting(result)
    end

    private

    # @return [ActiveRecord::Relation] all customers
    def default_relation
      Customer.all
    end

    # Text search across first_name, last_name, email, and phone.
    def search_by_query(rel)
      return rel unless @params[:q].present?

      query = "%#{@params[:q]}%"
      rel.where(
        "first_name LIKE :q OR last_name LIKE :q OR email LIKE :q OR phone LIKE :q",
        q: query
      )
    end

    # Filters by presence or absence of orders.
    def filter_by_has_orders(rel)
      return rel if @params[:has_orders].nil?

      if @params[:has_orders]
        rel.joins(:orders).distinct
      else
        rel.left_joins(:orders).where(orders: { id: nil })
      end
    end

    # Filters by presence or absence of email.
    def filter_by_has_email(rel)
      return rel if @params[:has_email].nil?

      if @params[:has_email]
        rel.where.not(email: [nil, ""])
      else
        rel.where(email: [nil, ""])
      end
    end

    # Filters by total amount spent (from paid invoices).
    def filter_by_total_spent(rel)
      return rel unless @params[:min_spent].present? || @params[:max_spent].present?

      rel = rel.joins(orders: :invoice)
        .where(invoices: { status: "paid" })
        .group("customers.id")
        .having("SUM(invoices.total_amount) >= ?", @params[:min_spent]) if @params[:min_spent].present?

      if @params[:max_spent].present?
        rel = rel.joins(orders: :invoice)
          .where(invoices: { status: "paid" })
          .group("customers.id")
          .having("SUM(invoices.total_amount) <= ?", @params[:max_spent])
      end

      rel
    end

    # Filters by creation date range.
    def filter_by_created_at(rel)
      rel = rel.where("customers.created_at >= ?", @params[:from_date]) if @params[:from_date].present?
      rel = rel.where("customers.created_at <= ?", @params[:to_date].end_of_day) if @params[:to_date].present?
      rel
    end

    # Applies sorting. Handles special cases for name and orders_count.
    def apply_sorting(rel)
      sort_by = @params[:sort_by]&.to_sym || :created_at
      sort_dir = @params[:sort_dir]&.to_sym || :desc

      case sort_by
      when :name
        # Sort by concatenated full name
        rel.order(Arel.sql("COALESCE(first_name, '') || ' ' || COALESCE(last_name, '') #{sort_dir}"))
      when :orders_count
        # Sort by number of orders
        rel.left_joins(:orders)
          .group("customers.id")
          .order(Arel.sql("COUNT(orders.id) #{sort_dir}"))
      else
        rel.order(sort_by => sort_dir)
      end
    end
  end
end
