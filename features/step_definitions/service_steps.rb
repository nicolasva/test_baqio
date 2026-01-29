# frozen_string_literal: true

# Service Base Step Definitions
# =============================
# Steps for testing the Service module base functionality.
#
# Covers:
# - Service execution and result handling
# - Error collection and retrieval
# - Message logging
# - Callback system
# - Integration with real services
#
# Uses instance variables: @service, @service_class, @callback_results, @error_raised
#

# ===== Test Service Classes =====

# Simple success service
class CucumberSuccessService < Service::Base
  def call
    @return_value || "default"
  end
end

# Service with arguments
class CucumberArgsService < Service::Base
  def call
    "#{@name} - #{@value}"
  end
end

# Service that adds one error
class CucumberSingleErrorService < Service::Base
  def call
    append_error(@error_type || :generic, @error_message || "An error occurred")
    nil
  end
end

# Service that adds multiple errors
class CucumberMultiErrorService < Service::Base
  def call
    append_error(:validation, "Invalid input")
    append_error(:database, "Connection failed")
    nil
  end
end

# Service that logs messages
class CucumberMessageService < Service::Base
  def call
    append_message(@log_message || "Default message")
    "done"
  end
end

# Service with callbacks
class CucumberCallbackService < Service::Base
  def call
    call_back(:on_complete, "result_data")
    "completed"
  end
end

# Service that calls undefined callback
class CucumberMissingCallbackService < Service::Base
  def call
    call_back(:undefined_callback)
  end
end

# ===== Context Steps =====

Given("a service that returns {string}") do |value|
  @service_class = CucumberSuccessService
  @service_args = { return_value: value }
end

Given("a service that concatenates name and value") do
  @service_class = CucumberArgsService
end

Given("a service that adds an error") do
  @service_class = CucumberSingleErrorService
  @service_args = {}
end

Given("a service that adds multiple errors") do
  @service_class = CucumberMultiErrorService
  @service_args = {}
end

Given("a service that adds an error of type {string} with message {string}") do |type, message|
  @service_class = CucumberSingleErrorService
  @service_args = { error_type: type.to_sym, error_message: message }
end

Given("a service that logs a message {string}") do |message|
  @service_class = CucumberMessageService
  @service_args = { log_message: message }
end

Given("a service with an on_complete callback") do
  @service_class = CucumberCallbackService
  @service_args = {}
end

Given("a service that calls back with arguments") do
  @service_class = CucumberCallbackService
  @service_args = {}
end

Given("a service that calls an undefined callback") do
  @service_class = CucumberMissingCallbackService
  @service_args = {}
end

Given("an account and a validated order exist") do
  @account = create(:account)
  @customer = create(:customer, account: @account)
  @order = create(:order, :validated, account: @account, customer: @customer, total_amount: 100.0)
end

# ===== Action Steps =====

When("I call the service") do
  @service = @service_class.call(**(@service_args || {}))
end

When("I call the service with name {string} and value {string}") do |name, value|
  @service = @service_class.call(name: name, value: value)
end

When("I call the service with a callback that records {string}") do |message|
  @callback_results = []
  @service = @service_class.call(**(@service_args || {})) do |c|
    c.on_complete { @callback_results << message }
  end
end

When("I call the service with a callback that captures arguments") do
  @callback_results = []
  @service = @service_class.call(**(@service_args || {})) do |c|
    c.on_complete { |arg| @callback_results << arg }
  end
end

When("I call the service without registering the callback") do
  @error_raised = nil
  begin
    @service = @service_class.call(**(@service_args || {}))
  rescue NoMethodError => e
    @error_raised = e
  end
end

When("I create an invoice using Invoice::Create service") do
  @service = Invoice::Create.call(order: @order, type: :debit)
end

When("I cancel the order using Order::Cancellation service") do
  @service = Order::Cancellation.call(order: @order)
end

# ===== Assertion Steps =====

Then("the service result is {string}") do |expected|
  expect(@service.result).to eq(expected)
end

Then("the service is successful") do
  expect(@service.successful?).to be true
end

Then("the service is not successful") do
  expect(@service.successful?).to be false
end

Then("the service has {int} error(s)") do |count|
  expect(@service.errors.size).to eq(count)
end

Then("the first error type is {string}") do |type|
  expect(@service.errors.first.type).to eq(type.to_sym)
end

Then("the first error message is {string}") do |message|
  expect(@service.errors.first.message).to eq(message)
end

Then("the service error type is {string}") do |type|
  expect(@service.error.type).to eq(type.to_sym)
end

Then("the service error message is {string}") do |message|
  expect(@service.error.message).to eq(message)
end

Then("the service has {int} message(s)") do |count|
  expect(@service.messages.size).to eq(count)
end

Then("the first message is {string}") do |message|
  expect(@service.messages.first.message).to eq(message)
end

Then("the first message has a timestamp") do
  expect(@service.messages.first.time).to be_a(Time)
end

Then("the callback recorded {string}") do |message|
  expect(@callback_results).to include(message)
end

Then("the callback received argument {string}") do |arg|
  expect(@callback_results).to include(arg)
end

Then("a NoMethodError is raised") do
  expect(@error_raised).to be_a(NoMethodError)
end

Then("the service returns an Invoice") do
  expect(@service.result).to be_a(Invoice)
end

Then("the invoice is persisted") do
  expect(@service.result).to be_persisted
end

# Note: "the order status is {string}" is defined in orders_workflow_steps.rb
