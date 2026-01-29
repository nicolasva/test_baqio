# language: en
#
# Advanced Order Queries Feature
# ==============================
# Tests the Query Objects for complex order filtering and analytics.
#
# Query Objects tested:
#
# FilterQuery:
# - Filter by status (single or multiple)
# - Filter by amount range (min/max)
# - Filter by date range
#
# NeedingAttentionQuery:
# - Orders pending too long (> 3 days)
# - Orders with overdue payment
#
# DashboardQuery:
# - Daily order statistics
# - Period-based revenue calculation
#
# WithRevenueQuery:
# - Average revenue per order
# - Revenue from paid invoices only
#

Feature: Advanced order queries
  As a user
  I want to query orders with complex filters
  In order to analyze my business activity

  Background:
    Given an account exists
    And a customer exists

  # ===== FilterQuery =====

  Scenario: Filter orders by status
    Given the following orders exist for the account:
      | status    |
      | pending   |
      | pending   |
      | validated |
      | cancelled |
    When I filter orders by status "pending"
    Then I find 2 filtered orders

  Scenario: Filter orders by minimum amount
    Given the following orders exist for the account:
      | amount |
      | 50     |
      | 150    |
      | 300    |
    When I filter orders with minimum amount of 100 euros
    Then I find 2 filtered orders

  Scenario: Filter orders by date range
    Given an order created 5 days ago exists
    And an order created 15 days ago exists
    And an order created 30 days ago exists
    When I filter orders from the last 10 days
    Then I find 1 filtered order

  # ===== NeedingAttentionQuery =====

  Scenario: Identify orders pending too long
    Given a pending order created 5 days ago exists
    And a pending order created 1 day ago exists
    When I search for orders needing attention
    Then I find 1 order pending too long

  Scenario: Identify orders with overdue payment
    Given an invoiced order with overdue payment exists
    And an invoiced order with current payment exists
    When I search for orders with overdue payment
    Then I find 1 order with overdue payment

  # ===== DashboardQuery =====

  Scenario: Get dashboard statistics
    Given 3 orders created today exist
    And 2 orders created yesterday exist
    When I request today's statistics
    Then I see 3 orders in the statistics

  Scenario: Get monthly revenue
    Given a paid order of 100 euros this month exists
    And a paid order of 200 euros this month exists
    And a paid order of 150 euros last month exists
    When I calculate monthly revenue
    Then the revenue is 300 euros

  # ===== WithRevenueQuery =====

  Scenario: Calculate average revenue per order
    Given a paid order of 100 euros exists
    And a paid order of 200 euros exists
    And a paid order of 300 euros exists
    When I calculate average revenue per order
    Then the average revenue is 200 euros
