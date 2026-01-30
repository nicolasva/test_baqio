# frozen_string_literal: true

# Provides invoice aggregation methods for models
# that have a `has_many :invoices` association.
#
# @example
#   class Customer < ApplicationRecord
#     has_many :invoices, through: :orders
#     include InvoiceAggregatable
#   end
#
#   customer.total_paid_amount # => 1500.0
#
module InvoiceAggregatable
  extend ActiveSupport::Concern

  # Calculates total amount from all paid invoices.
  #
  # @return [Float] total paid amount
  def total_paid_amount
    invoices.paid.sum(:total_amount)
  end

  # Semantic aliases for use in different contexts:
  # - total_spent: for Customer (how much they spent)
  # - total_revenue: for Account (how much revenue it generated)
  alias_method :total_spent, :total_paid_amount
  alias_method :total_revenue, :total_paid_amount
end
