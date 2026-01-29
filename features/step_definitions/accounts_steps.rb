# frozen_string_literal: true

# Account Management Step Definitions
# ===================================
# Steps for testing multi-tenant account operations.
#
# Covers:
# - Account creation and validation
# - Revenue calculation from paid invoices
# - Active order counting
# - Account search by name
#
# Uses instance variables: @account, @results, @account_valid
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("an account {string} exists") do |name|
  @account = create(:account, name: name)
end

Given("the account has a paid invoice of {int} euros") do |amount|
  customer = create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: customer)
  create(:invoice, :paid, order: order, amount: amount.to_f, tax_amount: 0)
end

Given("the account has an unpaid invoice of {int} euros") do |amount|
  customer = create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: customer)
  create(:invoice, :sent, order: order, amount: amount.to_f, tax_amount: 0)
end

Given("the account has {int} orders with status {string}") do |count, status|
  customer = @customer || create(:customer, account: @account)
  create_list(:order, count, status.to_sym, account: @account, customer: customer)
end

Given("the following accounts exist:") do |table|
  table.hashes.each do |row|
    create(:account, name: row["name"])
  end
end

# ===== Action Steps =====

When("I create an account named {string}") do |name|
  @account = create(:account, name: name)
end

When("I try to create an account without name") do
  @account = Account.new(name: nil)
  @account_valid = @account.save
end

When("I search accounts by {string}") do |query|
  @results = Account.by_name(query)
end

# ===== Assertion Steps =====

Then("account {string} exists") do |name|
  expect(@account.name).to eq(name)
end

Then("the account is not created") do
  expect(@account_valid).to be false
  expect(@account.errors[:name]).to include("can't be blank")
end

Then("the account revenue is {int} euros") do |amount|
  expect(@account.total_revenue).to eq(amount.to_f)
end

Then("the account has {int} active orders") do |count|
  expect(@account.active_orders.count).to eq(count)
end

Then("I find {int} accounts") do |count|
  expect(@results.count).to eq(count)
end
