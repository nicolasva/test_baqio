# frozen_string_literal: true

# Customer Management Step Definitions
# ====================================
# Steps for testing customer creation and display.
#
# Covers:
# - Customer creation with various info levels
# - Display name logic (full name, email, or ID fallback)
# - Initials generation
# - Total spent calculation
# - Order count and pluralization
# - Customer search by name
#
# Uses instance variables: @account, @customer, @results
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("an account exists") do
  @account = create(:account)
end

Given("customer {string} exists") do |full_name|
  @account ||= create(:account)
  first_name, last_name = full_name.split(" ", 2)
  @customer = create(:customer,
    account: @account,
    first_name: first_name,
    last_name: last_name
  )
end

Given("the customer has a paid invoice of {int} euros") do |amount|
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :paid, order: order, amount: amount.to_f, tax_amount: 0)
end

Given("the customer has {int} order(s)") do |count|
  create_list(:order, count, account: @account, customer: @customer)
end

Given("the following customers exist:") do |table|
  @account ||= create(:account)
  table.hashes.each do |row|
    create(:customer,
      account: @account,
      first_name: row["first name"],
      last_name: row["last name"],
      email: row["email"]
    )
  end
end

# ===== Action Steps =====

When("I create a customer with the following information:") do |table|
  row = table.hashes.first
  @customer = create(:customer,
    account: @account,
    first_name: row["first name"],
    last_name: row["last name"],
    email: row["email"],
    phone: row["phone"]
  )
end

When("I create a customer with only email {string}") do |email|
  @customer = create(:customer,
    account: @account,
    first_name: nil,
    last_name: nil,
    email: email
  )
end

When("I create a customer without name or email") do
  @customer = create(:customer,
    account: @account,
    first_name: nil,
    last_name: nil,
    email: nil
  )
end

When("I search customers by {string}") do |query|
  @results = @account.customers.by_name(query)
end

# ===== Assertion Steps =====

Then("the customer {string} exists") do |full_name|
  expect(@customer.full_name).to eq(full_name)
end

Then("the customer has email {string}") do |email|
  expect(@customer.email).to eq(email)
end

Then("the customer display name is {string}") do |display_name|
  expect(@customer.display_name).to eq(display_name)
end

Then("the customer display name contains {string}") do |text|
  expect(@customer.display_name).to include(text)
end

Then("the customer initials are {string}") do |initials|
  expect(@customer.decorate.initials).to eq(initials)
end

Then("the total spent by the customer is {int} euros") do |total|
  expect(@customer.total_spent).to eq(total.to_f)
end

Then("the orders text displays {string}") do |text|
  expect(@customer.decorate.orders_count_text).to eq(text)
end

Then("I find {int} customer(s)") do |count|
  expect(@results.count).to eq(count)
end
