# frozen_string_literal: true

module Invoices
  # Query object for identifying invoices that need follow-up or collection.
  # Categorizes invoices by urgency/priority based on how overdue they are.
  #
  # Priority levels:
  # - Critical: 60+ days overdue (bad debt risk)
  # - High: 30-60 days overdue (escalation needed)
  # - Medium: 1-30 days overdue (standard follow-up)
  # - Low: Due within 7 days (proactive reminder)
  #
  # @example Get all invoices needing follow-up
  #   Invoices::NeedingFollowUpQuery.call
  #
  # @example Group by priority for work queue
  #   query = Invoices::NeedingFollowUpQuery.new
  #   query.grouped_by_priority
  #   # => { critical: [...], high: [...], medium: [...], low: [...] }
  #
  # @example Get follow-up statistics
  #   query.stats  # => { total_overdue: 25, total_overdue_amount: 50000, ... }
  #
  class NeedingFollowUpQuery < ApplicationQuery
    include GroupedQuery

    has_groups(
      critical: :critical,
      high: :high_priority,
      medium: :medium_priority,
      low: :low_priority
    )

    def initialize(relation = default_relation, options: {})
      super(relation)
      @options = options
    end

    # Returns all invoices needing follow-up across all priority levels.
    #
    # @return [ActiveRecord::Relation] invoices requiring action
    def call
      relation.where(id: all_ids)
    end

    # Groups invoices by priority level for work queues.
    #
    # @return [Hash] invoices by priority level
    alias_method :grouped_by_priority, :grouped

    # Critical priority: invoices 60+ days overdue.
    # These require immediate escalation and may become bad debt.
    #
    # @return [ActiveRecord::Relation] severely overdue invoices
    def critical
      relation
        .sent
        .where("due_at < ?", 60.days.ago.to_date)
        .order(due_at: :asc)
    end

    # High priority: invoices 30-60 days overdue.
    # These need escalated collection efforts.
    #
    # @return [ActiveRecord::Relation] significantly overdue invoices
    def high_priority
      relation
        .sent
        .where(due_at: 60.days.ago.to_date..30.days.ago.to_date)
        .order(due_at: :asc)
    end

    # Medium priority: invoices 1-30 days overdue.
    # Standard follow-up process applies.
    #
    # @return [ActiveRecord::Relation] recently overdue invoices
    def medium_priority
      relation
        .sent
        .where(due_at: 30.days.ago.to_date...Date.current)
        .order(due_at: :asc)
    end

    # Low priority: invoices due within the next 7 days.
    # Proactive reminder can help prevent late payment.
    #
    # @return [ActiveRecord::Relation] upcoming due invoices
    def low_priority
      relation
        .sent
        .where(due_at: Date.current..(Date.current + 7.days))
        .order(due_at: :asc)
    end

    # Returns invoices due today for immediate follow-up.
    #
    # @return [ActiveRecord::Relation] invoices due today
    def due_today
      relation.sent.where(due_at: Date.current)
    end

    # Returns invoices due tomorrow for proactive outreach.
    #
    # @return [ActiveRecord::Relation] invoices due tomorrow
    def due_tomorrow
      relation.sent.where(due_at: Date.current + 1.day)
    end

    # Returns invoices due this week.
    #
    # @return [ActiveRecord::Relation] invoices due this week
    def due_this_week
      relation.sent.where(due_at: Date.current..Date.current.end_of_week)
    end

    # Computes statistics for collections management.
    #
    # @return [Hash] follow-up metrics
    def stats
      {
        total_overdue: relation.overdue.count,
        total_overdue_amount: relation.overdue.sum(:total_amount),
        due_this_week: due_this_week.count,
        critical_count: critical.count,
        average_days_overdue: average_days_overdue
      }
    end

    private

    # @return [ActiveRecord::Relation] all invoices
    def default_relation
      Invoice.all
    end


    # Calculates average days overdue for all overdue invoices.
    def average_days_overdue
      overdue_invoices = relation.overdue
      return 0 if overdue_invoices.empty?

      total_days = overdue_invoices.sum do |invoice|
        (Date.current - invoice.due_at).to_i
      end

      (total_days.to_f / overdue_invoices.count).round(1)
    end
  end
end
