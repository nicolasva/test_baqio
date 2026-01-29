# frozen_string_literal: true

# Base model class that all application models inherit from.
# Provides shared configuration, scopes, and methods for all models.
#
# This class is marked as primary_abstract_class to indicate it's the
# base class for the application's models but doesn't map to a database table.
#
# @example Creating a model
#   class Order < ApplicationRecord
#     belongs_to :customer
#     has_many :order_lines
#   end
#
# @example Adding shared functionality
#   class ApplicationRecord < ActiveRecord::Base
#     primary_abstract_class
#
#     def self.recent
#       order(created_at: :desc)
#     end
#   end
#
class ApplicationRecord < ActiveRecord::Base
  # Declares this class as the primary abstract class for the application.
  # Prevents ActiveRecord from looking for an "application_records" table.
  primary_abstract_class
end
