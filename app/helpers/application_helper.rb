# frozen_string_literal: true

# Base helper module available to all views in the application.
# Define shared view helper methods here that can be used across
# all templates, partials, and layouts.
#
# @example Adding a helper method
#   module ApplicationHelper
#     def format_date(date)
#       date&.strftime("%B %d, %Y")
#     end
#   end
#
# @example Using in a view
#   <%= format_date(@order.created_at) %>
#
module ApplicationHelper
  # Renders a status badge span tag.
  # Works with any decorated record that provides status_name and status_badge.
  #
  # @param name [String] the human-readable status label
  # @param badge_class [String] the CSS badge class (e.g. "badge-warning")
  # @return [String] HTML span with badge styling
  def status_badge_tag(name, badge_class)
    content_tag(:span, name, class: "badge #{badge_class}")
  end
end
