# frozen_string_literal: true

# Integration/Complete Workflow Step Definitions
# ==============================================
# Steps for end-to-end integration tests.
#
# Covers:
# - Complete sales workflow from order to payment
# - Invoiced orders with sent invoices
# - Customer spending totals
# - Batch shipment operations
#
# Uses instance variables: @account, @customer, @order, @invoice, @fulfillment, @fulfillments
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("an invoiced order with sent invoice exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :invoiced, account: @account, customer: @customer, total_amount: 100.0)
  @invoice = create(:invoice, :sent, order: @order, amount: 100.0, tax_amount: 0)
end

Given("a validated order for the customer exists") do
  @order = create(:order, :validated, account: @account, customer: @customer, total_amount: 0)
end

Given("another validated order for the customer exists") do
  @order = create(:order, :validated, account: @account, customer: @customer, total_amount: 0)
end

Given("the order is invoiced and paid with an amount of {int} euros") do |amount|
  @order.update!(total_amount: amount.to_f)
  invoice = Invoice::Create.new(order: @order, type: :debit).call
  invoice.send_to_customer!
  invoice.mark_as_paid!
end

Given("{int} pending shipments exist") do |count|
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillments = create_list(:fulfillment, count, :pending, fulfillment_service: @fulfillment_service)
end

# ===== Action Steps =====

When("I create an order for the customer") do
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)
end

When("I create {int} orders for the customer") do |count|
  create_list(:order, count, account: @account, customer: @customer)
end

When("I create a shipment for the order") do
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :pending, fulfillment_service: @fulfillment_service)
  @order.update!(fulfillment: @fulfillment)
end

When("I move all shipments to processing") do
  @fulfillments.each { |f| f.update!(status: "processing") }
end

When("I ship all shipments") do
  @fulfillments.each_with_index do |f, i|
    f.ship!(tracking_number: "TRACK#{i + 1}", carrier: "Test")
  end
end

When("I add the following lines:") do |table|
  table.hashes.each do |row|
    @order.add_line(
      name: row["name"],
      quantity: row["quantity"].to_i,
      unit_price: row["unit price"].to_f
    )
  end
  @order.update_total!
end

# ===== Assertion Steps =====

Then("the invoice has status {string}") do |status|
  invoice = @invoice || @order.invoice
  expect(invoice.reload.status).to eq(status)
end

Then("the customer has {int} order(s) total") do |count|
  expect(@customer.orders.count).to eq(count)
end

Then("the customer orders text displays {string}") do |text|
  expect(@customer.decorate.orders_count_text).to eq(text)
end

Then("all shipments have status {string}") do |status|
  @fulfillments.each do |f|
    expect(f.reload.status).to eq(status)
  end
end
