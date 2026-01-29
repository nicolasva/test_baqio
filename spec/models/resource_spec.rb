# frozen_string_literal: true

# Resource Model Spec
# ===================
# Tests for the Resource model (polymorphic event reference).
#
# Covers:
# - Factory validation (basic creation, traits)
# - Constants (RESOURCE_TYPES: Order, Invoice, Customer, Fulfillment)
# - Validations (name, resource_type required and in list)
# - Associations (account_events with dependent destroy)
# - Scopes (by_type, orders, invoices, customers, fulfillments)
# - Class methods (for creating/finding resources by record)
#
# Note: Resource provides a stable reference for events even if
# the original record is deleted.
#

require "rails_helper"

RSpec.describe Resource, type: :model do
  describe "factory" do
    it "creates a valid resource" do
      resource = build(:resource)
      expect(resource).to be_valid
    end

    it "creates resource with order trait" do
      resource = build(:resource, :order)
      expect(resource.resource_type).to eq("Order")
    end

    it "creates resource with invoice trait" do
      resource = build(:resource, :invoice)
      expect(resource.resource_type).to eq("Invoice")
    end
  end

  describe "constants" do
    it "defines RESOURCE_TYPES" do
      expect(Resource::RESOURCE_TYPES).to eq(%w[Order Invoice Customer Fulfillment OrderLine])
    end
  end

  describe "validations" do
    it "requires a name" do
      resource = build(:resource, name: nil)
      expect(resource).not_to be_valid
      expect(resource.errors[:name]).to include("can't be blank")
    end

    it "requires a resource_type" do
      resource = build(:resource, resource_type: nil)
      expect(resource).not_to be_valid
      expect(resource.errors[:resource_type]).to include("can't be blank")
    end

    it "requires resource_type to be in RESOURCE_TYPES" do
      resource = build(:resource, resource_type: "InvalidType")
      expect(resource).not_to be_valid
      expect(resource.errors[:resource_type]).to include("is not included in the list")
    end

    it "accepts valid resource_types" do
      Resource::RESOURCE_TYPES.each do |type|
        resource = build(:resource, resource_type: type)
        expect(resource).to be_valid
      end
    end
  end

  describe "associations" do
    it "has many account_events" do
      resource = create(:resource)
      event = create(:account_event, resource: resource)
      expect(resource.account_events).to include(event)
    end

    it "destroys associated account_events when destroyed" do
      resource = create(:resource)
      create(:account_event, resource: resource)
      expect { resource.destroy }.to change(AccountEvent, :count).by(-1)
    end
  end

  describe "scopes" do
    before do
      @order_resource = create(:resource, :order)
      @invoice_resource = create(:resource, :invoice)
      @customer_resource = create(:resource, :customer)
      @fulfillment_resource = create(:resource, :fulfillment)
    end

    describe ".by_type" do
      it "filters by resource_type" do
        expect(Resource.by_type("Order")).to include(@order_resource)
        expect(Resource.by_type("Order")).not_to include(@invoice_resource)
      end
    end

    describe ".orders" do
      it "returns only order resources" do
        expect(Resource.orders).to include(@order_resource)
        expect(Resource.orders).not_to include(@invoice_resource)
      end
    end

    describe ".invoices" do
      it "returns only invoice resources" do
        expect(Resource.invoices).to include(@invoice_resource)
        expect(Resource.invoices).not_to include(@order_resource)
      end
    end

    describe ".customers" do
      it "returns only customer resources" do
        expect(Resource.customers).to include(@customer_resource)
        expect(Resource.customers).not_to include(@order_resource)
      end
    end

    describe ".fulfillments" do
      it "returns only fulfillment resources" do
        expect(Resource.fulfillments).to include(@fulfillment_resource)
        expect(Resource.fulfillments).not_to include(@order_resource)
      end
    end
  end

  describe "class methods" do
    describe ".for" do
      let(:account) { create(:account) }
      let(:customer) { create(:customer, account: account) }
      let(:order) { create(:order, account: account, customer: customer) }

      it "creates a new resource for a record" do
        expect { Resource.for(order) }.to change(Resource, :count).by(1)
      end

      it "returns existing resource if already exists" do
        resource = Resource.for(order)
        expect(Resource.for(order)).to eq(resource)
        expect(Resource.count).to eq(1)
      end

      it "sets correct name format" do
        resource = Resource.for(order)
        expect(resource.name).to eq("Order##{order.id}")
      end

      it "sets correct resource_type" do
        resource = Resource.for(order)
        expect(resource.resource_type).to eq("Order")
      end

      it "works with different record types" do
        invoice = create(:invoice, order: order)
        resource = Resource.for(invoice)
        expect(resource.name).to eq("Invoice##{invoice.id}")
        expect(resource.resource_type).to eq("Invoice")
      end
    end
  end
end
