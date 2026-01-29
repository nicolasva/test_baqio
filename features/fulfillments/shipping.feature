# language: en
#
# Shipment Management Feature
# ===========================
# Tests the fulfillment/shipment lifecycle for order deliveries.
#
# Fulfillment Status Flow:
#   pending -> processing -> shipped -> delivered
#   pending -> cancelled
#   processing -> cancelled
#   (shipped/delivered cannot be cancelled)
#
# Key features tested:
# - Shipment creation with 'pending' status
# - Status transitions (processing, shipped, delivered)
# - Tracking number and carrier assignment during shipping
# - Automatic timestamp recording (shipped_at, delivered_at)
# - Transit duration calculation (days between shipped and delivered)
# - Status name display for UI
# - Filtering by status (in_transit, completed)
#

Feature: Shipment management
  As a user
  I want to manage order shipments
  In order to track deliveries

  Background:
    Given an account exists
    And a delivery service "DHL Express" exists

  Scenario: Create a new shipment
    When I create a shipment
    Then the shipment has status "pending"

  Scenario: Move a shipment to processing
    Given a pending shipment exists
    When I move the shipment to processing
    Then the shipment status is "processing"

  Scenario: Ship a package with tracking number
    Given a pending shipment exists
    When I ship the package with number "DHL123456789" and carrier "DHL"
    Then the shipment status is "shipped"
    And the tracking number is "DHL123456789"
    And the carrier is "DHL"
    And the shipping date is set

  Scenario: Mark a shipment as delivered
    Given a shipped shipment exists
    When I mark the shipment as delivered
    Then the shipment status is "delivered"
    And the delivery date is set

  Scenario: Cancel a pending shipment
    Given a pending shipment exists
    When I cancel the shipment
    Then the shipment status is "cancelled"

  Scenario: Cannot cancel a delivered shipment
    Given a delivered shipment exists
    When I try to cancel the shipment
    Then the shipment status remains "delivered"

  Scenario: Calculate transit duration
    Given a shipment shipped 5 days ago
    And delivered 2 days ago
    Then the transit duration is 3 days

  Scenario: Display pending status name
    Given a shipment with status "pending" exists
    Then the status name is "Pending"

  Scenario: Display shipped status name
    Given a shipment with status "shipped" exists
    Then the status name is "Shipped"

  Scenario: Display delivered status name
    Given a shipment with status "delivered" exists
    Then the status name is "Delivered"

  Scenario: Filter shipments in transit
    Given the following shipments exist:
      | status     |
      | pending    |
      | processing |
      | shipped    |
      | delivered  |
    When I filter shipments in transit
    Then I find 2 shipments

  Scenario: Filter completed shipments
    Given the following shipments exist:
      | status     |
      | pending    |
      | shipped    |
      | delivered  |
      | cancelled  |
    When I filter completed shipments
    Then I find 2 shipments
