# frozen_string_literal: true

# Orders Index Step Definitions
# ============================
# Steps for testing the orders list/index page.
#
# Covers:
# - Order creation with various attributes
# - Page navigation and pagination
# - Table display assertions
# - Status, customer, and fulfillment display
#
# Uses instance variables: @account, @customer, @order
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("the following orders exist:") do |table|
  @account ||= create(:account)

  table.hashes.each do |row|
    customer = create(:customer,
      account: @account,
      first_name: row["customer"].split.first,
      last_name: row["customer"].split.last
    )

    create(:order,
      account: @account,
      customer: customer,
      reference: row["reference"],
      status: row["status"],
      total_amount: row["amount"].to_f
    )
  end
end

Given("a {string} order exists") do |status|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  create(:order, account: @account, customer: customer, status: status)
end

Given("an {string} order exists") do |status|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  create(:order, account: @account, customer: customer, status: status)
end

Given("an order for this customer exists") do
  create(:order, account: @account, customer: @customer)
end

Given("an order with shipment {string} exists") do |service_name|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  fulfillment_service = create(:fulfillment_service, account: @account, name: service_name)
  fulfillment = create(:fulfillment, :shipped, fulfillment_service: fulfillment_service)
  create(:order, account: @account, customer: customer, fulfillment: fulfillment)
end

Given("an order with {int} lines and a total of {float} euros exists") do |line_count, total|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  order = create(:order, account: @account, customer: customer, total_amount: total)

  line_count.times do |i|
    create(:order_line, order: order, quantity: 1, unit_price: (total / line_count).round(2))
  end
end

Given("{int} orders exist") do |count|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  create_list(:order, count, account: @account, customer: customer)
end

# ===== Action Steps =====

When("I visit the orders page") do
  visit orders_path
end

When("I visit the orders page with page parameter {string}") do |page|
  visit orders_path(page: page)
end

# ===== Assertion Steps =====

Then("I see the orders table") do
  expect(page).to have_css("table.orders-list")
end

Then("the table is empty") do
  expect(page).to have_css("table.orders-list tbody")
  expect(page).not_to have_css("table.orders-list tbody tr")
end

Then("I see {int} order(s) in the table") do |count|
  expect(page).to have_css("table.orders-list tbody tr", count: count)
end

Then("I see reference {string}") do |reference|
  expect(page).to have_content(reference)
end

Then("I see status {string}") do |status|
  expect(page).to have_content(status)
end

Then("I see customer name {string}") do |name|
  expect(page).to have_content(name)
end

Then("I see carrier {string}") do |carrier|
  expect(page).to have_content(carrier)
end

Then("I see shipment status {string}") do |status|
  expect(page).to have_content(status)
end

Then("I see total quantity {string}") do |quantity|
  expect(page).to have_content(quantity)
end

Then("I see amount {string}") do |amount|
  # Handle different currency formats (US: $299.99, EU: 299,99 €)
  expect(page).to have_content(/#{Regexp.escape(amount)}|#{amount.gsub(",", ".")}/)
end

Then("I see pagination links") do
  has_pagination = page.has_css?("nav.pagination") || page.has_content?("page")
  expect(has_pagination).to be true
end
