# language: en
#
# Advanced Invoice Queries Feature
# ================================
# Tests the Query Objects for invoice analysis and collections management.
#
# Query Objects tested:
#
# AgingReportQuery:
# - Categorize invoices by days overdue (1-30, 31-60, 61-90, 90+)
# - Calculate total overdue amount
# - Standard accounts receivable aging report
#
# NeedingFollowUpQuery:
# - Critical invoices (60+ days overdue)
# - High priority (30-60 days)
# - Medium priority (1-30 days)
# - Low priority (due within 7 days)
# - Invoices due this week
#
# RevenueQuery:
# - Period comparison (current vs previous)
# - Growth percentage calculation
# - Revenue from paid invoices only
#

Feature: Advanced invoice queries
  As a user
  I want to analyze my invoices with advanced criteria
  In order to manage cash flow

  Background:
    Given an account exists
    And a customer exists

  # ===== AgingReportQuery =====

  Scenario: Generate invoice aging report
    Given a sent invoice overdue by 15 days exists
    And a sent invoice overdue by 45 days exists
    And a sent invoice overdue by 100 days exists
    When I generate the aging report
    Then I see 1 invoice in the 1-30 days bracket
    And I see 1 invoice in the 31-60 days bracket
    And I see 1 invoice in the over 90 days bracket

  Scenario: Calculate total overdue amount
    Given an invoice of 100 euros overdue by 10 days exists
    And an invoice of 200 euros overdue by 20 days exists
    And an invoice of 150 euros not yet due exists
    When I calculate total overdue amount
    Then the overdue amount is 300 euros

  # ===== NeedingFollowUpQuery =====

  Scenario: Identify critical invoices
    Given an invoice overdue by 70 days exists
    And an invoice overdue by 30 days exists
    When I search for critical invoices
    Then I find 1 critical invoice

  Scenario: Identify invoices to follow up this week
    Given an invoice due later this week exists
    And an invoice due in 10 days exists
    When I search for invoices to follow up this week
    Then I find 1 invoice to follow up

  Scenario: Group invoices by follow-up priority
    Given an invoice overdue by 70 days exists
    And an invoice overdue by 45 days exists
    And an invoice overdue by 15 days exists
    And an invoice due in 5 days exists
    When I group invoices by priority
    Then I see 1 critical invoice
    And I see 1 high priority invoice
    And I see 1 medium priority invoice
    And I see 1 low priority invoice

  # ===== RevenueQuery =====

  Scenario: Calculate revenue by period
    Given a paid invoice of 500 euros this month exists
    And a paid invoice of 300 euros last month exists
    When I compare revenue with the previous month
    Then the current revenue is 500 euros
    And the previous revenue is 300 euros
    And the growth is 66.67 percent
