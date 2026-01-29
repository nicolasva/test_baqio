# frozen_string_literal: true

# Field Change Tracking Step Definitions
# ======================================
# Steps for testing the Trackable concern that logs field modifications.
#
# Covers:
# - Order status and total_amount tracking
# - OrderLine unit_price tracking
# - Event payload verification
# - Cascading tracking effects
# - Event association and querying
#
# Uses instance variables: @account, @customer, @order, @order_line, @event, @results
#

# ===== Context Steps =====

Given("an order with status {string} and total {int} euros exists") do |status, total|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, status: status, account: @account, customer: @customer, total_amount: total.to_f)
  # Clear events created during setup
  AccountEvent.delete_all
end

Given("an order with a line at {int} euros unit price exists") do |unit_price|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)
  @order_line = create(:order_line, order: @order, unit_price: unit_price.to_f, quantity: 1)
  @order.update_total!
  # Clear events created during setup
  AccountEvent.delete_all
end

Given("an order with a line at {int} euros unit price and quantity {int} exists") do |unit_price, quantity|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order = create(:order, :pending, account: @account, customer: @customer, total_amount: 0)
  @order_line = create(:order_line, order: @order, unit_price: unit_price.to_f, quantity: quantity)
  @order.update_total!
  # Clear events created during setup
  AccountEvent.delete_all
end

Given("the following order changes have been made:") do |table|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  AccountEvent.delete_all

  orders = {}
  table.hashes.each do |row|
    order_id = row["order_id"]
    orders[order_id] ||= create(:order, :pending, account: @account, customer: @customer, total_amount: 100.0)

    case row["field"]
    when "status"
      orders[order_id].update!(status: row["new_value"])
    when "total_amount"
      orders[order_id].update!(total_amount: row["new_value"].to_f)
    end
  end
end

# ===== Action Steps (also usable as Given for chained scenarios) =====

When("I change the order status to {string}") do |status|
  @order.update!(status: status)
end

When("I change the order total to {int} euros") do |total|
  @order.update!(total_amount: total.to_f)
end

When("I change the order status to {string} and total to {int} euros") do |status, total|
  @order.update!(status: status, total_amount: total.to_f)
end

When("I change the order line unit price to {int} euros") do |unit_price|
  @order_line.update!(unit_price: unit_price.to_f)
end

When("I change the order line quantity to {int}") do |quantity|
  @order_line.update!(quantity: quantity)
end

When("I update the order notes to {string}") do |notes|
  @order.update!(notes: notes)
end

When("I retrieve recent tracking events") do
  @results = AccountEvent.where("event_type LIKE ?", "%.changed").recent
end

Given("I wait {int} second(s)") do |seconds|
  sleep(seconds)
end

# ===== Assertion Steps =====

Then("the event payload shows status changed from {string} to {string}") do |old_value, new_value|
  event = AccountEvent.find_by(event_type: "order.status.changed")
  expect(event).to be_present
  expect(event.parsed_payload[:field]).to eq("status")
  expect(event.parsed_payload[:old_value]).to eq(old_value)
  expect(event.parsed_payload[:new_value]).to eq(new_value)
end

Then("the event payload shows total_amount changed from {float} to {float}") do |old_value, new_value|
  event = AccountEvent.find_by(event_type: "order.total_amount.changed")
  expect(event).to be_present
  expect(event.parsed_payload[:field]).to eq("total_amount")
  expect(event.parsed_payload[:old_value].to_f).to eq(old_value)
  expect(event.parsed_payload[:new_value].to_f).to eq(new_value)
end

Then("the event payload shows unit_price changed from {float} to {float}") do |old_value, new_value|
  event = AccountEvent.find_by(event_type: "order_line.unit_price.changed")
  expect(event).to be_present
  expect(event.parsed_payload[:field]).to eq("unit_price")
  expect(event.parsed_payload[:old_value].to_f).to eq(old_value)
  expect(event.parsed_payload[:new_value].to_f).to eq(new_value)
end

Then("I find {int} tracking events for the order") do |count|
  events = AccountEvent.where("event_type LIKE ?", "order.%.changed")
  expect(events.count).to eq(count)
end

Then("no {string} event is recorded") do |event_type|
  expect(AccountEvent.where(event_type: event_type)).not_to exist
end

Then("the tracking event is associated with the order's account") do
  event = AccountEvent.find_by(event_type: "order.status.changed")
  expect(event).to be_present
  expect(event.account).to eq(@order.account)
end

Then("the tracking event has a resource of type {string}") do |resource_type|
  event = case resource_type
          when "Order"
            AccountEvent.find_by(event_type: "order.status.changed")
          when "OrderLine"
            AccountEvent.find_by(event_type: "order_line.unit_price.changed")
          else
            AccountEvent.where("event_type LIKE ?", "%.changed").last
          end
  expect(event).to be_present
  expect(event.resource.resource_type).to eq(resource_type)
end

Then("the first event is the total_amount change") do
  expect(@results.first.event_type).to eq("order.total_amount.changed")
end

Then("the last event is the status change") do
  expect(@results.last.event_type).to eq("order.status.changed")
end
