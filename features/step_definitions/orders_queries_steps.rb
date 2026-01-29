# frozen_string_literal: true

# Orders Query Step Definitions
# ============================
# Steps for testing order query objects.
#
# Query Objects tested:
# - Orders::FilterQuery - filtering by status, amount, date
# - Orders::NeedingAttentionQuery - stale and overdue orders
# - Orders::DashboardQuery - statistics and metrics
# - Orders::WithRevenueQuery - revenue calculations
#
# Uses instance variables: @account, @customer, @results, @query, @stats, @revenue, @average
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("the following orders exist for the account:") do |table|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)

  table.hashes.each do |row|
    if row["status"]
      create(:order, row["status"].to_sym, account: @account, customer: @customer)
    elsif row["amount"]
      create(:order, :pending, account: @account, customer: @customer, total_amount: row["amount"].to_f)
    end
  end
end

Given("an order created {int} days ago exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  create(:order, :pending, account: @account, customer: @customer, created_at: days.days.ago)
end

Given("a pending order created {int} day(s) ago exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  create(:order, :pending, account: @account, customer: @customer, created_at: days.days.ago)
end

Given("an invoiced order with overdue payment exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :invoiced, account: @account, customer: @customer)
  create(:invoice, :overdue, order: order)
end

Given("an invoiced order with current payment exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :invoiced, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, due_at: 10.days.from_now)
end

Given("{int} orders created today exist") do |count|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  create_list(:order, count, account: @account, customer: @customer, created_at: Time.current)
end

Given("{int} orders created yesterday exist") do |count|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  create_list(:order, count, account: @account, customer: @customer, created_at: 1.day.ago)
end

Given("a paid order of {int} euros this month exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :invoiced, account: @account, customer: @customer, total_amount: amount)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: Date.current)
end

Given("a paid order of {int} euros last month exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :invoiced, account: @account, customer: @customer, total_amount: amount)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: 1.month.ago)
end

Given("a paid order of {int} euros exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :invoiced, account: @account, customer: @customer, total_amount: amount)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0)
end

# ===== Action Steps =====

When("I filter orders by status {string}") do |status|
  @results = Orders::FilterQuery.new(@account.orders, filters: { status: status }).call
end

When("I filter orders with minimum amount of {int} euros") do |amount|
  @results = Orders::FilterQuery.new(@account.orders, filters: { min_amount: amount }).call
end

When("I filter orders from the last {int} days") do |days|
  @results = Orders::FilterQuery.new(@account.orders, filters: { from_date: days.days.ago }).call
end

When("I search for orders needing attention") do
  @query = Orders::NeedingAttentionQuery.new(@account.orders)
  @results = @query.call
end

When("I search for orders with overdue payment") do
  @query = Orders::NeedingAttentionQuery.new(@account.orders)
  @results = @query.invoiced_with_overdue_payment
end

When("I request today's statistics") do
  @stats = Orders::DashboardQuery.new(@account.orders, period: :today).stats
end

When("I calculate monthly revenue") do
  @revenue = Orders::WithRevenueQuery.new(@account.orders).total_revenue
  # Filter for this month only
  @revenue = @account.invoices.paid
    .where(paid_at: Time.current.all_month)
    .sum(:total_amount)
end

When("I calculate average revenue per order") do
  @average = Orders::WithRevenueQuery.new(@account.orders).average_revenue
end

# ===== Assertion Steps =====

Then("I find {int} filtered order(s)") do |count|
  expect(@results.count).to eq(count)
end

Then("I find {int} order pending too long") do |count|
  expect(@query.pending_too_long.count).to eq(count)
end

Then("I find {int} order with overdue payment") do |count|
  expect(@results.count).to eq(count)
end

Then("I see {int} orders in the statistics") do |count|
  expect(@stats[:total_orders]).to eq(count)
end

Then("the revenue is {int} euros") do |amount|
  expect(@revenue).to eq(amount.to_f)
end

Then("the average revenue is {int} euros") do |amount|
  expect(@average).to eq(amount.to_f)
end
