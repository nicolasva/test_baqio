# frozen_string_literal: true

# PersonName Value Object Spec
# ============================
# Tests for the PersonName immutable value object.
#
# Covers:
# - Initialization (first_name, last_name, whitespace stripping, freeze)
# - Equality (==, hash for hash keys)
# - full_name: "First Last" format
# - reversed_name: "Last, First" format
# - initials: "FL" format
# - Predicates (present?, blank?)
# - to_s: returns full_name or empty string
# - Class methods: .empty, .parse (splits full name string)
#

require "rails_helper"

RSpec.describe PersonName do
  describe "#initialize" do
    it "creates person name with first and last name" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name.first_name).to eq("Jean")
      expect(name.last_name).to eq("Dupont")
    end

    it "strips whitespace" do
      name = PersonName.new(first_name: "  Jean  ", last_name: "  Dupont  ")

      expect(name.first_name).to eq("Jean")
      expect(name.last_name).to eq("Dupont")
    end

    it "handles nil values" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name.first_name).to be_nil
      expect(name.last_name).to be_nil
    end

    it "converts empty strings to nil" do
      name = PersonName.new(first_name: "", last_name: "")

      expect(name.first_name).to be_nil
      expect(name.last_name).to be_nil
    end

    it "is frozen after creation" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name).to be_frozen
    end
  end

  describe "#==" do
    it "returns true for equal names" do
      name1 = PersonName.new(first_name: "Jean", last_name: "Dupont")
      name2 = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name1 == name2).to be true
    end

    it "returns false for different first names" do
      name1 = PersonName.new(first_name: "Jean", last_name: "Dupont")
      name2 = PersonName.new(first_name: "Pierre", last_name: "Dupont")

      expect(name1 == name2).to be false
    end

    it "returns false for different last names" do
      name1 = PersonName.new(first_name: "Jean", last_name: "Dupont")
      name2 = PersonName.new(first_name: "Jean", last_name: "Martin")

      expect(name1 == name2).to be false
    end
  end

  describe "#hash" do
    it "returns same hash for equal objects" do
      name1 = PersonName.new(first_name: "Jean", last_name: "Dupont")
      name2 = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name1.hash).to eq(name2.hash)
    end

    it "can be used as hash key" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")
      hash = { name => "value" }

      expect(hash[PersonName.new(first_name: "Jean", last_name: "Dupont")]).to eq("value")
    end
  end

  describe "#full_name" do
    it "returns first and last name joined" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name.full_name).to eq("Jean Dupont")
    end

    it "returns only first name when no last name" do
      name = PersonName.new(first_name: "Jean", last_name: nil)

      expect(name.full_name).to eq("Jean")
    end

    it "returns only last name when no first name" do
      name = PersonName.new(first_name: nil, last_name: "Dupont")

      expect(name.full_name).to eq("Dupont")
    end

    it "returns nil when no names" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name.full_name).to be_nil
    end
  end

  describe "#reversed_name" do
    it "returns last name, first name" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name.reversed_name).to eq("Dupont, Jean")
    end

    it "returns only first name when no last name" do
      name = PersonName.new(first_name: "Jean", last_name: nil)

      expect(name.reversed_name).to eq("Jean")
    end

    it "returns only last name when no first name" do
      name = PersonName.new(first_name: nil, last_name: "Dupont")

      expect(name.reversed_name).to eq("Dupont")
    end
  end

  describe "#initials" do
    it "returns initials from full name" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name.initials).to eq("JD")
    end

    it "returns single initial when only first name" do
      name = PersonName.new(first_name: "Jean", last_name: nil)

      expect(name.initials).to eq("J")
    end

    it "returns single initial when only last name" do
      name = PersonName.new(first_name: nil, last_name: "Dupont")

      expect(name.initials).to eq("D")
    end

    it "returns nil when no names" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name.initials).to be_nil
    end
  end

  describe "#present?" do
    it "returns true when first name is present" do
      name = PersonName.new(first_name: "Jean", last_name: nil)

      expect(name).to be_present
    end

    it "returns true when last name is present" do
      name = PersonName.new(first_name: nil, last_name: "Dupont")

      expect(name).to be_present
    end

    it "returns false when no names" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name).not_to be_present
    end
  end

  describe "#blank?" do
    it "returns true when no names" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name).to be_blank
    end

    it "returns false when name is present" do
      name = PersonName.new(first_name: "Jean", last_name: nil)

      expect(name).not_to be_blank
    end
  end

  describe "#to_s" do
    it "returns full name" do
      name = PersonName.new(first_name: "Jean", last_name: "Dupont")

      expect(name.to_s).to eq("Jean Dupont")
    end

    it "returns empty string when blank" do
      name = PersonName.new(first_name: nil, last_name: nil)

      expect(name.to_s).to eq("")
    end
  end

  describe ".empty" do
    it "returns empty person name" do
      name = PersonName.empty

      expect(name.first_name).to be_nil
      expect(name.last_name).to be_nil
      expect(name).to be_blank
    end
  end

  describe ".parse" do
    it "parses full name string" do
      name = PersonName.parse("Jean Dupont")

      expect(name.first_name).to eq("Jean")
      expect(name.last_name).to eq("Dupont")
    end

    it "handles single name" do
      name = PersonName.parse("Jean")

      expect(name.first_name).to eq("Jean")
      expect(name.last_name).to be_nil
    end

    it "handles multiple last names" do
      name = PersonName.parse("Jean Pierre Dupont")

      expect(name.first_name).to eq("Jean")
      expect(name.last_name).to eq("Pierre Dupont")
    end

    it "returns empty for blank string" do
      name = PersonName.parse("")

      expect(name).to be_blank
    end

    it "returns empty for nil" do
      name = PersonName.parse(nil)

      expect(name).to be_blank
    end
  end
end
