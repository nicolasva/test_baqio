# frozen_string_literal: true

# Customers::SearchQuery Spec
# ===========================
# Tests for the customer search and filter query.
#
# Covers:
# - Text search (q param): first name, last name, email, partial match
# - Filters:
#   - has_orders: customers with/without orders
#   - has_email: customers with/without email
# - Sorting:
#   - Default: created_at desc
#   - Custom: name asc/desc
#

require "rails_helper"

RSpec.describe Customers::SearchQuery do
  let(:account) { create(:account) }

  describe "#call" do
    context "with text search" do
      before do
        create(:customer, account: account, first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
        create(:customer, account: account, first_name: "Marie", last_name: "Martin", email: "marie@example.com")
        create(:customer, account: account, first_name: "Pierre", last_name: "Durand", email: "pierre@example.com")
      end

      it "searches by first name" do
        result = described_class.new(account.customers, params: { q: "Jean" }).call

        expect(result.count).to eq(1)
        expect(result.first.first_name).to eq("Jean")
      end

      it "searches by last name" do
        result = described_class.new(account.customers, params: { q: "Dupont" }).call

        expect(result.count).to eq(1)
      end

      it "searches by email" do
        result = described_class.new(account.customers, params: { q: "marie@" }).call

        expect(result.count).to eq(1)
      end

      it "searches with partial match" do
        result = described_class.new(account.customers, params: { q: "Du" }).call

        expect(result.count).to eq(2) # Dupont and Durand
      end
    end

    context "with has_orders filter" do
      before do
        @customer_with_orders = create(:customer, account: account)
        create(:order, account: account, customer: @customer_with_orders)

        @customer_without_orders = create(:customer, account: account)
      end

      it "filters customers with orders" do
        result = described_class.new(account.customers, params: { has_orders: true }).call

        expect(result).to include(@customer_with_orders)
        expect(result).not_to include(@customer_without_orders)
      end

      it "filters customers without orders" do
        result = described_class.new(account.customers, params: { has_orders: false }).call

        expect(result).to include(@customer_without_orders)
        expect(result).not_to include(@customer_with_orders)
      end
    end

    context "with has_email filter" do
      before do
        @customer_with_email = create(:customer, account: account, email: "test@example.com")
        @customer_without_email = create(:customer, account: account, email: nil)
      end

      it "filters customers with email" do
        result = described_class.new(account.customers, params: { has_email: true }).call

        expect(result).to include(@customer_with_email)
        expect(result).not_to include(@customer_without_email)
      end

      it "filters customers without email" do
        result = described_class.new(account.customers, params: { has_email: false }).call

        expect(result).to include(@customer_without_email)
        expect(result).not_to include(@customer_with_email)
      end
    end

    context "with sorting" do
      before do
        create(:customer, account: account, first_name: "Zoé", created_at: 1.day.ago)
        create(:customer, account: account, first_name: "Alice", created_at: 2.days.ago)
        create(:customer, account: account, first_name: "Martin", created_at: 3.days.ago)
      end

      it "sorts by created_at desc by default" do
        result = described_class.new(account.customers).call

        expect(result.first.first_name).to eq("Zoé")
      end

      it "sorts by name" do
        result = described_class.new(account.customers, params: { sort_by: :name, sort_dir: :asc }).call

        expect(result.first.first_name).to eq("Alice")
      end
    end
  end
end
