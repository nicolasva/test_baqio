# language: en
#
# Order Line Management Feature
# ============================
# Tests the management of individual items within an order.
#
# Features tested:
# - Adding single and multiple lines to an order
# - Automatic calculation of line total (quantity * unit_price)
# - Order total recalculation when lines change
# - SKU assignment to lines
# - Line deletion and quantity modification
# - Pluralization of item count ("1 item" vs "5 items")
#
# Business rules:
# - Line total_price = quantity * unit_price
# - Order total_amount = sum of all line totals
# - Empty orders have zero total
#

Feature: Order line management
  As a user
  I want to manage order lines
  In order to track ordered items

  Background:
    Given an account exists
    And a customer exists

  Scenario: Add multiple lines to an order
    Given a pending order exists
    When I add the following lines:
      | name          | quantity | unit price |
      | Blue T-shirt  | 2        | 25.00      |
      | Black Pants   | 1        | 45.00      |
      | Belt          | 1        | 15.00      |
    Then the order has 3 lines
    And the order total is 110 euros

  Scenario: Calculate line total price
    Given a pending order exists
    When I add a line with:
      | name   | quantity | unit price |
      | Shoes  | 3        | 89.99      |
    Then the line total price is approximately 269.97 euros

  Scenario: Add a line with SKU
    Given a pending order exists
    When I add a line with SKU:
      | name   | quantity | unit price | sku       |
      | Watch  | 1        | 199.00     | WATCH-001 |
    Then the line has SKU "WATCH-001"

  Scenario: Delete an order line
    Given an order with 3 lines exists
    When I delete the first line
    Then the order has 2 lines

  Scenario: Modify line quantity
    Given an order with a line of 2 items at 50 euros exists
    When I modify the line quantity to 5
    Then the line total price is 250 euros
    And the order total is 250 euros

  Scenario: An order without lines has zero total
    Given an order without lines exists
    Then the order total is 0 euros
    And the order is empty

  Scenario: Display item count singular
    Given an order with 1 line exists
    Then the summary displays "1 item"

  Scenario: Display item count plural
    Given an order with 10 lines exists
    Then the summary displays "10 items"
