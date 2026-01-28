# frozen_string_literal: true

class Invoice::Create
  attr_reader :order, :status

  def initialize(order, status)
    @order = order
    @status = status
  end

  def call
    if status == 'credit'
      invoice = Invoice.create(
        order: order,
        status: 'credit'
      )
      order.update(status: 'cancelled')
      AccountEvent.create(
        account: order.account,
        resource: invoice,
        topic: 'invoice.credit.create'
      )
    else
      invoice = Invoice.create(
        order: order,
        status: 'debit'
      )
      order.update(status: 'invoiced')
      AccountEvent.create(
        account: order.account,
        resource: invoice,
        topic: 'invoice.debit.create'
      )
    end
  end
end
