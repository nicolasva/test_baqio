# language: en
#
# Complete Sales Workflow Feature
# ===============================
# End-to-end integration tests for the full sales cycle.
#
# This feature tests the complete happy path:
# 1. Create order with line items
# 2. Validate order
# 3. Invoice order
# 4. Send invoice to customer
# 5. Create and ship fulfillment
# 6. Mark as delivered
# 7. Mark invoice as paid
#
# Also tests:
# - Order cancellation with refund (credit note)
# - Multiple orders per customer
# - Customer spending totals
# - Batch shipment processing
#

Feature: Complete sales workflow
  As a user
  I want to manage the complete sales cycle
  In order to process an order from start to finish

  Background:
    Given an account "My Shop" exists
    And customer "John Doe" exists
    And a delivery service "Colissimo" exists

  Scenario: Complete successful order workflow
    When I create an order for the customer
    And I add the following lines:
      | name   | quantity | unit price |
      | Book   | 2        | 15.00      |
      | Pen    | 4        | 3.00       |
    And I validate the order
    And I invoice the order
    And I send the invoice to the customer
    And I create a shipment for the order
    And I ship the package with number "COL123456" and carrier "Colissimo"
    And I mark the shipment as delivered
    And I mark the invoice as paid
    Then the order has status "invoiced"
    And the invoice has status "paid"
    And the shipment has status "delivered"
    And the order total is 42 euros

  Scenario: Cancel an order with refund
    Given an invoiced order with sent invoice exists
    When I cancel the order
    Then a credit note is created
    And the order has status "cancelled"

  Scenario: Customer with multiple orders
    When I create 3 orders for the customer
    Then the customer has 3 orders total
    And the customer orders text displays "3 orders"

  Scenario: Calculate total spent by customer
    Given a validated order for the customer exists
    And the order is invoiced and paid with an amount of 150 euros
    And another validated order for the customer exists
    And the order is invoiced and paid with an amount of 200 euros
    Then the total spent by the customer is 350 euros

  Scenario: Managing multiple shipments
    Given 3 pending shipments exist
    When I move all shipments to processing
    And I ship all shipments
    Then all shipments have status "shipped"
