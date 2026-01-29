# language: en
#
# Service Base Feature
# ====================
# Tests the base Service module that provides common service object functionality.
#
# Features tested:
# - Service execution via .call class method
# - Result storage and retrieval
# - Success/failure detection
# - Error collection and retrieval
# - Message logging
# - Callback system
#

Feature: Service base functionality
  As a developer
  I want a consistent service object pattern
  In order to encapsulate business logic with proper error handling

  # ===== Service Execution =====

  Scenario: Execute a successful service
    Given a service that returns "success"
    When I call the service
    Then the service result is "success"
    And the service is successful

  Scenario: Execute a service with keyword arguments
    Given a service that concatenates name and value
    When I call the service with name "test" and value "123"
    Then the service result is "test - 123"

  # ===== Error Handling =====

  Scenario: Service with errors is not successful
    Given a service that adds an error
    When I call the service
    Then the service is not successful
    And the service has 1 error

  Scenario: Service collects multiple errors
    Given a service that adds multiple errors
    When I call the service
    Then the service has 2 errors
    And the first error type is "validation"
    And the first error message is "Invalid input"

  Scenario: Access first error directly
    Given a service that adds an error of type "database" with message "Connection lost"
    When I call the service
    Then the service error type is "database"
    And the service error message is "Connection lost"

  # ===== Message Logging =====

  Scenario: Service logs messages
    Given a service that logs a message "Processing started"
    When I call the service
    Then the service has 1 message
    And the first message is "Processing started"

  Scenario: Messages have timestamps
    Given a service that logs a message "Timestamped message"
    When I call the service
    Then the first message has a timestamp

  # ===== Callbacks =====

  Scenario: Service executes callbacks
    Given a service with an on_complete callback
    When I call the service with a callback that records "callback executed"
    Then the callback recorded "callback executed"

  Scenario: Service passes arguments to callbacks
    Given a service that calls back with arguments
    When I call the service with a callback that captures arguments
    Then the callback received argument "result_data"

  Scenario: Missing callback raises error
    Given a service that calls an undefined callback
    When I call the service without registering the callback
    Then a NoMethodError is raised

  # ===== Integration with Real Services =====

  Scenario: Invoice::Create uses Service::Base
    Given an account and a validated order exist
    When I create an invoice using Invoice::Create service
    Then the service returns an Invoice
    And the invoice is persisted

  Scenario: Order::Cancellation uses Service::Base
    Given an account and a validated order exist
    When I cancel the order using Order::Cancellation service
    Then the order status is "cancelled"
