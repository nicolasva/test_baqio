# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :account
  belongs_to :customer
  belongs_to :fulfillment, optional: true
  has_many :order_lines, dependent: :destroy

  STATUSES = %w[
    pending
    invoiced
    validated
    cancelled
  ].freeze

  validates :reference, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES, allow_blank: false }, allow_nil: false

  STATUSES.each do |status|
    scope :"#{status}", ->{ where(status: status) }

    define_method :"#{status}?" do
      self.status == status
    end
  end

  def cancel
    return if self.cancelled?

    if self.invoiced?
      Invoice::Create.new(order).call
    elsif self.validated?
      Order::Cancellation.new(order).call
    end
  end
end
