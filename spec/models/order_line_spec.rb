# frozen_string_literal: true

# OrderLine Model Spec
# ====================
# Tests for the OrderLine (line item) model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Validations (name, quantity, unit_price required)
# - Associations (order, delegated account)
# - Scopes (by_sku, expensive_first)
# - Callbacks (calculate_total_price, update_order_total on save/destroy)
# - Instance methods (increase_quantity, decrease_quantity)
#
# Note: Quantity must be positive integer. Unit price can be zero.
# Callbacks automatically update parent order total.
#

require "rails_helper"

RSpec.describe OrderLine, type: :model do
  describe "factory" do
    it "creates a valid order_line" do
      line = build(:order_line)
      expect(line).to be_valid
    end

    it "creates expensive line with trait" do
      line = build(:order_line, :expensive)
      expect(line.unit_price).to eq(199.99)
    end

    it "creates bulk line with trait" do
      line = build(:order_line, :bulk)
      expect(line.quantity).to eq(10)
    end
  end

  describe "validations" do
    describe "name" do
      it "requires a name" do
        line = build(:order_line, name: nil)
        expect(line).not_to be_valid
        expect(line.errors[:name]).to include("can't be blank")
      end
    end

    describe "quantity" do
      it "requires a quantity" do
        line = build(:order_line)
        line.quantity = nil
        expect(line).not_to be_valid
        expect(line.errors[:quantity]).to include("can't be blank")
      end

      it "requires quantity to be positive" do
        line = build(:order_line, quantity: 0)
        expect(line).not_to be_valid
        expect(line.errors[:quantity]).to include("must be greater than 0")
      end

      it "requires quantity to be negative" do
        line = build(:order_line, quantity: -1)
        expect(line).not_to be_valid
      end

      it "requires quantity to be an integer" do
        line = build(:order_line, quantity: 1.5)
        expect(line).not_to be_valid
        expect(line.errors[:quantity]).to include("must be an integer")
      end
    end

    describe "unit_price" do
      it "requires a unit_price" do
        line = build(:order_line)
        line.unit_price = nil
        expect(line).not_to be_valid
        expect(line.errors[:unit_price]).to include("can't be blank")
      end

      it "requires unit_price to be non-negative" do
        line = build(:order_line, unit_price: -1)
        expect(line).not_to be_valid
        expect(line.errors[:unit_price]).to include("must be greater than or equal to 0")
      end

      it "allows zero unit_price" do
        line = build(:order_line, unit_price: 0)
        expect(line).to be_valid
      end
    end
  end

  describe "associations" do
    it "belongs to order" do
      order = create(:order)
      line = create(:order_line, order: order)
      expect(line.order).to eq(order)
    end

    describe "#account (delegated)" do
      it "delegates account to order" do
        account = create(:account)
        customer = create(:customer, account: account)
        order = create(:order, account: account, customer: customer)
        line = create(:order_line, order: order)

        expect(line.account).to eq(account)
      end
    end
  end

  describe "scopes" do
    describe ".by_sku" do
      it "filters by sku" do
        line1 = create(:order_line, sku: "SKU-001")
        line2 = create(:order_line, sku: "SKU-002")

        expect(OrderLine.by_sku("SKU-001")).to include(line1)
        expect(OrderLine.by_sku("SKU-001")).not_to include(line2)
      end
    end

    describe ".expensive_first" do
      it "orders by total_price desc" do
        cheap = create(:order_line, quantity: 1, unit_price: 10.0)
        expensive = create(:order_line, quantity: 1, unit_price: 100.0)

        expect(OrderLine.expensive_first.first).to eq(expensive)
        expect(OrderLine.expensive_first.last).to eq(cheap)
      end
    end
  end

  describe "callbacks" do
    describe "before_validation :calculate_total_price" do
      it "calculates total_price from quantity and unit_price" do
        line = build(:order_line, quantity: 3, unit_price: 25.0, total_price: nil)
        line.valid?

        expect(line.total_price).to eq(75.0)
      end

      it "handles nil quantity" do
        line = build(:order_line, quantity: nil, unit_price: 25.0, total_price: nil)
        line.valid?

        expect(line.total_price).to eq(0)
      end

      it "handles nil unit_price" do
        line = build(:order_line, quantity: 3, unit_price: nil, total_price: nil)
        line.valid?

        expect(line.total_price).to eq(0)
      end
    end

    describe "after_save :update_order_total" do
      let(:order) { create(:order, total_amount: 0) }

      it "updates order total after save" do
        create(:order_line, order: order, quantity: 2, unit_price: 10.0)
        expect(order.reload.total_amount).to eq(20.0)
      end

      it "updates order total when line is updated" do
        line = create(:order_line, order: order, quantity: 2, unit_price: 10.0)
        line.update!(quantity: 5)

        expect(order.reload.total_amount).to eq(50.0)
      end
    end

    describe "after_destroy :update_order_total" do
      let(:order) { create(:order, total_amount: 0) }

      it "updates order total after destroy" do
        line1 = create(:order_line, order: order, quantity: 2, unit_price: 10.0)
        create(:order_line, order: order, quantity: 1, unit_price: 15.0)

        expect(order.reload.total_amount).to eq(35.0)

        line1.destroy

        expect(order.reload.total_amount).to eq(15.0)
      end
    end
  end

  describe "instance methods" do
    describe "#increase_quantity" do
      let(:line) { create(:order_line, quantity: 5) }

      it "increases quantity by 1 by default" do
        line.increase_quantity
        expect(line.reload.quantity).to eq(6)
      end

      it "increases quantity by specified amount" do
        line.increase_quantity(3)
        expect(line.reload.quantity).to eq(8)
      end

      it "updates total_price" do
        line.increase_quantity(5)
        expect(line.reload.total_price).to eq(line.quantity * line.unit_price)
      end
    end

    describe "#decrease_quantity" do
      let(:line) { create(:order_line, quantity: 5) }

      it "decreases quantity by 1 by default" do
        line.decrease_quantity
        expect(line.reload.quantity).to eq(4)
      end

      it "decreases quantity by specified amount" do
        line.decrease_quantity(2)
        expect(line.reload.quantity).to eq(3)
      end

      it "destroys line if quantity becomes 0" do
        line.decrease_quantity(5)
        expect(OrderLine.find_by(id: line.id)).to be_nil
      end

      it "destroys line if quantity becomes negative" do
        line.decrease_quantity(10)
        expect(OrderLine.find_by(id: line.id)).to be_nil
      end

      it "updates total_price" do
        line.decrease_quantity(2)
        expect(line.reload.total_price).to eq(line.quantity * line.unit_price)
      end
    end
  end
end
