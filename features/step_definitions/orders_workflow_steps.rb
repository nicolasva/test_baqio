# frozen_string_literal: true

# Orders Workflow Step Definitions
# ================================
# Steps for testing the complete order lifecycle.
#
# Covers:
# - Order creation and status transitions
# - Order validation, invoicing, and cancellation
# - Order line management
# - Status display and decorators
#
# Uses instance variables: @account, @customer, @order
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a pending order exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer)
end

Given("a validated order exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :validated, account: @account, customer: @customer, total_amount: 100.0)
end

Given("an invoiced order exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :invoiced, account: @account, customer: @customer, total_amount: 100.0)
  create(:invoice, order: @order, amount: 100.0)
end

Given("an order with status {string} exists") do |status|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, status.to_sym, account: @account, customer: @customer)
end

Given("an order with the following lines:") do |table|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)

  total = 0
  table.hashes.each do |row|
    quantity = row["quantity"].to_i
    unit_price = row["unit price"].to_f
    line_total = quantity * unit_price
    total += line_total

    create(:order_line,
      order: @order,
      name: row["name"],
      quantity: quantity,
      unit_price: unit_price,
      total_price: line_total
    )
  end

  @order.update!(total_amount: total)
end

Given("an order with {int} line(s) exists") do |count|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer)
  create_list(:order_line, count, order: @order)
  @order.update_total!
end

Given("an order without lines exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)
end

# ===== Action Steps =====

When("I create an order") do
  @order = create(:order, :pending, account: @account, customer: @customer)
end

When("I validate the order") do
  @order.validate!
end

When("I try to validate the order") do
  @result = @order.validate!
end

When("I invoice the order") do
  @order.invoice!
end

When("I cancel the order") do
  @order.cancel!
end

When("I add a line with:") do |table|
  row = table.hashes.first
  @order.add_line(
    name: row["name"],
    quantity: row["quantity"].to_i,
    unit_price: row["unit price"].to_f
  )
  @order.update_total!
end

# ===== Assertion Steps =====

Then("the order has status {string}") do |status|
  expect(@order.reload.status).to eq(status)
end

Then("the order status is {string}") do |status|
  expect(@order.reload.status).to eq(status)
end

Then("the order status remains {string}") do |status|
  expect(@order.reload.status).to eq(status)
end

Then("the order has an automatically generated reference") do
  expect(@order.reference).to match(/^ORD-\d{8}-[A-Z0-9]+$/)
end

Then("an invoice is created for the order") do
  expect(@order.reload.invoice).to be_present
end

Then("a credit note is created") do
  invoice = Invoice.last
  expect(invoice.number).to start_with("CN-")
end

Then("an event {string} is created") do |event_type|
  expect(AccountEvent.where(event_type: event_type)).to exist
end

Then("the order has {int} line(s)") do |count|
  expect(@order.reload.order_lines.count).to eq(count)
end

Then("the order total is {int} euros") do |total|
  expect(@order.reload.total_amount).to eq(total.to_f)
end

Then("the order total is approximately {float} euros") do |total|
  expect(@order.reload.total_amount).to be_within(0.01).of(total)
end

Then("the summary displays {string}") do |text|
  expect(@order.decorate.lines_summary).to eq(text)
end

Then("the order is empty") do
  expect(@order.empty?).to be true
end

Then("the order status name is {string}") do |status_name|
  expect(@order.decorate.status_name).to eq(status_name)
end
