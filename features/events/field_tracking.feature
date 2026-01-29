# language: en
#
# Field Change Tracking Feature
# =============================
# Tests the automatic tracking of field modifications via the Trackable concern.
#
# Tracked fields:
# - Order: status, total_amount
# - OrderLine: unit_price
#
# Features tested:
# - Automatic event creation when tracked fields change
# - Event payload contains old_value and new_value
# - Event type follows "model.field.changed" pattern
# - No events for untracked field changes
# - Cascading tracking (order_line price -> order total)
#

Feature: Field change tracking
  As an administrator
  I want to automatically track field modifications
  In order to have a complete audit trail of data changes

  Background:
    Given an account exists
    And a customer exists

  # ===== Order Status Tracking =====

  Scenario: Track order status change from pending to validated
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "validated"
    Then an event "order.status.changed" is recorded
    And the event payload shows status changed from "pending" to "validated"

  Scenario: Track order status change from validated to invoiced
    Given an order with status "validated" and total 100 euros exists
    When I change the order status to "invoiced"
    Then an event "order.status.changed" is recorded
    And the event payload shows status changed from "validated" to "invoiced"

  Scenario: Track order status change to cancelled
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "cancelled"
    Then an event "order.status.changed" is recorded
    And the event payload shows status changed from "pending" to "cancelled"

  # ===== Order Total Amount Tracking =====

  Scenario: Track order total amount increase
    Given an order with status "pending" and total 100 euros exists
    When I change the order total to 150 euros
    Then an event "order.total_amount.changed" is recorded
    And the event payload shows total_amount changed from 100.0 to 150.0

  Scenario: Track order total amount decrease
    Given an order with status "pending" and total 200 euros exists
    When I change the order total to 150 euros
    Then an event "order.total_amount.changed" is recorded
    And the event payload shows total_amount changed from 200.0 to 150.0

  # ===== Multiple Field Changes =====

  Scenario: Track multiple field changes in single update
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "validated" and total to 200 euros
    Then an event "order.status.changed" is recorded
    And an event "order.total_amount.changed" is recorded
    And I find 2 tracking events for the order

  # ===== OrderLine Unit Price Tracking =====

  Scenario: Track order line unit price change
    Given an order with a line at 25 euros unit price exists
    When I change the order line unit price to 30 euros
    Then an event "order_line.unit_price.changed" is recorded
    And the event payload shows unit_price changed from 25.0 to 30.0

  Scenario: Track order line price increase
    Given an order with a line at 10 euros unit price exists
    When I change the order line unit price to 50 euros
    Then an event "order_line.unit_price.changed" is recorded
    And the event payload shows unit_price changed from 10.0 to 50.0

  Scenario: Track order line price decrease
    Given an order with a line at 100 euros unit price exists
    When I change the order line unit price to 75 euros
    Then an event "order_line.unit_price.changed" is recorded
    And the event payload shows unit_price changed from 100.0 to 75.0

  # ===== Cascading Tracking =====

  Scenario: Order line price change triggers order total tracking
    Given an order with a line at 25 euros unit price and quantity 2 exists
    When I change the order line unit price to 50 euros
    Then an event "order_line.unit_price.changed" is recorded
    And an event "order.total_amount.changed" is recorded

  # ===== No Tracking for Untracked Fields =====

  Scenario: No event when updating untracked order fields
    Given an order with status "pending" and total 100 euros exists
    When I update the order notes to "New notes"
    Then no "order.notes.changed" event is recorded

  Scenario: No event when updating order line quantity only
    Given an order with a line at 25 euros unit price exists
    When I change the order line quantity to 5
    Then no "order_line.quantity.changed" event is recorded

  # ===== Event Association =====

  Scenario: Tracking event is associated with correct account
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "validated"
    Then the tracking event is associated with the order's account

  Scenario: Tracking event creates correct resource reference
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "validated"
    Then the tracking event has a resource of type "Order"

  Scenario: OrderLine tracking event creates correct resource reference
    Given an order with a line at 25 euros unit price exists
    When I change the order line unit price to 30 euros
    Then the tracking event has a resource of type "OrderLine"

  # ===== Querying Tracking Events =====

  Scenario: Filter tracking events by type
    Given the following order changes have been made:
      | order_id | field        | old_value | new_value |
      | 1        | status       | pending   | validated |
      | 1        | total_amount | 100       | 150       |
      | 2        | status       | pending   | cancelled |
    When I filter events by type "order.status.changed"
    Then I find 2 events

  Scenario: Retrieve tracking events in chronological order
    Given an order with status "pending" and total 100 euros exists
    When I change the order status to "validated"
    And I wait 1 second
    And I change the order total to 200 euros
    And I retrieve recent tracking events
    Then the first event is the total_amount change
    And the last event is the status change
