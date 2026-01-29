# frozen_string_literal: true

# Fulfillment/Shipment Step Definitions
# =====================================
# Steps for testing shipment lifecycle management.
#
# Covers:
# - Shipment creation and status transitions
# - Shipping with tracking number and carrier
# - Delivery confirmation
# - Cancellation rules
# - Transit duration calculations
# - Filtering by status (in_transit, completed)
#
# Uses instance variables: @account, @fulfillment_service, @fulfillment, @results
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a delivery service {string} exists") do |name|
  @account ||= create(:account)
  @fulfillment_service = create(:fulfillment_service, account: @account, name: name)
end

Given("a pending shipment exists") do
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :pending, fulfillment_service: @fulfillment_service)
end

Given("a shipped shipment exists") do
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :shipped, fulfillment_service: @fulfillment_service)
end

Given("a delivered shipment exists") do
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :delivered, fulfillment_service: @fulfillment_service)
end

Given("a shipment with status {string} exists") do |status|
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  attrs = {}
  # Add tracking number for in-transit statuses so they appear in tracking queries
  if %w[processing shipped].include?(status)
    attrs[:tracking_number] = "TRACK#{SecureRandom.hex(4).upcase}"
    attrs[:carrier] = @fulfillment_service.name
  end
  @fulfillment = create(:fulfillment, status.to_sym, fulfillment_service: @fulfillment_service, **attrs)
end

Given("a shipment shipped {int} days ago") do |days|
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :shipped, fulfillment_service: @fulfillment_service, shipped_at: days.days.ago)
end

Given("the following shipments exist:") do |table|
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  table.hashes.each do |row|
    create(:fulfillment, row["status"].to_sym, fulfillment_service: @fulfillment_service)
  end
end

# ===== Action Steps =====

When("I create a shipment") do
  @fulfillment = create(:fulfillment, :pending, fulfillment_service: @fulfillment_service)
end

When("I move the shipment to processing") do
  @fulfillment.update!(status: "processing")
end

When("I ship the package with number {string} and carrier {string}") do |tracking, carrier|
  @fulfillment.ship!(tracking_number: tracking, carrier: carrier)
end

When("I mark the shipment as delivered") do
  @fulfillment.deliver!
end

When("I cancel the shipment") do
  @fulfillment.cancel!
end

When("I try to cancel the shipment") do
  @result = @fulfillment.cancel!
end

When("I filter shipments in transit") do
  @results = Fulfillment.in_transit
end

When("I filter completed shipments") do
  @results = Fulfillment.completed
end

# ===== Assertion Steps =====

Then("the shipment has status {string}") do |status|
  expect(@fulfillment.reload.status).to eq(status)
end

Then("the shipment status is {string}") do |status|
  expect(@fulfillment.reload.status).to eq(status)
end

Then("the shipment status remains {string}") do |status|
  expect(@fulfillment.reload.status).to eq(status)
end

Then("the tracking number is {string}") do |tracking|
  expect(@fulfillment.reload.tracking_number).to eq(tracking)
end

Then("the carrier is {string}") do |carrier|
  expect(@fulfillment.reload.carrier).to eq(carrier)
end

Then("the shipping date is set") do
  expect(@fulfillment.reload.shipped_at).to be_present
end

Then("the delivery date is set") do
  expect(@fulfillment.reload.delivered_at).to be_present
end

Then("the transit duration is {int} days") do |days|
  expect(@fulfillment.transit_duration).to eq(days)
end

Then("the status name is {string}") do |status_name|
  expect(@fulfillment.decorate.status_name).to eq(status_name)
end

Then("I find {int} shipment(s)") do |count|
  expect(@results.count).to eq(count)
end
