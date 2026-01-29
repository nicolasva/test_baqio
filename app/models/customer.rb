# frozen_string_literal: true

# Customer model representing a client who can place orders.
# Customers belong to an account and can have multiple orders.
# A customer can be identified by name, email, or a generated ID.
#
# @example Creating a customer
#   customer = Customer.create!(
#     account: account,
#     first_name: "John",
#     last_name: "Doe",
#     email: "john@example.com"
#   )
#
# @example Getting display name
#   customer.display_name # => "John Doe" or "john@example.com" or "Customer #123"
#
class Customer < ApplicationRecord
  include InvoiceAggregatable

  # ============================================
  # Associations
  # ============================================

  # The account this customer belongs to
  belongs_to :account

  # Orders placed by this customer
  # Cannot delete customer if they have orders (use restrict_with_error)
  has_many :orders, dependent: :restrict_with_error

  # All invoices for this customer's orders
  has_many :invoices, through: :orders

  # ============================================
  # Validations
  # ============================================

  # Email must be valid format if provided
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Email must be unique within the account (same email can exist in different accounts)
  validates :email, uniqueness: { scope: :account_id }, allow_blank: true

  # ============================================
  # Scopes
  # ============================================

  # Customers who have an email address
  scope :with_email, -> { where.not(email: [nil, ""]) }

  # Customers who have placed at least one order
  scope :with_orders, -> { joins(:orders).distinct }

  # Search customers by first or last name (partial match)
  # @param query [String] the search term
  # @return [ActiveRecord::Relation] matching customers
  scope :by_name, ->(query) {
    where("first_name LIKE :q OR last_name LIKE :q", q: "%#{query}%")
  }

  # ============================================
  # Instance Methods
  # ============================================

  # full_name and display_name are presentation methods
  # defined in CustomerDecorator.

  # Calculates total amount spent by this customer.
  # Only counts paid invoices (includes tax).
  #
  # @return [Float] total spent amount
  alias_method :total_spent, :total_paid_amount

  # Returns the number of orders placed by this customer.
  #
  # @return [Integer] order count
  def orders_count
    orders.count
  end
end
