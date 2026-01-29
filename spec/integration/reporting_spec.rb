# frozen_string_literal: true

# Reporting Integration Spec
# ==========================
# End-to-end tests for business reporting features.
#
# Covers:
# - Sales reporting:
#   - Total account revenue
#   - Customer spending breakdown
#   - Orders by status
#   - Top customers by spending
# - Invoice aging report:
#   - Current/due soon/overdue filtering
#   - Days overdue/until due calculations
# - Fulfillment performance:
#   - Transit duration by fulfillment
#   - Average transit time
#   - Counts by status
# - Order line analysis:
#   - Items per order
#   - Quantity sums
#   - Empty order detection
#   - SKU prefix grouping (VET-, ELEC-, ACC-)
#

require "rails_helper"

RSpec.describe "Reporting Integration", type: :model do
  let(:account) { create(:account, name: "Test Boutique") }

  describe "sales reporting" do
    before do
      # Create test data for reporting
      @customer1 = create(:customer, :french, account: account)
      @customer2 = create(:customer, :belgian, account: account)

      # Create orders for customer 1
      order1 = create(:order, :validated, account: account, customer: @customer1, total_amount: 150.0)
      create(:invoice, :paid, order: order1, amount: 150.0, tax_amount: 0)

      order2 = create(:order, :validated, account: account, customer: @customer1, total_amount: 200.0)
      create(:invoice, :paid, order: order2, amount: 200.0, tax_amount: 0)

      # Create orders for customer 2
      order3 = create(:order, :validated, account: account, customer: @customer2, total_amount: 300.0)
      create(:invoice, :paid, order: order3, amount: 300.0, tax_amount: 0)

      # Pending orders (not counted in revenue)
      create(:order, :pending, account: account, customer: @customer1, total_amount: 500.0)
    end

    it "calculates total account revenue" do
      expect(account.total_revenue).to eq(650.0)
    end

    it "calculates customer spending" do
      expect(@customer1.total_spent).to eq(350.0)
      expect(@customer2.total_spent).to eq(300.0)
    end

    it "counts orders by status" do
      expect(account.orders.pending.count).to eq(1)
      # Orders remain validated since we only created invoices, not called invoice!
      expect(account.orders.validated.count).to eq(3)
      expect(account.active_orders.count).to eq(4)
    end

    it "identifies top customers by spending" do
      top_customers = account.customers.sort_by { |c| -c.total_spent }.first(2)
      expect(top_customers.first).to eq(@customer1)
      expect(top_customers.first.total_spent).to eq(350.0)
    end
  end

  describe "invoice aging report" do
    before do
      customer = create(:customer, account: account)

      # Current invoices
      order1 = create(:order, :validated, account: account, customer: customer)
      @current = create(:invoice, :sent, order: order1, issued_at: Date.current, due_at: 30.days.from_now)

      # Due soon
      order2 = create(:order, :validated, account: account, customer: customer)
      @due_soon = create(:invoice, :sent, order: order2, issued_at: 25.days.ago, due_at: 5.days.from_now)

      # Overdue 0-30 days
      order3 = create(:order, :validated, account: account, customer: customer)
      @overdue_30 = create(:invoice, :sent, order: order3, issued_at: 45.days.ago, due_at: 15.days.ago)

      # Overdue 30-60 days
      order4 = create(:order, :validated, account: account, customer: customer)
      @overdue_60 = create(:invoice, :sent, order: order4, issued_at: 75.days.ago, due_at: 45.days.ago)

      # Paid invoices
      order5 = create(:order, :validated, account: account, customer: customer)
      @paid = create(:invoice, :paid, order: order5)
    end

    it "filters current invoices (not yet due)" do
      current = account.invoices.sent.where("due_at > ?", Date.current)
      expect(current).to include(@current)
      expect(current).not_to include(@overdue_30)
    end

    it "filters overdue invoices" do
      expect(account.invoices.overdue.count).to eq(2)
    end

    it "filters invoices due soon" do
      expect(account.invoices.due_soon(7).count).to eq(1)
    end

    it "calculates days overdue correctly" do
      expect(@overdue_30.days_overdue).to eq(15)
      expect(@overdue_60.days_overdue).to eq(45)
    end

    it "calculates days until due correctly" do
      expect(@current.days_until_due).to eq(30)
      expect(@due_soon.days_until_due).to eq(5)
    end
  end

  describe "fulfillment performance report" do
    before do
      service = create(:fulfillment_service, :dhl, account: account)

      # Fast delivery (1 day transit)
      @fast = create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 3.days.ago,
        delivered_at: 2.days.ago,
        tracking_number: "FAST001"
      )

      # Normal delivery (3 days transit)
      @normal = create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 5.days.ago,
        delivered_at: 2.days.ago,
        tracking_number: "NORM001"
      )

      # Slow delivery (7 days transit)
      @slow = create(:fulfillment, fulfillment_service: service,
        status: "delivered",
        shipped_at: 10.days.ago,
        delivered_at: 3.days.ago,
        tracking_number: "SLOW001"
      )

      # In transit
      @in_transit = create(:fulfillment, :shipped, fulfillment_service: service)

      # Pending
      @pending = create(:fulfillment, :pending, fulfillment_service: service)
    end

    it "calculates transit duration for each fulfillment" do
      expect(@fast.transit_duration).to eq(1)
      expect(@normal.transit_duration).to eq(3)
      expect(@slow.transit_duration).to eq(7)
    end

    it "returns nil for non-delivered fulfillments" do
      expect(@in_transit.transit_duration).to be_nil
      expect(@pending.transit_duration).to be_nil
    end

    it "calculates average transit time" do
      delivered = Fulfillment.delivered
      transit_times = delivered.map(&:transit_duration).compact
      avg_transit = transit_times.sum.to_f / transit_times.size

      expect(avg_transit).to be_within(0.1).of(3.67)
    end

    it "counts fulfillments by status" do
      expect(Fulfillment.pending.count).to eq(1)
      expect(Fulfillment.shipped.count).to eq(1)
      expect(Fulfillment.delivered.count).to eq(3)
      expect(Fulfillment.in_transit.count).to eq(1) # Only shipped is in transit
      expect(Fulfillment.completed.count).to eq(3) # Delivered only
    end
  end

  describe "order line analysis" do
    before do
      customer = create(:customer, account: account)

      # Order 1: Clothing items
      @order1 = create(:order, :pending, account: account, customer: customer)
      create(:order_line, :clothing, order: @order1, quantity: 2)
      create(:order_line, :clothing, order: @order1, quantity: 1)
      @order1.update_total!

      # Order 2: Electronics
      @order2 = create(:order, :pending, account: account, customer: customer)
      create(:order_line, :electronics, order: @order2, quantity: 1)
      @order2.update_total!

      # Order 3: Mixed
      @order3 = create(:order, :pending, account: account, customer: customer)
      create(:order_line, :clothing, order: @order3, quantity: 1)
      create(:order_line, :accessories, order: @order3, quantity: 2)
      @order3.update_total!
    end

    it "counts items per order" do
      expect(@order1.lines_count).to eq(2)
      expect(@order2.lines_count).to eq(1)
      expect(@order3.lines_count).to eq(2)
    end

    it "calculates total quantity per order" do
      expect(@order1.order_lines.sum(:quantity)).to eq(3)
      expect(@order2.order_lines.sum(:quantity)).to eq(1)
      expect(@order3.order_lines.sum(:quantity)).to eq(3)
    end

    it "identifies empty orders" do
      customer = create(:customer, account: account)
      empty_order = create(:order, :pending, account: account, customer: customer)
      expect(empty_order.empty?).to be true
      expect(@order1.empty?).to be false
    end

    it "groups order lines by SKU prefix" do
      all_lines = OrderLine.all
      clothing_lines = all_lines.select { |l| l.sku&.start_with?("VET-") }
      electronics_lines = all_lines.select { |l| l.sku&.start_with?("ELEC-") }
      accessories_lines = all_lines.select { |l| l.sku&.start_with?("ACC-") }

      expect(clothing_lines.count).to eq(3)
      expect(electronics_lines.count).to eq(1)
      expect(accessories_lines.count).to eq(1)
    end
  end
end
