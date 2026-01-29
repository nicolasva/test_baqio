# language: en
#
# Event Audit Trail Feature
# =========================
# Tests the audit logging system for tracking account activity.
#
# AccountEvent records important actions for compliance and debugging:
# - invoice.debit.created: New invoice created
# - invoice.credit.created: Credit note created
# - order.cancelled: Order cancellation
#
# Features tested:
# - Automatic event creation on business actions
# - Event filtering by type
# - Chronological retrieval (most recent first)
# - Date-based filtering (today's events)
# - Payload storage for additional metadata
#

Feature: Event audit trail
  As an administrator
  I want to track account events
  In order to have complete action traceability

  Background:
    Given an account exists
    And a customer exists

  Scenario: Create an event when an invoice is created
    Given a validated order exists
    When I invoice the order
    Then an event "invoice.debit.created" is recorded

  Scenario: Create an event when a validated order is cancelled
    Given a validated order exists
    When I cancel the order
    Then an event "order.cancelled" is recorded

  Scenario: Filter events by type
    Given the following events exist:
      | type                    |
      | invoice.debit.created   |
      | invoice.debit.created   |
      | order.cancelled         |
      | invoice.credit.created  |
    When I filter events by type "invoice.debit.created"
    Then I find 2 events

  Scenario: Retrieve recent events
    Given an event created 1 day ago exists
    And an event created 2 days ago exists
    And an event created 3 days ago exists
    When I retrieve recent events
    Then the first event is the most recent

  Scenario: Retrieve today's events
    Given an event created today exists
    And an event created yesterday exists
    When I filter today's events
    Then I find 1 event

  Scenario: Store additional data in an event
    When I create an event with the following payload:
      | key       | value        |
      | action    | modification |
      | user_id   | 123          |
    Then the event payload contains "action" with value "modification"
