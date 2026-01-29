# frozen_string_literal: true

module Orders
  # Query object to find orders that require attention or action.
  # Identifies orders in various problematic states that may need
  # follow-up from the team.
  #
  # Problem categories:
  # - Orders pending too long without validation
  # - Validated orders not yet invoiced
  # - Invoiced orders with overdue payments
  # - Paid orders awaiting shipment
  #
  # @example Get all orders needing attention
  #   Orders::NeedingAttentionQuery.call
  #
  # @example Get orders grouped by problem type
  #   query = Orders::NeedingAttentionQuery.new
  #   query.grouped  # => { pending_too_long: [...], ... }
  #
  class NeedingAttentionQuery < ApplicationQuery
    include GroupedQuery

    has_groups(
      pending_too_long: :pending_too_long,
      validated_not_invoiced: :validated_not_invoiced,
      invoiced_overdue: :invoiced_with_overdue_payment,
      awaiting_shipment: :awaiting_shipment
    )

    # Orders pending longer than this need attention
    PENDING_THRESHOLD_DAYS = 3
    # Validated orders older than this without invoice need attention
    VALIDATED_THRESHOLD_DAYS = 7

    def initialize(relation = default_relation)
      super(relation)
    end

    # Returns all orders needing attention across all categories.
    #
    # @return [ActiveRecord::Relation] orders requiring action
    def call
      relation.where(id: all_ids)
    end

    # Orders stuck in pending status for too long.
    # These may need validation or customer follow-up.
    #
    # @return [ActiveRecord::Relation] stale pending orders
    def pending_too_long
      relation
        .pending
        .where("orders.created_at < ?", PENDING_THRESHOLD_DAYS.days.ago)
    end

    # Validated orders that haven't been invoiced yet.
    # These are ready for billing but haven't been processed.
    #
    # @return [ActiveRecord::Relation] validated orders without invoices
    def validated_not_invoiced
      relation
        .validated
        .left_joins(:invoice)
        .where(invoices: { id: nil })
        .where("orders.created_at < ?", VALIDATED_THRESHOLD_DAYS.days.ago)
    end

    # Invoiced orders where payment is overdue.
    # These need payment collection follow-up.
    #
    # @return [ActiveRecord::Relation] orders with overdue invoices
    def invoiced_with_overdue_payment
      relation
        .invoiced
        .joins(:invoice)
        .where(invoices: { status: "sent" })
        .where("invoices.due_at < ?", Date.current)
    end

    # Paid orders that haven't been shipped yet.
    # These are ready for fulfillment.
    #
    # @return [ActiveRecord::Relation] paid orders awaiting shipment
    def awaiting_shipment
      relation
        .invoiced
        .joins(:invoice)
        .where(invoices: { status: "paid" })
        .where(fulfillment_id: nil)
    end

    private

    # @return [ActiveRecord::Relation] all orders
    def default_relation
      Order.all
    end

  end
end
