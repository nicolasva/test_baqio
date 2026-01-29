# frozen_string_literal: true

# Money Value Object Spec
# =======================
# Tests for the Money immutable value object.
#
# Covers:
# - Initialization (amount, currency, normalization, freeze)
# - Arithmetic (+, -, *, /, negation)
# - Comparison (<=> , ==, hash for hash keys)
# - Predicates (zero?, positive?, negative?)
# - Formatting (to_s, to_f, to_d)
# - Class methods (zero, from_cents)
#
# Note: Currency defaults to EUR. Currency mismatch raises ArgumentError.
#

require "rails_helper"

RSpec.describe Money do
  describe "#initialize" do
    it "creates money with amount and default currency" do
      money = Money.new(100)

      expect(money.amount).to eq(BigDecimal("100"))
      expect(money.currency).to eq("EUR")
    end

    it "creates money with specified currency" do
      money = Money.new(100, "USD")

      expect(money.currency).to eq("USD")
    end

    it "normalizes currency to uppercase" do
      money = Money.new(100, "usd")

      expect(money.currency).to eq("USD")
    end

    it "handles nil amount as zero" do
      money = Money.new(nil)

      expect(money.amount).to eq(BigDecimal("0"))
    end

    it "handles string amounts" do
      money = Money.new("99.99")

      expect(money.amount).to eq(BigDecimal("99.99"))
    end

    it "is frozen after creation" do
      money = Money.new(100)

      expect(money).to be_frozen
    end
  end

  describe "arithmetic operations" do
    let(:money1) { Money.new(100, "EUR") }
    let(:money2) { Money.new(50, "EUR") }

    describe "#+" do
      it "adds two money objects" do
        result = money1 + money2

        expect(result.amount).to eq(BigDecimal("150"))
        expect(result.currency).to eq("EUR")
      end

      it "raises error for different currencies" do
        usd = Money.new(50, "USD")

        expect { money1 + usd }.to raise_error(ArgumentError, /Currency mismatch/)
      end
    end

    describe "#-" do
      it "subtracts two money objects" do
        result = money1 - money2

        expect(result.amount).to eq(BigDecimal("50"))
      end

      it "raises error for different currencies" do
        usd = Money.new(50, "USD")

        expect { money1 - usd }.to raise_error(ArgumentError, /Currency mismatch/)
      end
    end

    describe "#*" do
      it "multiplies money by a number" do
        result = money1 * 2

        expect(result.amount).to eq(BigDecimal("200"))
      end

      it "handles decimal multipliers" do
        result = money1 * 0.5

        expect(result.amount).to eq(BigDecimal("50"))
      end
    end

    describe "#/" do
      it "divides money by a number" do
        result = money1 / 2

        expect(result.amount).to eq(BigDecimal("50"))
      end

      it "raises error for division by zero" do
        expect { money1 / 0 }.to raise_error(ZeroDivisionError)
      end
    end

    describe "#-@" do
      it "negates the amount" do
        result = -money1

        expect(result.amount).to eq(BigDecimal("-100"))
      end
    end
  end

  describe "comparison" do
    describe "#<=>" do
      it "compares money objects" do
        small = Money.new(50)
        large = Money.new(100)

        expect(small <=> large).to eq(-1)
        expect(large <=> small).to eq(1)
        expect(small <=> Money.new(50)).to eq(0)
      end

      it "returns nil for different currencies" do
        eur = Money.new(100, "EUR")
        usd = Money.new(100, "USD")

        expect(eur <=> usd).to be_nil
      end

      it "returns nil for non-money objects" do
        money = Money.new(100)

        expect(money <=> 100).to be_nil
      end
    end

    describe "#==" do
      it "returns true for equal money objects" do
        money1 = Money.new(100, "EUR")
        money2 = Money.new(100, "EUR")

        expect(money1 == money2).to be true
      end

      it "returns false for different amounts" do
        money1 = Money.new(100)
        money2 = Money.new(50)

        expect(money1 == money2).to be false
      end

      it "returns false for different currencies" do
        eur = Money.new(100, "EUR")
        usd = Money.new(100, "USD")

        expect(eur == usd).to be false
      end
    end

    describe "#hash" do
      it "returns same hash for equal objects" do
        money1 = Money.new(100, "EUR")
        money2 = Money.new(100, "EUR")

        expect(money1.hash).to eq(money2.hash)
      end

      it "can be used as hash key" do
        money = Money.new(100)
        hash = { money => "value" }

        expect(hash[Money.new(100)]).to eq("value")
      end
    end
  end

  describe "predicates" do
    describe "#zero?" do
      it "returns true for zero amount" do
        expect(Money.new(0)).to be_zero
      end

      it "returns false for non-zero amount" do
        expect(Money.new(100)).not_to be_zero
      end
    end

    describe "#positive?" do
      it "returns true for positive amount" do
        expect(Money.new(100)).to be_positive
      end

      it "returns false for zero" do
        expect(Money.new(0)).not_to be_positive
      end

      it "returns false for negative amount" do
        expect(Money.new(-100)).not_to be_positive
      end
    end

    describe "#negative?" do
      it "returns true for negative amount" do
        expect(Money.new(-100)).to be_negative
      end

      it "returns false for positive amount" do
        expect(Money.new(100)).not_to be_negative
      end
    end
  end

  describe "formatting" do
    describe "#to_s" do
      it "returns formatted string" do
        money = Money.new(99.99, "EUR")

        expect(money.to_s).to eq("99.99 EUR")
      end
    end

    describe "#to_f" do
      it "returns float value" do
        money = Money.new(99.99)

        expect(money.to_f).to eq(99.99)
      end
    end

    describe "#to_d" do
      it "returns BigDecimal value" do
        money = Money.new(99.99)

        expect(money.to_d).to eq(BigDecimal("99.99"))
      end
    end
  end

  describe "class methods" do
    describe ".zero" do
      it "creates zero money with default currency" do
        money = Money.zero

        expect(money.amount).to eq(BigDecimal("0"))
        expect(money.currency).to eq("EUR")
      end

      it "creates zero money with specified currency" do
        money = Money.zero("USD")

        expect(money.currency).to eq("USD")
      end
    end

    describe ".from_cents" do
      it "creates money from cents" do
        money = Money.from_cents(9999)

        expect(money.amount).to eq(BigDecimal("99.99"))
      end
    end
  end
end
