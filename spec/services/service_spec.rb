# frozen_string_literal: true

# Service Module Spec
# ===================
# Tests for the base Service module that provides common service object functionality.
#
# Covers:
# - Service::Base: initialization, execution, error/message handling
# - Service::Callbacks: callback registration and invocation
# - Service::Error: error value object
# - Service::Message: message value object
#

require "rails_helper"

RSpec.describe Service, type: :service do
  # Test service that succeeds
  class TestSuccessService < Service::Base
    def call
      append_message("Operation started")
      "success_result"
    end
  end

  # Test service that fails
  class TestFailureService < Service::Base
    def call
      append_error(:validation, "Something went wrong")
      append_error(:database, "Connection failed")
      nil
    end
  end

  # Test service with callbacks
  class TestCallbackService < Service::Base
    def call
      call_back(:on_start, "starting")
      result = "processed"
      call_back(:on_complete, result)
      result
    end
  end

  # Test service that uses instance variables
  class TestArgsService < Service::Base
    def call
      "#{@name} - #{@value}"
    end
  end

  describe Service::Base do
    describe "#initialize" do
      it "sets instance variables from keyword arguments" do
        service = TestArgsService.new(name: "test", value: 42)
        expect(service.instance_variable_get(:@name)).to eq("test")
        expect(service.instance_variable_get(:@value)).to eq(42)
      end

      it "initializes errors as empty array" do
        service = TestSuccessService.new
        expect(service.errors).to eq([])
      end

      it "initializes messages as empty array" do
        service = TestSuccessService.new
        expect(service.messages).to eq([])
      end

      it "accepts a block for callbacks" do
        callback_called = false
        service = TestCallbackService.new do |c|
          c.on_start { callback_called = true }
          c.on_complete { }
        end
        service.execute
        expect(callback_called).to be true
      end
    end

    describe ".call" do
      it "creates and executes the service" do
        service = TestSuccessService.call
        expect(service.result).to eq("success_result")
      end

      it "passes keyword arguments to new" do
        service = TestArgsService.call(name: "foo", value: 123)
        expect(service.result).to eq("foo - 123")
      end

      it "passes block to new" do
        results = []
        TestCallbackService.call do |c|
          c.on_start { |msg| results << "start: #{msg}" }
          c.on_complete { |res| results << "complete: #{res}" }
        end
        expect(results).to eq(["start: starting", "complete: processed"])
      end
    end

    describe "#execute" do
      it "calls the call method and stores result" do
        service = TestSuccessService.new
        service.execute
        expect(service.result).to eq("success_result")
      end

      it "returns self for chaining" do
        service = TestSuccessService.new
        expect(service.execute).to eq(service)
      end
    end

    describe "#successful?" do
      context "when no errors" do
        it "returns true" do
          service = TestSuccessService.call
          expect(service.successful?).to be true
        end
      end

      context "when errors present" do
        it "returns false" do
          service = TestFailureService.call
          expect(service.successful?).to be false
        end
      end
    end

    describe "#error" do
      context "when no errors" do
        it "returns nil" do
          service = TestSuccessService.call
          expect(service.error).to be_nil
        end
      end

      context "when errors present" do
        it "returns the first error" do
          service = TestFailureService.call
          expect(service.error).to be_a(Service::Error)
          expect(service.error.type).to eq(:validation)
          expect(service.error.message).to eq("Something went wrong")
        end
      end
    end

    describe "#errors" do
      it "returns all errors" do
        service = TestFailureService.call
        expect(service.errors.size).to eq(2)
        expect(service.errors.map(&:type)).to eq([:validation, :database])
      end
    end

    describe "#messages" do
      it "returns all messages" do
        service = TestSuccessService.call
        expect(service.messages.size).to eq(1)
        expect(service.messages.first.message).to eq("Operation started")
      end
    end

    describe "#append_error (private)" do
      it "creates an Error with type, message and caller info" do
        service = TestFailureService.call
        error = service.errors.first
        expect(error.type).to eq(:validation)
        expect(error.message).to eq("Something went wrong")
        expect(error.caller_info).to be_a(String)
        expect(error.caller_info).to include("service_spec.rb")
      end

      context "with verbose: true" do
        it "outputs the error to stdout" do
          verbose_service = Class.new(Service::Base) do
            def call
              append_error(:test, "verbose error", verbose: true)
            end
          end

          expect { verbose_service.call }.to output(/test : verbose error/).to_stdout
        end
      end
    end

    describe "#append_message (private)" do
      it "creates a Message with content and timestamp" do
        service = TestSuccessService.call
        message = service.messages.first
        expect(message.message).to eq("Operation started")
        expect(message.time).to be_a(Time)
      end

      context "with verbose: true" do
        it "outputs the message to stdout" do
          verbose_service = Class.new(Service::Base) do
            def call
              append_message("verbose message", verbose: true)
            end
          end

          expect { verbose_service.call }.to output(/verbose message/).to_stdout
        end
      end
    end

    describe "#call_back (private)" do
      it "invokes registered callbacks" do
        results = []
        TestCallbackService.call do |c|
          c.on_start { |msg| results << msg }
          c.on_complete { |res| results << res }
        end
        expect(results).to eq(["starting", "processed"])
      end
    end
  end

  describe Service::Callbacks do
    describe "#initialize" do
      it "accepts a block for registering callbacks" do
        callbacks = Service::Callbacks.new do |c|
          c.on_success { "success" }
        end
        expect(callbacks.call(:on_success)).to eq("success")
      end

      it "works without a block" do
        callbacks = Service::Callbacks.new
        expect { callbacks.call(:missing) }.to raise_error(NoMethodError)
      end
    end

    describe "#call" do
      let(:callbacks) do
        Service::Callbacks.new do |c|
          c.on_event { |arg| "received: #{arg}" }
        end
      end

      it "invokes the callback with arguments" do
        result = callbacks.call(:on_event, "data")
        expect(result).to eq("received: data")
      end

      it "raises NoMethodError for undefined callbacks" do
        expect { callbacks.call(:undefined) }.to raise_error(NoMethodError, /undefined/)
      end
    end

    describe "callback registration via method_missing" do
      it "registers callbacks with blocks" do
        callbacks = Service::Callbacks.new
        callbacks.my_callback { "callback result" }
        expect(callbacks.call(:my_callback)).to eq("callback result")
      end

      it "raises for methods without blocks" do
        callbacks = Service::Callbacks.new
        expect { callbacks.unknown_method }.to raise_error(NoMethodError)
      end
    end

    describe "#respond_to_missing?" do
      it "returns true for any method" do
        callbacks = Service::Callbacks.new
        expect(callbacks.respond_to?(:any_method)).to be true
      end
    end
  end

  describe Service::Error do
    subject(:error) { Service::Error.new(:validation, "Invalid data", "app/services/test.rb:10") }

    describe "#initialize" do
      it "sets the type" do
        expect(error.type).to eq(:validation)
      end

      it "sets the message" do
        expect(error.message).to eq("Invalid data")
      end

      it "sets the caller_info" do
        expect(error.caller_info).to eq("app/services/test.rb:10")
      end
    end

    describe "attributes" do
      it "provides read access to type" do
        expect(error).to respond_to(:type)
      end

      it "provides read access to message" do
        expect(error).to respond_to(:message)
      end

      it "provides read access to caller_info" do
        expect(error).to respond_to(:caller_info)
      end
    end
  end

  describe Service::Message do
    subject(:message) { Service::Message.new("Processing complete") }

    describe "#initialize" do
      it "sets the message" do
        expect(message.message).to eq("Processing complete")
      end

      it "sets the time to current time" do
        freeze_time = Time.new(2024, 1, 15, 10, 30, 0)
        allow(Time).to receive(:now).and_return(freeze_time)

        new_message = Service::Message.new("test")
        expect(new_message.time).to eq(freeze_time)
      end
    end

    describe "attributes" do
      it "provides read access to message" do
        expect(message).to respond_to(:message)
      end

      it "provides read access to time" do
        expect(message).to respond_to(:time)
        expect(message.time).to be_a(Time)
      end
    end
  end

  describe "integration with real services" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }
    let(:order) { create(:order, :validated, account: account, customer: customer, total_amount: 100.0) }

    it "Invoice::Create inherits from Service::Base" do
      expect(Invoice::Create.ancestors).to include(Service::Base)
    end

    it "Order::Cancellation inherits from Service::Base" do
      expect(Order::Cancellation.ancestors).to include(Service::Base)
    end

    it "services can be called with .call class method" do
      result = Invoice::Create.call(order: order, type: :debit)
      expect(result).to be_a(Invoice::Create)
      expect(result.result).to be_a(Invoice)
    end
  end
end
