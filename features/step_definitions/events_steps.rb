# frozen_string_literal: true

# Event Audit Trail Step Definitions
# ==================================
# Steps for testing the audit logging system.
#
# Covers:
# - Event creation with various types
# - Event filtering by type and date
# - Chronological ordering (recent first)
# - Payload storage and retrieval
#
# Uses instance variables: @account, @event, @results
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("the following events exist:") do |table|
  @account ||= create(:account)
  resource = create(:resource)

  table.hashes.each do |row|
    create(:account_event, account: @account, resource: resource, event_type: row["type"])
  end
end

Given("an event created {int} day(s) ago exists") do |days|
  @account ||= create(:account)
  resource = create(:resource)
  create(:account_event, account: @account, resource: resource, event_type: "test.event", created_at: days.days.ago)
end

Given("an event created today exists") do
  @account ||= create(:account)
  resource = create(:resource)
  create(:account_event, account: @account, resource: resource, event_type: "test.event", created_at: Time.current)
end

Given("an event created yesterday exists") do
  @account ||= create(:account)
  resource = create(:resource)
  create(:account_event, account: @account, resource: resource, event_type: "test.event", created_at: 1.day.ago)
end

# ===== Action Steps =====

When("I filter events by type {string}") do |type|
  @results = AccountEvent.by_type(type)
end

When("I retrieve recent events") do
  @results = AccountEvent.recent
end

When("I filter today's events") do
  @results = AccountEvent.today
end

When("I create an event with the following payload:") do |table|
  @account ||= create(:account)
  # Create a dummy record to use for the resource
  customer = create(:customer, account: @account)

  payload = {}
  table.hashes.each do |row|
    payload[row["key"]] = row["value"]
  end

  @event = AccountEvent.log(
    account: @account,
    record: customer,
    event_type: "test.custom",
    payload: payload
  )
end

# ===== Assertion Steps =====

Then("an event {string} is recorded") do |event_type|
  expect(AccountEvent.where(event_type: event_type)).to exist
end

Then("I find {int} event(s)") do |count|
  expect(@results.count).to eq(count)
end

Then("the first event is the most recent") do
  events = @results.to_a
  expect(events.first.created_at).to be >= events.last.created_at
end

Then("the event payload contains {string} with value {string}") do |key, value|
  expect(@event.parsed_payload[key.to_sym]).to eq(value)
end
