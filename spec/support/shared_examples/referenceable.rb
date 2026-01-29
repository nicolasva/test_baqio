# frozen_string_literal: true

# Referenceable Shared Examples
# =============================
# Shared examples for models that auto-generate reference numbers.
#
# Usage:
#   it_behaves_like "a referenceable model", :reference, "ORD"
#   it_behaves_like "a referenceable model", :number, "INV"
#
# Tests:
# - Reference starts with prefix (e.g., "ORD-", "INV-")
# - Reference includes date component (YYYYMMDD)
# - Existing reference is not overwritten
# - Each record gets a unique reference
#

RSpec.shared_examples "a referenceable model" do |attribute, prefix|
  describe "reference generation" do
    it "generates #{attribute} with #{prefix} prefix" do
      record = build(described_class.model_name.singular.to_sym)
      record.send(:"#{attribute}=", nil)
      record.valid?
      expect(record.send(attribute)).to start_with("#{prefix}-")
    end

    it "generates #{attribute} with date component" do
      record = build(described_class.model_name.singular.to_sym)
      record.send(:"#{attribute}=", nil)
      record.valid?
      expect(record.send(attribute)).to include(Time.current.strftime("%Y%m%d"))
    end

    it "does not override existing #{attribute}" do
      existing_ref = "#{prefix}-EXISTING-123"
      record = build(described_class.model_name.singular.to_sym, attribute => existing_ref)
      record.valid?
      expect(record.send(attribute)).to eq(existing_ref)
    end

    it "generates unique #{attribute} for each record" do
      record1 = create(described_class.model_name.singular.to_sym)
      record2 = create(described_class.model_name.singular.to_sym)
      expect(record1.send(attribute)).not_to eq(record2.send(attribute))
    end
  end
end
