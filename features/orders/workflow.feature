# language: en
#
# Order Workflow Feature
# ======================
# Tests the complete order lifecycle from creation to completion or cancellation.
#
# Order Status Flow:
#   pending -> validated -> invoiced -> (complete)
#   pending -> cancelled
#   validated -> cancelled (creates event)
#   invoiced -> cancelled (creates credit note)
#
# Key business rules tested:
# - Orders start in 'pending' status with auto-generated reference
# - Validation moves order to 'validated' status
# - Invoicing creates an invoice and moves order to 'invoiced'
# - Cancellation behavior differs based on current status
# - Order lines affect total amount calculation
#

Feature: Order workflow
  As a user
  I want to manage the order lifecycle
  In order to process sales efficiently

  Background:
    Given an account exists
    And a customer exists

  Scenario: Create a new order
    When I create an order
    Then the order has status "pending"
    And the order has an automatically generated reference

  Scenario: Validate a pending order
    Given a pending order exists
    When I validate the order
    Then the order status is "validated"

  Scenario: Cannot validate an already validated order
    Given a validated order exists
    When I try to validate the order
    Then the order status remains "validated"

  Scenario: Invoice a validated order
    Given a validated order exists
    When I invoice the order
    Then the order status is "invoiced"
    And an invoice is created for the order

  Scenario: Cancel a pending order
    Given a pending order exists
    When I cancel the order
    Then the order status is "cancelled"

  Scenario: Cancel a validated order
    Given a validated order exists
    When I cancel the order
    Then the order status is "cancelled"
    And an event "order.cancelled" is created

  Scenario: Cancel an invoiced order creates a credit note
    Given an invoiced order exists
    When I cancel the order
    Then a credit note is created
    And the order status is "cancelled"

  Scenario: Add lines to an order
    Given a pending order exists
    When I add a line with:
      | name           | quantity | unit price |
      | White T-shirt  | 2        | 29.99      |
    Then the order has 1 line
    And the order total is approximately 59.98 euros

  Scenario: Calculate total with multiple lines
    Given an order with the following lines:
      | name      | quantity | unit price |
      | T-shirt   | 2        | 20.00      |
      | Jeans     | 1        | 50.00      |
      | Shoes     | 1        | 80.00      |
    Then the order total is 170 euros
    And the order has 3 lines

  Scenario: Display items summary
    Given an order with 5 lines exists
    Then the summary displays "5 items"

  Scenario: Display summary with a single item
    Given an order with 1 line exists
    Then the summary displays "1 item"

  Scenario: Empty order
    Given an order without lines exists
    Then the order is empty
    And the order total is 0 euros

  Scenario: Display status names
    Given an order with status "pending" exists
    Then the order status name is "Pending"

  Scenario: Display validated status
    Given an order with status "validated" exists
    Then the order status name is "Validated"

  Scenario: Display invoiced status
    Given an order with status "invoiced" exists
    Then the order status name is "Invoiced"
