# language: en
#
# Invoice Payment Management Feature
# ==================================
# Tests payment processing and due date tracking for invoices.
#
# Payment rules tested:
# - Only 'sent' invoices can be marked as paid
# - Payment date can be specified explicitly
# - Draft and already-paid invoices cannot be paid again
#
# Due date tracking:
# - Overdue: due_at < current date
# - Due soon: due_at within 7 days
# - Days calculation for overdue/upcoming
#
# Filtering capabilities:
# - Overdue invoices (sent status, past due date)
# - Invoices due soon (sent status, due within 7 days)
#

Feature: Invoice payment management
  As a user
  I want to manage invoice payments
  In order to track cash flow

  Background:
    Given an account exists
    And a customer exists
    And a validated order exists

  Scenario: Pay an invoice on a specific date
    Given a sent invoice exists
    When I mark the invoice as paid on "2024-06-15"
    Then the payment date is "2024-06-15"

  Scenario: Cannot pay a draft invoice
    Given a draft invoice exists
    When I try to mark the invoice as paid
    Then the invoice status remains "draft"

  Scenario: Cannot pay an already paid invoice
    Given a paid invoice exists
    When I try to mark the invoice as paid
    Then the invoice status remains "paid"

  Scenario: Invoice overdue for several days
    Given a sent invoice with due date 15 days ago exists
    Then the invoice is overdue
    And the days overdue is 15

  Scenario: Invoice due in exactly 7 days
    Given a sent invoice with due date in 7 days exists
    Then the invoice is due soon
    And the days until due is 7

  Scenario: Invoice due today
    Given a sent invoice with due date today exists
    Then the days until due is 0
    And the invoice is not yet overdue

  Scenario: Filter overdue invoices
    Given the following invoices exist:
      | status | due date       |
      | sent   | 5 days ago     |
      | sent   | in 10 days     |
      | sent   | 10 days ago    |
      | paid   | 5 days ago     |
    When I filter overdue invoices
    Then I find 2 overdue invoices

  Scenario: Filter invoices due soon
    Given the following invoices exist:
      | status | due date       |
      | sent   | in 3 days      |
      | sent   | in 5 days      |
      | sent   | in 15 days     |
      | paid   | in 2 days      |
    When I filter invoices due soon
    Then I find 2 invoices due soon
