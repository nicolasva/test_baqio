# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrdersHelper, type: :helper do
  describe "#order_reference_link" do
    it "returns a link to the order with its reference" do
      account = create(:account)
      customer = create(:customer, account: account)
      order = create(:order, account: account, customer: customer)

      result = helper.order_reference_link(order)
      expect(result).to have_css("a", text: order.reference)
      expect(result).to include(orders_path)
    end
  end
end
