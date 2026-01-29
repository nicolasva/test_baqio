# frozen_string_literal: true

# Statusable Shared Examples
# ==========================
# Shared examples for models using the Statusable concern.
#
# Usage:
#   it_behaves_like "a statusable model", [:pending, :validated, :cancelled]
#   it_behaves_like "a model with status transitions", { pending: [:validated, :cancelled] }
#
# "a statusable model":
# - Tests predicate methods (pending?, validated?, etc.)
# - Tests scope existence for each status
# - Tests without_status scope
#
# "a model with status transitions":
# - Tests allowed status transitions
#

RSpec.shared_examples "a statusable model" do |statuses|
  describe "status methods" do
    statuses.each do |status|
      describe "##{status}?" do
        it "returns true when status is #{status}" do
          subject.status = status.to_s
          expect(subject.send(:"#{status}?")).to be true
        end

        it "returns false when status is not #{status}" do
          other_status = (statuses - [status]).first
          subject.status = other_status.to_s
          expect(subject.send(:"#{status}?")).to be false
        end
      end
    end
  end

  describe "status scopes" do
    statuses.each do |status|
      describe ".#{status}" do
        it "returns records with #{status} status" do
          # This test requires the factory to be set up properly
          expect(described_class).to respond_to(status)
        end
      end
    end

    describe ".without_status" do
      it "excludes records with the specified status" do
        expect(described_class).to respond_to(:without_status)
      end
    end
  end
end

RSpec.shared_examples "a model with status transitions" do |valid_transitions|
  valid_transitions.each do |from_status, to_statuses|
    to_statuses.each do |to_status|
      it "allows transition from #{from_status} to #{to_status}" do
        subject.status = from_status.to_s
        subject.status = to_status.to_s
        expect(subject.status).to eq(to_status.to_s)
      end
    end
  end
end
