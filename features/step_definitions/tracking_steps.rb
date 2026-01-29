# frozen_string_literal: true

# Shipment Tracking Step Definitions
# ==================================
# Steps for testing tracking number management and validation.
#
# Covers:
# - Tracking number assignment
# - Shipping without/with carrier
# - Transit duration with specific dates
# - Tracking number uniqueness validation
# - Status transition restrictions
#
# Uses instance variables: @fulfillment_service, @fulfillment, @original_tracking
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a shipment with tracking number {string} exists") do |tracking_number|
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  @fulfillment = create(:fulfillment, :shipped, fulfillment_service: @fulfillment_service, tracking_number: tracking_number)
end

Given("delivered today") do
  @fulfillment.update!(status: "delivered", delivered_at: Time.current)
end

Given("delivered {int} day(s) ago") do |days|
  @fulfillment.update!(status: "delivered", delivered_at: days.days.ago)
end

# ===== Action Steps =====

When("I ship the package with number {string}") do |tracking|
  @fulfillment.ship!(tracking_number: tracking)
end

When("I try to ship the package with number {string}") do |tracking|
  @original_tracking = @fulfillment.tracking_number
  @result = @fulfillment.ship!(tracking_number: tracking)
end

When("I try to mark the shipment as delivered") do
  @result = @fulfillment.deliver!
end

When("I try to create a shipment with the same tracking number") do
  @new_fulfillment = Fulfillment.new(
    fulfillment_service: @fulfillment_service,
    tracking_number: @fulfillment.tracking_number,
    status: "pending"
  )
  @fulfillment_valid = @new_fulfillment.save
end

# ===== Assertion Steps =====

Then("the carrier is empty") do
  expect(@fulfillment.reload.carrier).to be_blank
end

Then("the tracking number remains unchanged") do
  expect(@fulfillment.reload.tracking_number).to eq(@original_tracking)
end

Then("the shipment is not created") do
  expect(@fulfillment_valid).to be false
end

Then("the shipment is in transit") do
  expect(@fulfillment.in_transit?).to be true
end

Then("the shipment is completed") do
  expect(@fulfillment.completed?).to be true
end
