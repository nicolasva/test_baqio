# frozen_string_literal: true

# Customer Query Step Definitions
# ===============================
# Steps for testing customer query objects.
#
# Query Objects tested:
# - Customers::SearchQuery - text search and filtering
# - Customers::TopSpendersQuery - ranking by spending
# - Customers::InactiveQuery - churn detection and segmentation
#
# Uses instance variables: @account, @results, @top_results, @top_stats,
#                          @top_customer, @segmented
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("customer {string} with {int} order(s) exists") do |name, count|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  customer = create(:customer, account: @account, first_name: first_name, last_name: last_name)
  create_list(:order, count, account: @account, customer: customer)
end

Given("customer {string} without orders exists") do |name|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  create(:customer, account: @account, first_name: first_name, last_name: last_name)
end

Given("customer {string} having spent {int} euros exists") do |name, amount|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  customer = create(:customer, account: @account, first_name: first_name, last_name: last_name)
  order = create(:order, :validated, account: @account, customer: customer)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0)
end

Given("customer {string} having spent {int} euros in {int} orders exists") do |name, amount, orders_count|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  customer = create(:customer, account: @account, first_name: first_name, last_name: last_name)
  amount_per_order = amount.to_f / orders_count
  orders_count.times do
    order = create(:order, :validated, account: @account, customer: customer)
    create(:invoice, :paid, order: order, amount: amount_per_order, tax_amount: 0)
  end
  @top_customer = customer
end

Given("customer {string} with last order {int} months ago exists") do |name, months|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  customer = create(:customer, account: @account, first_name: first_name, last_name: last_name)
  create(:order, account: @account, customer: customer, created_at: months.months.ago)
end

Given("customer {string} with last order {int} week(s) ago exists") do |name, weeks|
  @account ||= create(:account)
  first_name, last_name = name.split(" ", 2)
  customer = create(:customer, account: @account, first_name: first_name, last_name: last_name)
  create(:order, account: @account, customer: customer, created_at: weeks.weeks.ago)
end

Given("a customer with last order {int} days ago exists") do |days|
  @account ||= create(:account)
  customer = create(:customer, account: @account)
  create(:order, account: @account, customer: customer, created_at: days.days.ago)
end

# ===== Action Steps =====

When("I search customers with term {string}") do |term|
  @results = Customers::SearchQuery.new(@account.customers, params: { q: term }).call
end

When("I filter customers having orders") do
  @results = Customers::SearchQuery.new(@account.customers, params: { has_orders: true }).call
end

When("I search for the top {int} customers") do |limit|
  @top_results = Customers::TopSpendersQuery.new(@account.customers, limit: limit).call.to_a
end

When("I request top customer statistics") do
  @top_stats = Customers::TopSpendersQuery.new(@account.customers, limit: 1).with_stats.first
end

When("I search for customers who never ordered") do
  @results = Customers::InactiveQuery.new(@account.customers).never_ordered
end

When("I search for inactive customers") do
  @results = Customers::InactiveQuery.new(@account.customers).no_recent_orders
end

When("I segment customers by inactivity") do
  @segmented = Customers::InactiveQuery.new(@account.customers).segmented
end

# ===== Assertion Steps =====

Then("I find {int} customers in the search") do |count|
  expect(@results.count).to eq(count)
end

Then("I find {int} customer with orders") do |count|
  expect(@results.count).to eq(count)
end

Then("the first customer is {string}") do |name|
  first_name, last_name = name.split(" ", 2)
  expect(@top_results.first.first_name).to eq(first_name)
  expect(@top_results.first.last_name).to eq(last_name)
end

Then("the second customer is {string}") do |name|
  first_name, last_name = name.split(" ", 2)
  expect(@top_results.second.first_name).to eq(first_name)
  expect(@top_results.second.last_name).to eq(last_name)
end

Then("the total spent is {int} euros") do |amount|
  expect(@top_stats[:total_spent]).to eq(amount.to_f)
end

Then("the average order value is {int} euros") do |amount|
  expect(@top_stats[:average_order_value]).to eq(amount.to_f)
end

Then("I find {int} customers without orders") do |count|
  expect(@results.count).to eq(count)
end

Then("I find {int} inactive customer") do |count|
  expect(@results.to_a.size).to eq(count)
end

Then("I see {int} customer inactive for 30-60 days") do |count|
  expect(@segmented[:inactive_30_60_days].to_a.size).to eq(count)
end

Then("I see {int} customer inactive for 60-90 days") do |count|
  expect(@segmented[:inactive_60_90_days].to_a.size).to eq(count)
end

Then("I see {int} customer inactive for 90-180 days") do |count|
  expect(@segmented[:inactive_90_180_days].to_a.size).to eq(count)
end
