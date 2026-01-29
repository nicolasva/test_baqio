# frozen_string_literal: true

# Account Model Spec
# ==================
# Tests for the Account model (multi-tenant root).
#
# Covers:
# - Factory validation (basic creation)
# - Validations (name required)
# - Associations (customers, orders, invoices, fulfillment_services, events)
# - Scopes (by_name)
# - Instance methods (active_orders, total_revenue)
#

require "rails_helper"

RSpec.describe Account, type: :model do
  describe "factory" do
    it "creates a valid account" do
      account = build(:account)
      expect(account).to be_valid
    end

    it "creates unique names" do
      account1 = create(:account)
      account2 = create(:account)
      expect(account1.name).not_to eq(account2.name)
    end
  end

  describe "validations" do
    it "requires a name" do
      account = build(:account, name: nil)
      expect(account).not_to be_valid
      expect(account.errors[:name]).to include("can't be blank")
    end

    it "requires name to be present (not empty string)" do
      account = build(:account, name: "")
      expect(account).not_to be_valid
    end
  end

  describe "associations" do
    let(:account) { create(:account) }

    describe "#account_events" do
      it "has many account_events" do
        event = create(:account_event, account: account)
        expect(account.account_events).to include(event)
      end

      it "destroys associated account_events when destroyed" do
        create(:account_event, account: account)
        expect { account.destroy }.to change(AccountEvent, :count).by(-1)
      end
    end

    describe "#customers" do
      it "has many customers" do
        customer = create(:customer, account: account)
        expect(account.customers).to include(customer)
      end

      it "destroys associated customers when destroyed" do
        create(:customer, account: account)
        expect { account.destroy }.to change(Customer, :count).by(-1)
      end
    end

    describe "#orders" do
      it "has many orders" do
        customer = create(:customer, account: account)
        order = create(:order, account: account, customer: customer)
        expect(account.orders).to include(order)
      end

      it "has many orders through account" do
        customer = create(:customer, account: account)
        order = create(:order, account: account, customer: customer)
        expect(account.orders).to include(order)
        expect(account.orders.count).to eq(1)
      end
    end

    describe "#fulfillment_services" do
      it "has many fulfillment_services" do
        service = create(:fulfillment_service, account: account)
        expect(account.fulfillment_services).to include(service)
      end

      it "destroys associated fulfillment_services when destroyed" do
        create(:fulfillment_service, account: account)
        expect { account.destroy }.to change(FulfillmentService, :count).by(-1)
      end
    end

    describe "#invoices" do
      it "has many invoices through orders" do
        customer = create(:customer, account: account)
        order = create(:order, account: account, customer: customer)
        invoice = create(:invoice, order: order)
        expect(account.invoices).to include(invoice)
      end
    end
  end

  describe "scopes" do
    describe ".by_name" do
      it "finds accounts by partial name match" do
        account1 = create(:account, name: "Acme Corporation")
        account2 = create(:account, name: "Beta Inc")
        create(:account, name: "Gamma LLC")

        expect(Account.by_name("Acme")).to include(account1)
        expect(Account.by_name("Acme")).not_to include(account2)
      end

      it "finds by partial match case-insensitively in SQLite" do
        account = create(:account, name: "Acme Corporation")
        # SQLite LIKE is case-insensitive by default
        expect(Account.by_name("acme")).to include(account)
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account) }

    describe "#active_orders" do
      it "returns orders that are not cancelled" do
        pending_order = create(:order, :pending, account: account, customer: customer)
        validated_order = create(:order, :validated, account: account, customer: customer)
        cancelled_order = create(:order, :cancelled, account: account, customer: customer)

        active = account.active_orders

        expect(active).to include(pending_order, validated_order)
        expect(active).not_to include(cancelled_order)
      end
    end

    describe "#total_revenue" do
      it "returns sum of paid invoices" do
        order1 = create(:order, account: account, customer: customer)
        order2 = create(:order, account: account, customer: customer)
        create(:invoice, :paid, order: order1, amount: 100.0, tax_amount: 20.0)
        create(:invoice, :paid, order: order2, amount: 200.0, tax_amount: 40.0)
        create(:invoice, :draft, order: create(:order, account: account, customer: customer), amount: 50.0)

        expect(account.total_revenue).to eq(360.0) # 120 + 240
      end

      it "returns 0 when no paid invoices" do
        expect(account.total_revenue).to eq(0)
      end
    end
  end
end
