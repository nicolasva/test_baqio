# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomersHelper, type: :helper do
  let(:account) { create(:account) }

  describe "#customer_email_link" do
    it "returns a mailto link when email is present" do
      customer = create(:customer, account: account, email: "john@example.com")
      result = helper.customer_email_link(customer)
      expect(result).to have_css("a[href='mailto:john@example.com']", text: "john@example.com")
    end

    it "returns nil when email is blank" do
      customer = create(:customer, account: account, email: nil)
      expect(helper.customer_email_link(customer)).to be_nil
    end
  end

  describe "#customer_phone_link" do
    it "returns a tel link when phone is present" do
      customer = create(:customer, account: account, phone: "+33612345678")
      result = helper.customer_phone_link(customer)
      expect(result).to have_css("a[href='tel:+33612345678']", text: "+33612345678")
    end

    it "returns nil when phone is blank" do
      customer = create(:customer, account: account, phone: nil)
      expect(helper.customer_phone_link(customer)).to be_nil
    end
  end

  describe "#customer_address_formatted" do
    it "returns formatted address with line breaks" do
      customer = create(:customer, account: account, address: "123 Rue de Paris\n75001 Paris")
      result = helper.customer_address_formatted(customer)
      expect(result).to include("123 Rue de Paris")
      expect(result).to include("<br")
    end

    it "returns nil when address is blank" do
      customer = create(:customer, account: account, address: nil)
      expect(helper.customer_address_formatted(customer)).to be_nil
    end
  end
end
