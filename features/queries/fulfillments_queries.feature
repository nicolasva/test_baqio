# language: en
#
# Advanced Shipment Queries Feature
# =================================
# Tests the Query Objects for logistics analysis and monitoring.
#
# Query Objects tested:
#
# PerformanceQuery:
# - Average transit time calculation
# - On-time delivery rate (percentage under target days)
# - Transit time distribution (1 day, 2-3 days, 4-5 days, etc.)
#
# DelayedQuery:
# - Shipments stuck in pending (> threshold days)
# - Shipments in transit too long
# - Delay statistics
#
# TrackingQuery:
# - Search by tracking number
# - Filter by carrier
# - List active shipments (shipped + processing)
#

Feature: Advanced shipment queries
  As a user
  I want to analyze my shipments with advanced criteria
  In order to optimize logistics

  Background:
    Given an account exists
    And a delivery service "Express" exists

  # ===== PerformanceQuery =====

  Scenario: Calculate average transit time
    Given a shipment delivered in 2 days exists
    And a shipment delivered in 4 days exists
    And a shipment delivered in 3 days exists
    When I calculate average transit time
    Then the average transit time is 3 days

  Scenario: Calculate on-time delivery rate
    Given a shipment delivered in 3 days exists
    And a shipment delivered in 4 days exists
    And a shipment delivered in 8 days exists
    When I calculate on-time delivery rate
    Then the on-time delivery rate is 66.7 percent

  Scenario: Analyze transit time distribution
    Given a shipment delivered in 1 day exists
    And a shipment delivered in 3 days exists
    And a shipment delivered in 5 days exists
    And a shipment delivered in 10 days exists
    When I analyze transit time distribution
    Then I see 1 delivery in 1 day
    And I see 1 delivery in 2-3 days
    And I see 1 delivery in 4-5 days
    And I see 1 delivery in more than 8 days

  # ===== DelayedQuery =====

  Scenario: Identify shipments stuck in pending
    Given a pending shipment created 5 days ago exists
    And a pending shipment created 1 day ago exists
    When I search for stuck shipments
    Then I find 1 shipment stuck in pending

  Scenario: Identify shipments in transit too long
    Given a shipment shipped 10 days ago not delivered exists
    And a shipment shipped 3 days ago not delivered exists
    When I search for delivery delayed shipments
    Then I find 1 delivery delayed shipment

  Scenario: Get delay statistics
    Given a pending shipment created 5 days ago exists
    And a shipment shipped 10 days ago not delivered exists
    When I request delay statistics
    Then the total delayed shipments count is 2

  # ===== TrackingQuery =====

  Scenario: Search shipment by tracking number
    Given a shipment with tracking number "DHL123456" exists
    And a shipment with tracking number "UPS789012" exists
    When I search for shipment with number "DHL123456"
    Then I find the shipment with the correct tracking number

  Scenario: Filter shipments by carrier
    Given a shipment with carrier "DHL" exists
    And a shipment with carrier "DHL" exists
    And a shipment with carrier "UPS" exists
    When I filter shipments by carrier "DHL"
    Then I find 2 DHL shipments

  Scenario: List active shipments
    Given a shipment with status "shipped" exists
    And a shipment with status "processing" exists
    And a shipment with status "delivered" exists
    When I list active shipments
    Then I find 2 active shipments
