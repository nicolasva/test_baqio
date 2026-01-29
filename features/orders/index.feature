# language: en
#
# Orders List Feature
# ===================
# Tests the orders index page display and pagination.
#
# UI elements tested:
# - Orders table with reference, status, customer, amounts
# - Status badges with proper display names
# - Customer information display
# - Delivery/fulfillment information
# - Pagination with 50 items per page
#
# Note: Uses @pagination tag for scenarios requiring many records.
#

Feature: Orders list
  As a user
  I want to see the list of orders
  In order to manage my orders efficiently

  Background:
    Given an account "Baqio Demo" exists

  Scenario: Display empty orders page
    When I visit the orders page
    Then I see the orders table
    And the table is empty

  Scenario: Display existing orders
    Given the following orders exist:
      | reference      | status    | customer      | amount |
      | ORD-2024-0001 | pending   | John Doe      | 150.00 |
      | ORD-2024-0002 | validated | Marie Martin  | 250.00 |
      | ORD-2024-0003 | invoiced  | Pierre Durand | 350.00 |
    When I visit the orders page
    Then I see 3 orders in the table
    And I see reference "ORD-2024-0001"
    And I see reference "ORD-2024-0002"
    And I see reference "ORD-2024-0003"

  Scenario: Display order statuses
    Given a "pending" order exists
    And a "validated" order exists
    And an "invoiced" order exists
    And a "cancelled" order exists
    When I visit the orders page
    Then I see status "Pending"
    And I see status "Validated"
    And I see status "Invoiced"
    And I see status "Cancelled"

  Scenario: Display customer information
    Given customer "Sophie Petit" exists
    And an order for this customer exists
    When I visit the orders page
    Then I see customer name "Sophie Petit"

  Scenario: Display delivery information
    Given an order with shipment "DHL Express" exists
    When I visit the orders page
    Then I see carrier "DHL Express"
    And I see shipment status "Shipped"

  Scenario: Display quantities and amounts
    Given an order with 3 lines and a total of 300.0 euros exists
    When I visit the orders page
    Then I see total quantity "3"
    And I see amount "300"

  @pagination
  Scenario: Paginate orders
    Given 60 orders exist
    When I visit the orders page
    Then I see 50 orders in the table
    And I see pagination links

  @pagination
  Scenario: Navigate to page 2
    Given 60 orders exist
    When I visit the orders page with page parameter "2"
    Then I see 10 orders in the table
