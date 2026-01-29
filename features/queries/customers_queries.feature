# language: en
#
# Advanced Customer Queries Feature
# =================================
# Tests the Query Objects for customer analysis and segmentation.
#
# Query Objects tested:
#
# SearchQuery:
# - Text search across name and email
# - Filter by order presence (has orders / no orders)
#
# TopSpendersQuery:
# - Rank customers by total spending
# - Calculate average order value per customer
# - Limit results (top N customers)
#
# InactiveQuery:
# - Customers who never ordered
# - Customers with no recent orders
# - Segmentation by inactivity duration:
#   - 30-60 days inactive
#   - 60-90 days inactive
#   - 90-180 days inactive
#

Feature: Advanced customer queries
  As a user
  I want to analyze my customers with advanced criteria
  In order to optimize customer relationships

  Background:
    Given an account exists

  # ===== SearchQuery =====

  Scenario: Search customers by name or email
    Given the following customers exist:
      | first name | last name | email             |
      | John       | Dupont    | john@example.com  |
      | Marie      | Martin    | marie@example.com |
      | Pierre     | Durand    | pierre@test.com   |
    When I search customers with term "example"
    Then I find 2 customers in the search

  Scenario: Filter customers with orders
    Given customer "John Dupont" with 3 orders exists
    And customer "Marie Martin" without orders exists
    When I filter customers having orders
    Then I find 1 customer with orders

  # ===== TopSpendersQuery =====

  Scenario: Identify top customers
    Given customer "John Dupont" having spent 500 euros exists
    And customer "Marie Martin" having spent 1000 euros exists
    And customer "Pierre Durand" having spent 300 euros exists
    When I search for the top 2 customers
    Then the first customer is "Marie Martin"
    And the second customer is "John Dupont"

  Scenario: Calculate top customer statistics
    Given customer "John Dupont" having spent 600 euros in 3 orders exists
    When I request top customer statistics
    Then the total spent is 600 euros
    And the average order value is 200 euros

  # ===== InactiveQuery =====

  Scenario: Identify customers who never ordered
    Given customer "John Dupont" with 1 order exists
    And customer "Marie Martin" without orders exists
    And customer "Pierre Durand" without orders exists
    When I search for customers who never ordered
    Then I find 2 customers without orders

  Scenario: Identify inactive customers
    Given customer "John Dupont" with last order 6 months ago exists
    And customer "Marie Martin" with last order 1 week ago exists
    When I search for inactive customers
    Then I find 1 inactive customer

  Scenario: Segment customers by inactivity duration
    Given a customer with last order 45 days ago exists
    And a customer with last order 75 days ago exists
    And a customer with last order 120 days ago exists
    When I segment customers by inactivity
    Then I see 1 customer inactive for 30-60 days
    And I see 1 customer inactive for 60-90 days
    And I see 1 customer inactive for 90-180 days
