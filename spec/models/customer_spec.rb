# frozen_string_literal: true

# Customer Model Spec
# ===================
# Tests for the Customer model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Validations (email format, uniqueness scoped to account)
# - Associations (account, orders, invoices)
# - Scopes (with_email, with_orders, by_name)
# - Instance methods (full_name, display_name, total_spent, orders_count)
#
# Note: Email is optional but must be valid format if provided.
# Customers cannot be deleted if they have orders.
#

require "rails_helper"

RSpec.describe Customer, type: :model do
  describe "Test data creation" do
    it "can create a valid customer for testing" do
      customer = build(:customer)
      expect(customer).to be_valid
    end

    it "can create a customer without email" do
      customer = build(:customer, :without_email)
      expect(customer).to be_valid
      expect(customer.email).to be_nil
    end

    it "can create a customer without name" do
      customer = build(:customer, :without_name)
      expect(customer).to be_valid
    end
  end

  describe "Data validation rules" do
    describe "Email address" do
      it "allows customers without an email" do
        customer = build(:customer, email: nil)
        expect(customer).to be_valid
      end

      it "allows an empty email field" do
        customer = build(:customer, email: "")
        expect(customer).to be_valid
      end

      it "rejects invalid email formats" do
        customer = build(:customer, email: "invalid-email")
        expect(customer).not_to be_valid
        expect(customer.errors[:email]).to include("is invalid")
      end

      it "accepts properly formatted emails" do
        customer = build(:customer, email: "valid@example.com")
        expect(customer).to be_valid
      end

      it "prevents duplicate emails in the same account" do
        account = create(:account)
        create(:customer, account: account, email: "same@example.com")
        duplicate = build(:customer, account: account, email: "same@example.com")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include("has already been taken")
      end

      it "allows the same email in different accounts" do
        account1 = create(:account)
        account2 = create(:account)
        create(:customer, account: account1, email: "same@example.com")
        customer2 = build(:customer, account: account2, email: "same@example.com")

        expect(customer2).to be_valid
      end
    end
  end

  describe "Relationships with other data" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }

    it "is linked to an account" do
      expect(customer.account).to eq(account)
    end

    describe "Orders" do
      it "can have multiple orders" do
        order = create(:order, customer: customer, account: account)
        expect(customer.orders).to include(order)
      end

      it "cannot be deleted if they have orders" do
        create(:order, customer: customer, account: account)
        expect(customer.destroy).to be false
        expect(customer.errors[:base]).to include("Cannot delete record because dependent orders exist")
      end

      it "can be deleted if they have no orders" do
        expect(customer.destroy).to be_truthy
      end
    end

    describe "Invoices" do
      it "can access invoices through their orders" do
        order = create(:order, customer: customer, account: account)
        invoice = create(:invoice, order: order)
        expect(customer.invoices).to include(invoice)
      end
    end
  end

  describe "Quick filters for searching customers" do
    let(:account) { create(:account) }

    describe "Customers with email" do
      it "returns only customers who have an email address" do
        with_email = create(:customer, account: account, email: "test@example.com")
        without_email = create(:customer, account: account, email: nil)
        empty_email = create(:customer, account: account, email: "")

        expect(Customer.with_email).to include(with_email)
        expect(Customer.with_email).not_to include(without_email, empty_email)
      end
    end

    describe "Customers with orders" do
      it "returns only customers who have placed orders" do
        with_orders = create(:customer, account: account)
        without_orders = create(:customer, account: account)
        create(:order, customer: with_orders, account: account)

        expect(Customer.with_orders).to include(with_orders)
        expect(Customer.with_orders).not_to include(without_orders)
      end

      it "returns each customer only once even if they have multiple orders" do
        customer = create(:customer, account: account)
        create_list(:order, 3, customer: customer, account: account)

        expect(Customer.with_orders.count).to eq(1)
      end
    end

    describe "Search by name" do
      it "finds customers by their first name" do
        john = create(:customer, account: account, first_name: "John", last_name: "Doe")
        jane = create(:customer, account: account, first_name: "Jane", last_name: "Smith")

        expect(Customer.by_name("John")).to include(john)
        expect(Customer.by_name("John")).not_to include(jane)
      end

      it "finds customers by their last name" do
        john = create(:customer, account: account, first_name: "John", last_name: "Doe")

        expect(Customer.by_name("Doe")).to include(john)
      end

      it "finds customers with partial name matches" do
        john = create(:customer, account: account, first_name: "Johnny", last_name: "Doe")

        expect(Customer.by_name("John")).to include(john)
      end
    end
  end

  describe "Customer information methods" do
    describe "Getting the full name" do
      it "combines first and last name" do
        customer = build(:customer, first_name: "John", last_name: "Doe")
        expect(customer.full_name).to eq("John Doe")
      end

      it "returns just the first name if there is no last name" do
        customer = build(:customer, first_name: "John", last_name: nil)
        expect(customer.full_name).to eq("John")
      end

      it "returns just the last name if there is no first name" do
        customer = build(:customer, first_name: nil, last_name: "Doe")
        expect(customer.full_name).to eq("Doe")
      end

      it "returns nothing if there is no name at all" do
        customer = build(:customer, first_name: nil, last_name: nil)
        expect(customer.full_name).to be_nil
      end

      it "treats empty strings as no name" do
        customer = build(:customer, first_name: "", last_name: "")
        expect(customer.full_name).to be_nil
      end
    end

    describe "Getting the display name (for showing in the UI)" do
      it "shows the full name if available" do
        customer = build(:customer, first_name: "John", last_name: "Doe")
        expect(customer.display_name).to eq("John Doe")
      end

      it "shows the email if there is no name" do
        customer = build(:customer, first_name: nil, last_name: nil, email: "test@example.com")
        expect(customer.display_name).to eq("test@example.com")
      end

      it "shows 'Customer #ID' if there is no name or email" do
        customer = create(:customer, first_name: nil, last_name: nil, email: nil)
        expect(customer.display_name).to eq("Customer ##{customer.id}")
      end
    end

    describe "Calculating total spent by customer" do
      let(:account) { create(:account) }
      let(:customer) { create(:customer, account: account) }

      it "adds up all paid invoices (including tax)" do
        order1 = create(:order, customer: customer, account: account)
        order2 = create(:order, customer: customer, account: account)
        create(:invoice, :paid, order: order1, amount: 100.0, tax_amount: 20.0)
        create(:invoice, :paid, order: order2, amount: 50.0, tax_amount: 10.0)

        expect(customer.total_spent).to eq(180.0) # 120 + 60
      end

      it "does not count unpaid invoices" do
        order = create(:order, customer: customer, account: account)
        create(:invoice, :draft, order: order, amount: 100.0)

        expect(customer.total_spent).to eq(0)
      end
    end

    describe "Counting customer orders" do
      let(:account) { create(:account) }
      let(:customer) { create(:customer, account: account) }

      it "returns the total number of orders placed" do
        create_list(:order, 3, customer: customer, account: account)
        expect(customer.orders_count).to eq(3)
      end

      it "returns 0 for new customers with no orders" do
        expect(customer.orders_count).to eq(0)
      end
    end
  end
end
