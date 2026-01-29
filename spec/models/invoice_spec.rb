# frozen_string_literal: true

# Invoice Model Spec
# ==================
# Tests for the Invoice model.
#
# Covers:
# - Factory validation (basic creation, traits)
# - Status values (draft, sent, paid, cancelled)
# - Validations (number uniqueness, amount required, status required)
# - Associations (order, delegated account and customer)
# - Scopes (recent, overdue, due_soon, by status)
# - Callbacks (total_amount calculation, number generation)
# - State transitions (send_to_customer!, mark_as_paid!, cancel!)
# - Instance methods (overdue?, days_until_due, days_overdue)
#

require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "Test data creation" do
    it "can create a valid invoice for testing" do
      invoice = build(:invoice)
      expect(invoice).to be_valid
    end

    it "can create an invoice that has been sent to the customer" do
      invoice = build(:invoice, :sent)
      expect(invoice.status).to eq("sent")
      expect(invoice.issued_at).to be_present
      expect(invoice.due_at).to be_present
    end

    it "can create a paid invoice" do
      invoice = build(:invoice, :paid)
      expect(invoice.status).to eq("paid")
      expect(invoice.paid_at).to be_present
    end

    it "can create an overdue invoice (past due date)" do
      invoice = build(:invoice, :overdue)
      expect(invoice.status).to eq("sent")
      expect(invoice.due_at).to be < Date.current
    end
  end

  describe "Allowed status values" do
    it "only allows: draft, sent, paid, or cancelled" do
      expect(Invoice::STATUSES).to eq(%w[draft sent paid cancelled])
    end
  end

  describe "Data validation rules" do
    describe "Invoice number" do
      it "automatically generates a number when none is provided" do
        invoice = build(:invoice, number: nil)
        invoice.valid?
        expect(invoice.number).to be_present
      end

      it "requires an invoice number" do
        invoice = build(:invoice)
        invoice.number = nil
        # Skip callbacks to test validation directly
        invoice.define_singleton_method(:generate_number) { }
        expect(invoice).not_to be_valid
        expect(invoice.errors[:number]).to include("can't be blank")
      end

      it "prevents duplicate invoice numbers" do
        create(:invoice, number: "INV-001")
        duplicate = build(:invoice, number: "INV-001")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:number]).to include("has already been taken")
      end
    end

    describe "Invoice amount" do
      it "requires an amount to be set" do
        invoice = build(:invoice)
        invoice.amount = nil
        invoice.tax_amount = 0
        expect(invoice).not_to be_valid
        expect(invoice.errors[:amount]).to include("can't be blank")
      end

      it "does not allow negative amounts" do
        invoice = build(:invoice, amount: -1)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:amount]).to include("must be greater than or equal to 0")
      end

      it "allows zero amount invoices" do
        invoice = build(:invoice, amount: 0)
        expect(invoice).to be_valid
      end
    end

    describe "Invoice status" do
      it "requires a status to be set" do
        invoice = build(:invoice, status: nil)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to include("can't be blank")
      end

      it "only accepts valid status values" do
        invoice = build(:invoice, status: "invalid")
        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe "Relationships with other data" do
    it "is linked to an order" do
      order = create(:order)
      invoice = create(:invoice, order: order)
      expect(invoice.order).to eq(order)
    end

    describe "Accessing order information" do
      let(:account) { create(:account) }
      let(:customer) { create(:customer, account: account) }
      let(:order) { create(:order, account: account, customer: customer) }
      let(:invoice) { create(:invoice, order: order) }

      it "can access the account through the order" do
        expect(invoice.account).to eq(account)
      end

      it "can access the customer through the order" do
        expect(invoice.customer).to eq(customer)
      end
    end
  end

  describe "Quick filters for searching invoices" do
    describe "Recent invoices" do
      it "returns invoices from newest to oldest" do
        old_invoice = create(:invoice, created_at: 2.days.ago)
        new_invoice = create(:invoice, created_at: 1.hour.ago)

        expect(Invoice.recent.first).to eq(new_invoice)
        expect(Invoice.recent.last).to eq(old_invoice)
      end
    end

    describe "Overdue invoices" do
      it "returns only sent invoices that are past their due date" do
        overdue = create(:invoice, :overdue)
        not_overdue = create(:invoice, :sent)
        draft = create(:invoice, :draft)

        expect(Invoice.overdue).to include(overdue)
        expect(Invoice.overdue).not_to include(not_overdue, draft)
      end
    end

    describe "Invoices due soon" do
      it "returns sent invoices due within the specified number of days" do
        due_soon = create(:invoice, :due_soon)
        due_later = create(:invoice, :sent, due_at: 30.days.from_now)

        expect(Invoice.due_soon(7)).to include(due_soon)
        expect(Invoice.due_soon(7)).not_to include(due_later)
      end

      it "defaults to 7 days if not specified" do
        due_soon = create(:invoice, status: "sent", due_at: 5.days.from_now)
        expect(Invoice.due_soon).to include(due_soon)
      end
    end

    describe "Filter by status" do
      it "provides a filter for each invoice status" do
        Invoice::STATUSES.each do |status|
          expect(Invoice).to respond_to(status)
        end
      end
    end
  end

  describe "Automatic calculations when saving" do
    describe "Total amount calculation" do
      it "automatically calculates total = amount + tax" do
        invoice = build(:invoice, amount: 100.0, tax_amount: 20.0, total_amount: nil)
        invoice.valid?

        expect(invoice.total_amount).to eq(120.0)
      end

      it "handles invoices with no tax" do
        invoice = build(:invoice, amount: 100.0, tax_amount: nil, total_amount: nil)
        invoice.valid?

        expect(invoice.total_amount).to eq(100.0)
      end
    end

    describe "Invoice number generation" do
      it "auto-generates a unique invoice number on creation" do
        invoice = build(:invoice, number: nil)
        invoice.valid?

        expect(invoice.number).to be_present
        expect(invoice.number).to match(/^INV-\d{8}-[A-F0-9]{8}$/)
      end

      it "keeps the provided number if one is given" do
        invoice = build(:invoice, number: "CUSTOM-001")
        invoice.valid?

        expect(invoice.number).to eq("CUSTOM-001")
      end
    end
  end

  describe "Available actions on an invoice" do
    describe "Sending an invoice to the customer" do
      context "when the invoice is a draft" do
        let(:invoice) { create(:invoice, :draft) }

        it "changes the status to sent" do
          invoice.send_to_customer!
          expect(invoice.reload.status).to eq("sent")
        end

        it "records today as the issue date" do
          invoice.send_to_customer!
          expect(invoice.reload.issued_at).to eq(Date.current)
        end

        it "sets the due date to 30 days from now" do
          invoice.send_to_customer!
          expect(invoice.reload.due_at).to eq(Date.current + 30.days)
        end

        it "returns true to confirm success" do
          expect(invoice.send_to_customer!).to be_truthy
        end
      end

      context "when the invoice has already been sent" do
        let(:invoice) { create(:invoice, :sent) }

        it "returns false (cannot send again)" do
          expect(invoice.send_to_customer!).to be false
        end

        it "does not change the status" do
          invoice.send_to_customer!
          expect(invoice.reload.status).to eq("sent")
        end
      end
    end

    describe "Marking an invoice as paid" do
      context "when the invoice has been sent" do
        let(:invoice) { create(:invoice, :sent) }

        it "changes the status to paid" do
          invoice.mark_as_paid!
          expect(invoice.reload.status).to eq("paid")
        end

        it "records today as the payment date by default" do
          invoice.mark_as_paid!
          expect(invoice.reload.paid_at).to eq(Date.current)
        end

        it "can use a custom payment date" do
          custom_date = 5.days.ago.to_date
          invoice.mark_as_paid!(custom_date)
          expect(invoice.reload.paid_at).to eq(custom_date)
        end

        it "returns true to confirm success" do
          expect(invoice.mark_as_paid!).to be_truthy
        end
      end

      context "when the invoice is still a draft" do
        let(:invoice) { create(:invoice, :draft) }

        it "returns false (must send first)" do
          expect(invoice.mark_as_paid!).to be false
        end
      end
    end

    describe "Cancelling an invoice" do
      context "when the invoice is a draft" do
        let(:invoice) { create(:invoice, :draft) }

        it "changes the status to cancelled" do
          invoice.cancel!
          expect(invoice.reload.status).to eq("cancelled")
        end

        it "returns true to confirm success" do
          expect(invoice.cancel!).to be_truthy
        end
      end

      context "when the invoice has been sent" do
        let(:invoice) { create(:invoice, :sent) }

        it "can still be cancelled" do
          invoice.cancel!
          expect(invoice.reload.status).to eq("cancelled")
        end
      end

      context "when the invoice has been paid" do
        let(:invoice) { create(:invoice, :paid) }

        it "returns false (cannot cancel a paid invoice)" do
          expect(invoice.cancel!).to be false
        end

        it "does not change the status" do
          invoice.cancel!
          expect(invoice.reload.status).to eq("paid")
        end
      end
    end

    describe "Checking if invoice is overdue" do
      it "is overdue when sent and past due date" do
        invoice = build(:invoice, status: "sent", due_at: 1.day.ago)
        expect(invoice.overdue?).to be true
      end

      it "is not overdue when still a draft" do
        invoice = build(:invoice, status: "draft", due_at: 1.day.ago)
        expect(invoice.overdue?).to be false
      end

      it "is not overdue when there is no due date" do
        invoice = build(:invoice, status: "sent", due_at: nil)
        expect(invoice.overdue?).to be false
      end

      it "is not overdue when due date is in the future" do
        invoice = build(:invoice, status: "sent", due_at: 1.day.from_now)
        expect(invoice.overdue?).to be false
      end
    end

    describe "Calculating days until due" do
      it "returns nothing when there is no due date" do
        invoice = build(:invoice, due_at: nil)
        expect(invoice.days_until_due).to be_nil
      end

      it "returns positive number when due in the future" do
        invoice = build(:invoice, due_at: 10.days.from_now)
        expect(invoice.days_until_due).to eq(10)
      end

      it "returns negative number when overdue" do
        invoice = build(:invoice, due_at: 5.days.ago)
        expect(invoice.days_until_due).to eq(-5)
      end

      it "returns 0 when due today" do
        invoice = build(:invoice, due_at: Date.current)
        expect(invoice.days_until_due).to eq(0)
      end
    end

    describe "Calculating days overdue" do
      it "returns 0 when not overdue" do
        invoice = build(:invoice, status: "sent", due_at: 1.day.from_now)
        expect(invoice.days_overdue).to eq(0)
      end

      it "returns the number of days past due when overdue" do
        invoice = build(:invoice, status: "sent", due_at: 5.days.ago)
        expect(invoice.days_overdue).to eq(5)
      end
    end
  end
end
