# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#status_badge_tag" do
    it "renders a span with badge classes" do
      result = helper.status_badge_tag("Pending", "badge-warning")
      expect(result).to have_css("span.badge.badge-warning", text: "Pending")
    end

    it "renders different status names and classes" do
      result = helper.status_badge_tag("Paid", "badge-success")
      expect(result).to have_css("span.badge.badge-success", text: "Paid")
    end
  end
end
