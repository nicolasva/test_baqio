# language: en
#
# Invoice Lifecycle Feature
# =========================
# Tests the complete invoice lifecycle from creation to payment or cancellation.
#
# Invoice Status Flow:
#   draft -> sent -> paid
#   draft -> cancelled
#   sent -> cancelled
#   (paid invoices cannot be cancelled)
#
# Key business rules tested:
# - Invoices start as 'draft' with auto-generated number (INV-xxx)
# - Sending sets issue date to today and due date to +30 days
# - Payment records the payment date
# - Overdue detection based on due_at vs current date
# - Credit notes have number prefix 'CN-'
# - Total amount includes VAT (amount + tax_amount)
#

Feature: Invoice lifecycle
  As a user
  I want to manage the invoice lifecycle
  In order to track customer payments

  Background:
    Given an account exists
    And a customer exists
    And a validated order exists

  Scenario: Create an invoice for an order
    When I create an invoice for the order
    Then a "draft" invoice is created
    And the invoice has a number starting with "INV-"
    And the order status is "invoiced"

  Scenario: Send an invoice to the customer
    Given a draft invoice exists
    When I send the invoice to the customer
    Then the invoice status is "sent"
    And the issue date is today
    And the due date is in 30 days

  Scenario: Mark an invoice as paid
    Given a sent invoice exists
    When I mark the invoice as paid
    Then the invoice status is "paid"
    And the payment date is today

  Scenario: Cancel a draft invoice
    Given a draft invoice exists
    When I cancel the invoice
    Then the invoice status is "cancelled"

  Scenario: Cancel a sent invoice
    Given a sent invoice exists
    When I cancel the invoice
    Then the invoice status is "cancelled"

  Scenario: Cannot cancel a paid invoice
    Given a paid invoice exists
    When I try to cancel the invoice
    Then the invoice status remains "paid"

  Scenario: Calculate total amount with VAT
    When I create an invoice with an amount of 100 euros and VAT of 20 euros
    Then the invoice total amount is 120 euros

  Scenario: Detect an overdue invoice
    Given a sent invoice with past due date exists
    Then the invoice is overdue
    And the days overdue are displayed

  Scenario: Detect an invoice due soon
    Given a sent invoice with due date in 5 days exists
    Then the invoice is due soon

  Scenario: Create a credit note
    When I create a credit note for the order
    Then an invoice with number starting with "CN-" is created
    And the order status is "cancelled"
