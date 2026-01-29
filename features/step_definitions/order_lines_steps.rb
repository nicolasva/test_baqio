# frozen_string_literal: true

# Order Lines Step Definitions
# ============================
# Steps for testing order line item management.
#
# Covers:
# - Adding lines with SKU
# - Modifying line quantities
# - Deleting lines
# - Line total price calculations
#
# Uses instance variables: @account, @customer, @order, @order_line
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("an order with a line of {int} items at {int} euros exists") do |quantity, price|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)
  @order_line = create(:order_line, order: @order, quantity: quantity, unit_price: price.to_f)
  @order.update_total!
end

# ===== Action Steps =====
# Note: "I add a line with:" is defined in orders_workflow_steps.rb

When("I add a line with SKU:") do |table|
  row = table.hashes.first
  @order_line = @order.add_line(
    name: row["name"],
    quantity: row["quantity"].to_i,
    unit_price: row["unit price"].to_f,
    sku: row["sku"]
  )
  @order.update_total!
end

When("I delete the first line") do
  @order.order_lines.first.destroy
  @order.update_total!
end

When("I modify the line quantity to {int}") do |quantity|
  @order_line.update!(quantity: quantity)
  @order.update_total!
end

# ===== Assertion Steps =====

Then("the line total price is approximately {float} euros") do |total|
  expect(@order.order_lines.last.total_price).to be_within(0.01).of(total)
end

Then("the line total price is {int} euros") do |total|
  expect(@order_line.reload.total_price).to eq(total.to_f)
end

Then("the line has SKU {string}") do |sku|
  expect(@order_line.sku).to eq(sku)
end
