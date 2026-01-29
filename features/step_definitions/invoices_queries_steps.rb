# frozen_string_literal: true

# Invoice Query Step Definitions
# ==============================
# Steps for testing invoice query objects.
#
# Query Objects tested:
# - Invoices::AgingReportQuery - accounts receivable aging
# - Invoices::NeedingFollowUpQuery - collection prioritization
# - Invoices::RevenueQuery - revenue analysis and comparison
#
# Uses instance variables: @account, @customer, @report, @overdue_amount,
#                          @results, @grouped, @comparison
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a sent invoice overdue by {int} days exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, due_at: days.days.ago, issued_at: (days + 30).days.ago)
end

Given("an invoice of {int} euros overdue by {int} days exists") do |amount, days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, amount: amount, tax_amount: 0, due_at: days.days.ago, issued_at: (days + 30).days.ago)
end

Given("an invoice of {int} euros not yet due exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, amount: amount, tax_amount: 0, due_at: 10.days.from_now, issued_at: Date.current)
end

Given("an invoice overdue by {int} days exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, due_at: days.days.ago, issued_at: (days + 30).days.ago)
end

Given("an invoice due in {int} days exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :sent, order: order, due_at: days.days.from_now, issued_at: Date.current)
end

Given("a paid invoice of {int} euros this month exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: Date.current)
end

Given("a paid invoice of {int} euros last month exists") do |amount|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  order = create(:order, :validated, account: @account, customer: @customer)
  create(:invoice, :paid, order: order, amount: amount, tax_amount: 0, paid_at: 1.month.ago)
end

# ===== Action Steps =====

When("I generate the aging report") do
  @report = Invoices::AgingReportQuery.new(@account.invoices).summary
end

When("I calculate total overdue amount") do
  @overdue_amount = Invoices::AgingReportQuery.new(@account.invoices).total_overdue_amount
end

When("I search for critical invoices") do
  @results = Invoices::NeedingFollowUpQuery.new(@account.invoices).critical
end

When("I search for invoices to follow up this week") do
  @results = Invoices::NeedingFollowUpQuery.new(@account.invoices).due_this_week
end

When("I group invoices by priority") do
  @grouped = Invoices::NeedingFollowUpQuery.new(@account.invoices).grouped_by_priority
end

When("I compare revenue with the previous month") do
  @comparison = Invoices::RevenueQuery.new(@account.invoices).comparison(
    current_period: :this_month,
    previous_period: :last_month
  )
end

# ===== Assertion Steps =====

Then("I see {int} invoice in the 1-30 days bracket") do |count|
  expect(@report[:days_1_30][:count]).to eq(count)
end

Then("I see {int} invoice in the 31-60 days bracket") do |count|
  expect(@report[:days_31_60][:count]).to eq(count)
end

Then("I see {int} invoice in the over 90 days bracket") do |count|
  expect(@report[:over_90][:count]).to eq(count)
end

Then("the overdue amount is {int} euros") do |amount|
  expect(@overdue_amount).to eq(amount.to_f)
end

Then("I find {int} critical invoice") do |count|
  expect(@results.count).to eq(count)
end

Then("I find {int} invoice to follow up") do |count|
  expect(@results.count).to eq(count)
end

Then("I see {int} critical invoice(s)") do |count|
  expect(@grouped[:critical].count).to eq(count)
end

Then("I see {int} high priority invoice") do |count|
  expect(@grouped[:high].count).to eq(count)
end

Then("I see {int} medium priority invoice") do |count|
  expect(@grouped[:medium].count).to eq(count)
end

Then("I see {int} low priority invoice") do |count|
  expect(@grouped[:low].count).to eq(count)
end

Then("the current revenue is {int} euros") do |amount|
  expect(@comparison[:current]).to eq(amount.to_f)
end

Then("the previous revenue is {int} euros") do |amount|
  expect(@comparison[:previous]).to eq(amount.to_f)
end

Then("the growth is {float} percent") do |percentage|
  expect(@comparison[:growth_percentage]).to be_within(0.1).of(percentage)
end
