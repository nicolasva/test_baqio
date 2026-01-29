# frozen_string_literal: true

# Account Association Shared Examples
# ====================================
# Shared examples for models that belong to an Account (multi-tenant).
#
# Usage:
#   it_behaves_like "a model belonging to account"
#   it_behaves_like "a model with soft delete"
#
# "a model belonging to account":
# - Tests belongs_to :account association
# - Tests validation (invalid without account)
# - Tests account accessor
#
# "a model with soft delete":
# - Tests deleted? and soft_delete methods exist
#

RSpec.shared_examples "a model belonging to account" do
  describe "account association" do
    it "belongs to account" do
      association = described_class.reflect_on_association(:account)
      expect(association.macro).to eq(:belongs_to)
    end

    it "is invalid without account" do
      record = build(described_class.model_name.singular.to_sym, account: nil)
      expect(record).not_to be_valid
      expect(record.errors[:account]).to be_present
    end

    it "can access account" do
      account = create(:account)
      record = create(described_class.model_name.singular.to_sym, account: account)
      expect(record.account).to eq(account)
    end
  end
end

RSpec.shared_examples "a model with soft delete" do
  describe "soft delete" do
    it "responds to deleted?" do
      expect(subject).to respond_to(:deleted?)
    end

    it "responds to soft_delete" do
      expect(subject).to respond_to(:soft_delete) if subject.respond_to?(:soft_delete)
    end
  end
end
