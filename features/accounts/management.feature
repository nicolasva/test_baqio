# language: en
#
# Account Management Feature
# ==========================
# Tests multi-tenant account creation and business metrics.
#
# Account is the top-level tenant entity that owns:
# - Customers
# - Orders
# - Invoices
# - Fulfillments
#
# Features tested:
# - Account creation with required name
# - Name validation (cannot be blank)
# - Revenue calculation from paid invoices only
# - Active order counting (excludes cancelled)
# - Account search by name
#

Feature: Account management
  As an administrator
  I want to manage application accounts
  In order to allow users to use the system

  Scenario: Create an account with a name
    When I create an account named "My Shop"
    Then account "My Shop" exists

  Scenario: An account without name is invalid
    When I try to create an account without name
    Then the account is not created

  Scenario: Calculate account revenue
    Given an account "Test Shop" exists
    And the account has a paid invoice of 500 euros
    And the account has a paid invoice of 300 euros
    And the account has an unpaid invoice of 200 euros
    Then the account revenue is 800 euros

  Scenario: Count active orders of an account
    Given an account "Active Shop" exists
    And the account has 5 orders with status "pending"
    And the account has 3 orders with status "validated"
    And the account has 2 orders with status "cancelled"
    Then the account has 8 active orders

  Scenario: Search accounts by name
    Given the following accounts exist:
      | name              |
      | Paris Shop        |
      | Lyon Shop         |
      | Marseille Store   |
    When I search accounts by "Shop"
    Then I find 2 accounts
