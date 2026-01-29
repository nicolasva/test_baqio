# frozen_string_literal: true

# Invoice Lifecycle Step Definitions
# ==================================
# Steps for testing invoice creation and status transitions.
#
# Covers:
# - Invoice creation (standard and credit notes)
# - Status transitions (draft -> sent -> paid)
# - Invoice cancellation
# - Due date and overdue detection
# - Amount calculations with VAT
#
# Uses instance variables: @account, @customer, @order, @invoice
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a customer exists") do
  @account ||= create(:account)
  @customer = create(:customer, account: @account)
end

Given("a draft invoice exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :draft, order: @order)
end

Given("a sent invoice exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :sent, order: @order)
end

Given("a paid invoice exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :paid, order: @order)
end

Given("a sent invoice with past due date exists") do
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :overdue, order: @order)
end

Given("a sent invoice with due date in {int} days exists") do |days|
  @account ||= create(:account)
  @customer ||= create(:customer, account: @account)
  @order ||= create(:order, :validated, account: @account, customer: @customer)
  @invoice = create(:invoice, :sent, order: @order, issued_at: 25.days.ago.to_date, due_at: days.days.from_now.to_date)
end

# ===== Action Steps =====

When("I create an invoice for the order") do
  @invoice = Invoice::Create.new(order: @order, type: :debit).call
end

When("I create a credit note for the order") do
  @invoice = Invoice::Create.new(order: @order, type: :credit).call
end

When("I send the invoice to the customer") do
  @invoice ||= @order.invoice
  @invoice.send_to_customer!
end

When("I mark the invoice as paid") do
  @invoice ||= @order.invoice
  @invoice.mark_as_paid!
end

When("I cancel the invoice") do
  @invoice.cancel!
end

When("I try to cancel the invoice") do
  @result = @invoice.cancel!
end

When("I create an invoice with an amount of {int} euros and VAT of {int} euros") do |amount, tax|
  @invoice = create(:invoice, order: @order, amount: amount.to_f, tax_amount: tax.to_f)
end

# ===== Assertion Steps =====

Then("a {string} invoice is created") do |status|
  expect(@invoice).to be_present
  expect(@invoice.status).to eq(status)
end

Then("the invoice has a number starting with {string}") do |prefix|
  expect(@invoice.number).to start_with(prefix)
end

Then("an invoice with number starting with {string} is created") do |prefix|
  expect(@invoice.number).to start_with(prefix)
end

Then("the invoice status is {string}") do |status|
  expect(@invoice.reload.status).to eq(status)
end

Then("the invoice status remains {string}") do |status|
  expect(@invoice.reload.status).to eq(status)
end

Then("the issue date is today") do
  expect(@invoice.reload.issued_at).to eq(Date.current)
end

Then("the due date is in {int} days") do |days|
  expect(@invoice.reload.due_at).to eq(Date.current + days.days)
end

Then("the payment date is today") do
  expect(@invoice.reload.paid_at).to eq(Date.current)
end

Then("the invoice total amount is {int} euros") do |total|
  expect(@invoice.total_amount).to eq(total.to_f)
end

Then("the invoice is overdue") do
  expect(@invoice.overdue?).to be true
end

Then("the days overdue are displayed") do
  expect(@invoice.days_overdue).to be > 0
end

Then("the invoice is due soon") do
  expect(@invoice.days_until_due).to be <= 7
  expect(@invoice.days_until_due).to be >= 0
end
