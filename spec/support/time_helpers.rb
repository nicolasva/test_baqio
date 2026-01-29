# frozen_string_literal: true

# Time Helpers Configuration
# ==========================
# Includes ActiveSupport::Testing::TimeHelpers in RSpec tests.
#
# Provides methods for time travel in tests:
# - travel_to(time) - freezes time at a specific point
# - travel(duration) - moves time forward by duration
# - freeze_time - freezes time at current moment
# - unfreeze_time - restores normal time
#

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
