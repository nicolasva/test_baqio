# frozen_string_literal: true

# Invoice Payment Step Definitions
# ================================
# Steps for testing payment processing and due date tracking.
#
# Covers:
# - Payment with specific dates
# - Due date scenarios (overdue, due today, due soon)
# - Filtering invoices by payment status
# - Days overdue/until due calculations
#
# Uses instance variables: @account, @customer, @order, @invoice, @results
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a sent invoice with due date {int} days ago exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :sent, order: @order, issued_at: (days + 30).days.ago.to_date, due_at: days.days.ago.to_date)
end

Given("a sent invoice with due date today exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :sent, order: @order, issued_at: 30.days.ago.to_date, due_at: Date.current)
end

Given("the following invoices exist:") do |table|
  @account ||= create(:account)

  table.hashes.each do |row|
    customer = create(:customer, account: @account)
    order = create(:order, :validated, account: @account, customer: customer)

    due_date = case row["due date"]
    when /(\d+) days ago/
      $1.to_i.days.ago.to_date
    when /in (\d+) days/
      $1.to_i.days.from_now.to_date
    else
      Date.current
    end

    create(:invoice, row["status"].to_sym, order: order, issued_at: 30.days.ago.to_date, due_at: due_date)
  end
end

# ===== Action Steps =====

When("I mark the invoice as paid on {string}") do |date|
  @invoice.mark_as_paid!(Date.parse(date))
end

When("I try to mark the invoice as paid") do
  @result = @invoice.mark_as_paid!
end

When("I filter overdue invoices") do
  @results = Invoice.overdue
end

When("I filter invoices due soon") do
  @results = Invoice.due_soon
end

# ===== Assertion Steps =====

Then("the payment date is {string}") do |date|
  expect(@invoice.reload.paid_at).to eq(Date.parse(date))
end

Then("the days overdue is {int}") do |days|
  expect(@invoice.days_overdue).to eq(days)
end

Then("the days until due is {int}") do |days|
  expect(@invoice.days_until_due).to eq(days)
end

Then("the invoice is not yet overdue") do
  expect(@invoice.overdue?).to be false
end

Then("I find {int} overdue invoices") do |count|
  expect(@results.count).to eq(count)
end

Then("I find {int} invoices due soon") do |count|
  expect(@results.count).to eq(count)
end
