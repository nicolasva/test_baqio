# language: en
#
# Customer Management Feature
# ===========================
# Tests customer creation, display, and metrics.
#
# Customer display name priority:
# 1. Full name (first + last)
# 2. Email
# 3. "Customer #ID"
#
# Features tested:
# - Customer creation with full info (name, email, phone)
# - Anonymous customers (email only, no name)
# - Customer without any identifying info
# - Initials generation from name
# - Total spent calculation from paid invoices
# - Order count with proper pluralization ("1 order" vs "5 orders")
# - Customer search by name
#

Feature: Customer management
  As a user
  I want to manage my customers
  In order to track my business relationships

  Background:
    Given an account exists

  Scenario: Create a customer with all information
    When I create a customer with the following information:
      | first name | last name | email              | phone          |
      | John       | Doe       | john@example.com   | +33612345678   |
    Then the customer "John Doe" exists
    And the customer has email "john@example.com"

  Scenario: Create a customer without name
    When I create a customer with only email "anonymous@example.com"
    Then the customer display name is "anonymous@example.com"

  Scenario: Create a customer without email or name
    When I create a customer without name or email
    Then the customer display name contains "Customer #"

  Scenario: Display customer initials
    Given customer "Marie Martin" exists
    Then the customer initials are "MM"

  Scenario: Calculate total spent by a customer
    Given customer "Pierre Durand" exists
    And the customer has a paid invoice of 150 euros
    And the customer has a paid invoice of 250 euros
    Then the total spent by the customer is 400 euros

  Scenario: Count customer orders
    Given customer "Sophie Petit" exists
    And the customer has 5 orders
    Then the orders text displays "5 orders"

  Scenario: A customer with a single order
    Given customer "Lucas Robert" exists
    And the customer has 1 order
    Then the orders text displays "1 order"

  Scenario: Search customers by name
    Given the following customers exist:
      | first name | last name |
      | John       | Dupont    |
      | Marie      | Durand    |
      | Pierre     | Martin    |
    When I search customers by "Du"
    Then I find 2 customers
