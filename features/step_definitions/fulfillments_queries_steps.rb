# frozen_string_literal: true

# Fulfillment Query Step Definitions
# ==================================
# Steps for testing fulfillment/shipment query objects.
#
# Query Objects tested:
# - Fulfillments::PerformanceQuery - transit time and delivery rates
# - Fulfillments::DelayedQuery - stuck and delayed shipments
# - Fulfillments::TrackingQuery - search and filter by tracking/carrier
#
# Uses instance variables: @account, @fulfillment_service, @average_transit,
#                          @on_time_rate, @distribution, @query, @delay_stats,
#                          @found_fulfillment, @carrier_results, @active_results
#

# ===== Context Steps =====
# Steps that set up test data (Given...)

Given("a shipment delivered in {int} day(s) exists") do |days|
  @account ||= create(:account)
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  create(:fulfillment, fulfillment_service: @fulfillment_service,
    status: "delivered",
    shipped_at: (days + 1).days.ago,
    delivered_at: 1.day.ago,
    tracking_number: "TRACK#{SecureRandom.hex(4).upcase}"
  )
end

Given("a pending shipment created {int} day(s) ago exists") do |days|
  @account ||= create(:account)
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  fulfillment = create(:fulfillment, :pending, fulfillment_service: @fulfillment_service)
  fulfillment.update_column(:created_at, days.days.ago)
end

Given("a shipment shipped {int} days ago not delivered exists") do |days|
  @account ||= create(:account)
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  create(:fulfillment, fulfillment_service: @fulfillment_service,
    status: "shipped",
    shipped_at: days.days.ago,
    tracking_number: "TRACK#{SecureRandom.hex(4).upcase}"
  )
end

# Using the step from tracking_steps.rb for "a shipment with tracking number {string} exists"

Given("a shipment with carrier {string} exists") do |carrier|
  @account ||= create(:account)
  @fulfillment_service ||= create(:fulfillment_service, account: @account)
  create(:fulfillment, :shipped, fulfillment_service: @fulfillment_service,
    carrier: carrier,
    tracking_number: "TRACK#{SecureRandom.hex(4).upcase}"
  )
end

# ===== Action Steps =====

When("I calculate average transit time") do
  @average_transit = Fulfillments::PerformanceQuery.new(@fulfillment_service.fulfillments).average_transit_time
end

When("I calculate on-time delivery rate") do
  @on_time_rate = Fulfillments::PerformanceQuery.new(@fulfillment_service.fulfillments).on_time_delivery_rate
end

When("I analyze transit time distribution") do
  @distribution = Fulfillments::PerformanceQuery.new(@fulfillment_service.fulfillments).transit_time_distribution
end

When("I search for stuck shipments") do
  @query = Fulfillments::DelayedQuery.new(@fulfillment_service.fulfillments)
  @stuck_pending = @query.stuck_in_pending
end

When("I search for delivery delayed shipments") do
  @query = Fulfillments::DelayedQuery.new(@fulfillment_service.fulfillments)
  @shipping_delayed = @query.shipping_taking_too_long
end

When("I request delay statistics") do
  @delay_stats = Fulfillments::DelayedQuery.new(@fulfillment_service.fulfillments).stats
end

When("I search for shipment with number {string}") do |tracking|
  @found_fulfillment = Fulfillments::TrackingQuery.new(@fulfillment_service.fulfillments).by_tracking_number(tracking)
end

When("I filter shipments by carrier {string}") do |carrier|
  @carrier_results = Fulfillments::TrackingQuery.new(@fulfillment_service.fulfillments).by_carrier(carrier)
end

When("I list active shipments") do
  @active_results = Fulfillments::TrackingQuery.new(@fulfillment_service.fulfillments).active
end

# ===== Assertion Steps =====

Then("the average transit time is {int} days") do |days|
  expect(@average_transit).to eq(days.to_f)
end

Then("the on-time delivery rate is {float} percent") do |rate|
  expect(@on_time_rate).to be_within(0.1).of(rate)
end

Then("I see {int} delivery in 1 day") do |count|
  expect(@distribution["1 day"]).to eq(count)
end

Then("I see {int} delivery in 2-3 days") do |count|
  expect(@distribution["2-3 days"]).to eq(count)
end

Then("I see {int} delivery in 4-5 days") do |count|
  expect(@distribution["4-5 days"]).to eq(count)
end

Then("I see {int} delivery in more than 8 days") do |count|
  expect(@distribution["8+ days"]).to eq(count)
end

Then("I find {int} shipment stuck in pending") do |count|
  expect(@stuck_pending.count).to eq(count)
end

Then("I find {int} delivery delayed shipment") do |count|
  expect(@shipping_delayed.count).to eq(count)
end

Then("the total delayed shipments count is {int}") do |count|
  expect(@delay_stats[:total_delayed]).to eq(count)
end

Then("I find the shipment with the correct tracking number") do
  expect(@found_fulfillment).to be_present
  expect(@found_fulfillment.tracking_number).to eq("DHL123456")
end

Then("I find {int} DHL shipments") do |count|
  expect(@carrier_results.count).to eq(count)
end

Then("I find {int} active shipments") do |count|
  expect(@active_results.count).to eq(count)
end
