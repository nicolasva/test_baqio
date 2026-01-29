# language: en
#
# Shipment Tracking Feature
# =========================
# Tests tracking number management and shipment state validation.
#
# Tracking features tested:
# - Shipping with tracking number only (no carrier)
# - Shipping with tracking number and carrier
# - Tracking number uniqueness validation
# - Prevention of re-shipping already shipped items
#
# Status transition rules:
# - Cannot deliver an unshipped package
# - Cannot cancel delivered shipments
# - Processing shipments can be cancelled
#
# Transit duration scenarios:
# - Short transit (2 days)
# - Long transit (6 days)
# - In-transit and completed status checks
#

Feature: Shipment tracking
  As a user
  I want to track my shipments
  In order to know the status of my deliveries

  Background:
    Given an account exists
    And a delivery service "Express" exists

  Scenario: Ship a package without carrier
    Given a pending shipment exists
    When I ship the package with number "TRACK001"
    Then the tracking number is "TRACK001"
    And the carrier is empty

  Scenario: Ship a package with carrier
    Given a pending shipment exists
    When I ship the package with number "TRACK002" and carrier "DHL"
    Then the tracking number is "TRACK002"
    And the carrier is "DHL"
    And the shipping date is set

  Scenario: Cannot ship an already shipped shipment
    Given a shipped shipment exists
    When I try to ship the package with number "NEWTRACK"
    Then the tracking number remains unchanged

  Scenario: Cannot deliver an unshipped shipment
    Given a pending shipment exists
    When I try to mark the shipment as delivered
    Then the shipment status remains "pending"

  Scenario: Calculate short transit duration
    Given a shipment shipped 2 days ago
    And delivered today
    Then the transit duration is 2 days

  Scenario: Calculate long transit duration
    Given a shipment shipped 7 days ago
    And delivered 1 days ago
    Then the transit duration is 6 days

  Scenario: Unique tracking number
    Given a shipment with tracking number "UNIQUE123" exists
    When I try to create a shipment with the same tracking number
    Then the shipment is not created

  Scenario: Cancel a processing shipment
    Given a shipment with status "processing" exists
    When I cancel the shipment
    Then the shipment status is "cancelled"

  Scenario: Cannot cancel a delivered shipment
    Given a delivered shipment exists
    When I try to cancel the shipment
    Then the shipment status remains "delivered"

  Scenario: Check if a shipment is in transit
    Given a shipment with status "shipped" exists
    Then the shipment is in transit

  Scenario: Check if a shipment is completed
    Given a delivered shipment exists
    Then the shipment is completed
