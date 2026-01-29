# frozen_string_literal: true

# Base query class that all query objects inherit from.
# Query Objects encapsulate complex database queries, making them
# reusable, testable, and keeping models focused on domain logic.
#
# Each query object operates on an ActiveRecord relation and returns
# a modified relation or computed results.
#
# @example Creating a query object
#   class Orders::FilterQuery < ApplicationQuery
#     def initialize(relation = default_relation, filters: {})
#       super(relation)
#       @filters = filters
#     end
#
#     def call
#       relation.where(status: @filters[:status])
#     end
#
#     private
#
#     def default_relation
#       Order.all
#     end
#   end
#
# @example Using a query object
#   Orders::FilterQuery.call(filters: { status: "pending" })
#   Orders::FilterQuery.new(Order.recent, filters: { status: "pending" }).call
#
class ApplicationQuery
  # @return [ActiveRecord::Relation] the base relation being queried
  attr_reader :relation

  # Initializes the query with a base relation.
  #
  # @param relation [ActiveRecord::Relation] the starting relation
  #   Defaults to the query's default_relation if not provided
  def initialize(relation = default_relation)
    @relation = relation
  end

  # Executes the query and returns the result.
  # Must be implemented by subclasses.
  #
  # @return [ActiveRecord::Relation] the filtered/modified relation
  # @raise [NotImplementedError] if subclass doesn't implement this method
  def call
    raise NotImplementedError, "Subclasses must implement #call"
  end

  # Class method shorthand for instantiating and calling the query.
  # Allows chaining queries: Orders::FilterQuery.call(filters: {})
  #
  # @param args [Array] arguments passed to initialize
  # @return [ActiveRecord::Relation] the query result
  def self.call(...)
    new(...).call
  end

  private

  # Returns the default relation when none is provided.
  # Must be implemented by subclasses.
  #
  # @return [ActiveRecord::Relation] the base relation for this query
  # @raise [NotImplementedError] if subclass doesn't implement this method
  def default_relation
    raise NotImplementedError, "Subclasses must implement #default_relation"
  end
end
