# frozen_string_literal: true

# FulfillmentService Model Spec
# =============================
# Tests for the FulfillmentService (shipping provider) model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Validations (name required, uniqueness scoped to account)
# - Associations (account, fulfillments with dependent destroy)
# - Scopes (active, inactive)
# - Instance methods (activate!, deactivate!, fulfillments_count)
#

require "rails_helper"

RSpec.describe FulfillmentService, type: :model do
  describe "factory" do
    it "creates a valid fulfillment_service" do
      service = build(:fulfillment_service)
      expect(service).to be_valid
    end

    it "creates inactive service with trait" do
      service = build(:fulfillment_service, :inactive)
      expect(service.active).to be false
    end
  end

  describe "validations" do
    describe "name" do
      it "requires a name" do
        service = build(:fulfillment_service, name: nil)
        expect(service).not_to be_valid
        expect(service.errors[:name]).to include("can't be blank")
      end

      it "validates uniqueness within account" do
        account = create(:account)
        create(:fulfillment_service, account: account, name: "DHL Express")
        duplicate = build(:fulfillment_service, account: account, name: "DHL Express")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("has already been taken")
      end

      it "allows same name in different accounts" do
        account1 = create(:account)
        account2 = create(:account)
        create(:fulfillment_service, account: account1, name: "DHL Express")
        service2 = build(:fulfillment_service, account: account2, name: "DHL Express")

        expect(service2).to be_valid
      end
    end
  end

  describe "associations" do
    let(:account) { create(:account) }
    let(:service) { create(:fulfillment_service, account: account) }

    it "belongs to account" do
      expect(service.account).to eq(account)
    end

    describe "#fulfillments" do
      it "has many fulfillments" do
        fulfillment = create(:fulfillment, fulfillment_service: service)
        expect(service.fulfillments).to include(fulfillment)
      end

      it "destroys associated fulfillments when destroyed" do
        create(:fulfillment, fulfillment_service: service)
        expect { service.destroy }.to change(Fulfillment, :count).by(-1)
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".active" do
      it "returns only active services" do
        active = create(:fulfillment_service, account: account, active: true)
        inactive = create(:fulfillment_service, account: account, active: false)

        expect(FulfillmentService.active).to include(active)
        expect(FulfillmentService.active).not_to include(inactive)
      end
    end

    describe ".inactive" do
      it "returns only inactive services" do
        active = create(:fulfillment_service, account: account, active: true)
        inactive = create(:fulfillment_service, account: account, active: false)

        expect(FulfillmentService.inactive).to include(inactive)
        expect(FulfillmentService.inactive).not_to include(active)
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:service) { create(:fulfillment_service, account: account, active: false) }

    describe "#activate!" do
      it "sets active to true" do
        service.activate!
        expect(service.reload.active).to be true
      end
    end

    describe "#deactivate!" do
      it "sets active to false" do
        service.update!(active: true)
        service.deactivate!
        expect(service.reload.active).to be false
      end
    end

    describe "#fulfillments_count" do
      it "returns number of fulfillments" do
        create_list(:fulfillment, 3, fulfillment_service: service)
        expect(service.fulfillments_count).to eq(3)
      end

      it "returns 0 when no fulfillments" do
        expect(service.fulfillments_count).to eq(0)
      end
    end
  end
end
