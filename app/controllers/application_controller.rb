# frozen_string_literal: true

# Base controller that all application controllers inherit from.
# Provides shared configuration, filters, and helper methods.
#
# Rails 8 features enabled:
# - Modern browser enforcement for progressive enhancement
# - Import map ETag invalidation for proper caching
#
# @example Adding shared functionality
#   class ApplicationController < ActionController::Base
#     before_action :authenticate_user!
#     helper_method :current_user
#   end
#
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push,
  # badges, import maps, CSS nesting, and CSS :has.
  # Returns a 406 Not Acceptable for unsupported browsers.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the ETag for HTML responses.
  # Ensures browsers fetch new JavaScript when import map changes.
  stale_when_importmap_changes
end
