# frozen_string_literal: true

class Order::Cancellation
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def call
    order.update!(status: 'cancelled')
  end
end
