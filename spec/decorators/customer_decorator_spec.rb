# frozen_string_literal: true

# CustomerDecorator Spec
# ======================
# Tests for the CustomerDecorator (presentation logic).
#
# Covers:
# - display_name: full name → email → "Customer #ID" fallback
# - full_name: first + last name joining
# - initials: first letters of name parts
# - total_spent_formatted: currency display
# - orders_count_text: singular/plural formatting
#

require "rails_helper"

RSpec.describe CustomerDecorator do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, first_name: "Marie", last_name: "Dupont", email: "marie@example.com") }
  let(:decorated_customer) { customer.decorate }

  describe "#display_name" do
    it "returns full name when present" do
      expect(decorated_customer.display_name).to eq("Marie Dupont")
    end

    it "returns email when no name" do
      customer.update!(first_name: nil, last_name: nil)
      expect(decorated_customer.display_name).to eq("marie@example.com")
    end

    it "returns Customer #id when no name or email" do
      customer.update!(first_name: nil, last_name: nil, email: nil)
      expect(decorated_customer.display_name).to eq("Customer ##{customer.id}")
    end
  end

  describe "#full_name" do
    it "returns first and last name joined" do
      expect(decorated_customer.full_name).to eq("Marie Dupont")
    end

    it "returns only first name when no last name" do
      customer.update!(last_name: nil)
      expect(decorated_customer.full_name).to eq("Marie")
    end

    it "returns nil when no name" do
      customer.update!(first_name: nil, last_name: nil)
      expect(decorated_customer.full_name).to be_nil
    end
  end

  describe "#initials" do
    it "returns initials from full name" do
      expect(decorated_customer.initials).to eq("MD")
    end

    it "returns ? when no name" do
      customer.update!(first_name: nil, last_name: nil)
      expect(decorated_customer.initials).to eq("?")
    end
  end

  describe "#total_spent_formatted" do
    it "returns formatted currency" do
      order = create(:order, account: account, customer: customer)
      create(:invoice, :paid, order: order, amount: 100.0, tax_amount: 20.0)

      expect(decorated_customer.total_spent_formatted).to include("120")
    end
  end

  describe "#orders_count_text" do
    it "returns singular for 1 order" do
      create(:order, account: account, customer: customer)
      expect(decorated_customer.orders_count_text).to eq("1 order")
    end

    it "returns plural for multiple orders" do
      create_list(:order, 3, account: account, customer: customer)
      expect(decorated_customer.orders_count_text).to eq("3 orders")
    end

    it "returns 0 orders when no orders" do
      expect(decorated_customer.orders_count_text).to eq("0 orders")
    end
  end
end
