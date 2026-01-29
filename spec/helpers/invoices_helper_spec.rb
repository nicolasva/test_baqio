# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicesHelper, type: :helper do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:order) { create(:order, account: account, customer: customer) }
  let(:invoice) { create(:invoice, order: order, status: "draft", amount: 100.0, tax_amount: 20.0) }

  describe "#due_status" do
    context "when invoice is draft" do
      it "returns nil" do
        expect(helper.due_status(invoice)).to be_nil
      end
    end

    context "when invoice is sent and overdue" do
      before { invoice.update!(status: "sent", issued_at: 45.days.ago, due_at: 15.days.ago) }

      it "returns overdue message with danger class" do
        result = helper.due_status(invoice)
        expect(result).to have_css("span.text-danger", text: /Overdue/)
      end

      it "includes the number of days overdue" do
        result = helper.due_status(invoice)
        expect(result.to_s).to include("#{invoice.days_overdue} days")
      end
    end

    context "when invoice is sent and due soon" do
      before { invoice.update!(status: "sent", issued_at: 25.days.ago, due_at: 5.days.from_now) }

      it "returns due soon message with warning class" do
        result = helper.due_status(invoice)
        expect(result).to have_css("span.text-warning", text: /Due soon/)
      end
    end

    context "when invoice is sent with due date far away" do
      before { invoice.update!(status: "sent", issued_at: 2.days.ago, due_at: 20.days.from_now) }

      it "returns days remaining with muted class" do
        result = helper.due_status(invoice)
        expect(result).to have_css("span.text-muted", text: /days remaining/)
      end
    end

    context "when invoice has no due date" do
      before { invoice.update!(status: "sent", issued_at: Date.current, due_at: nil) }

      it "returns nil" do
        expect(helper.due_status(invoice)).to be_nil
      end
    end
  end
end
