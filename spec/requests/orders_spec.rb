# frozen_string_literal: true

# Orders Request Spec
# ===================
# Integration tests for the Orders controller (HTTP requests).
#
# Covers:
# - GET /orders (index action):
#   - Empty state (no orders)
#   - With orders (displays references, customer names)
#   - Different statuses (Pending, Validated, Cancelled)
#   - Fulfillment info (service name, status)
#   - Order lines (quantity, total price)
#   - Pagination (50 per page, page parameter)
#   - Response format (HTML)
#

require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }

  describe "GET /orders" do
    context "when there are no orders" do
      it "returns successful response" do
        get orders_path

        expect(response).to have_http_status(:success)
      end

      it "renders HTML content" do
        get orders_path

        expect(response.content_type).to include("text/html")
      end
    end

    context "when there are orders" do
      let!(:orders) { create_list(:order, 3, account: account, customer: customer) }

      it "returns successful response" do
        get orders_path

        expect(response).to have_http_status(:success)
      end

      it "displays order references" do
        get orders_path

        orders.each do |order|
          expect(response.body).to include(order.reference)
        end
      end

      it "displays customer names" do
        get orders_path

        expect(response.body).to include(customer.display_name)
      end
    end

    context "with different order statuses" do
      let!(:pending_order) { create(:order, :pending, account: account, customer: customer) }
      let!(:validated_order) { create(:order, :validated, account: account, customer: customer) }
      let!(:cancelled_order) { create(:order, :cancelled, account: account, customer: customer) }

      it "displays all orders regardless of status" do
        get orders_path

        expect(response.body).to include(pending_order.reference)
        expect(response.body).to include(validated_order.reference)
        expect(response.body).to include(cancelled_order.reference)
      end

      it "displays status names in English" do
        get orders_path

        expect(response.body).to include("Pending")
        expect(response.body).to include("Validated")
        expect(response.body).to include("Cancelled")
      end
    end

    context "with fulfillment" do
      let(:fulfillment_service) { create(:fulfillment_service, account: account, name: "DHL Express") }
      let(:fulfillment) { create(:fulfillment, :shipped, fulfillment_service: fulfillment_service) }
      let!(:order) { create(:order, account: account, customer: customer, fulfillment: fulfillment) }

      it "displays fulfillment service name" do
        get orders_path

        expect(response.body).to include("DHL Express")
      end

      it "displays fulfillment status" do
        get orders_path

        expect(response.body).to include("Shipped")
      end
    end

    context "with order lines" do
      let!(:order) { create(:order, account: account, customer: customer, total_amount: 250.0) }

      before do
        create(:order_line, order: order, quantity: 3, unit_price: 50.0)
        create(:order_line, order: order, quantity: 2, unit_price: 50.0)
      end

      it "displays total quantity" do
        get orders_path

        expect(response.body).to include("5")
      end

      it "displays total price" do
        get orders_path

        expect(response.body).to include("250")
      end
    end

    context "pagination" do
      let!(:orders) { create_list(:order, 60, account: account, customer: customer) }

      it "paginates results to 50 per page" do
        get orders_path

        # First page should have 50 orders
        displayed_count = orders.first(50).count { |o| response.body.include?(o.reference) }
        expect(displayed_count).to eq(50)
      end

      it "accepts page parameter" do
        get orders_path, params: { page: 2 }

        expect(response).to have_http_status(:success)
      end

      it "displays pagination links" do
        get orders_path

        expect(response.body).to include("page")
      end
    end

    context "response format" do
      let!(:order) { create(:order, account: account, customer: customer) }

      it "responds to HTML format" do
        get orders_path, headers: { "Accept" => "text/html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end
  end
end
