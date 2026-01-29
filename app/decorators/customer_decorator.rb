# frozen_string_literal: true

# Decorator for Customer model presentation logic.
# Provides formatted display values for views.
#
# @example Using the decorator
#   customer = Customer.find(1).decorate
#   customer.display_name          # => "John Doe"
#   customer.initials              # => "JD"
#   customer.orders_count_text     # => "5 orders"
#   customer.total_spent_formatted # => "$1,234.56"
#
class CustomerDecorator < ApplicationDecorator
  # Delegate all model methods to the underlying customer
  delegate_all

  # Format total_spent as currency (creates total_spent_formatted method)
  formats_currency :total_spent

  # Create orders_count_text method that returns "X order(s)"
  pluralizes_count :orders_count, singular: "order", plural: "orders"

  # ============================================
  # Display Methods
  # ============================================

  # Returns the best available name for display.
  # Priority: full name > email > "Customer #ID"
  #
  # @return [String] display name
  def display_name
    full_name || email || "Customer ##{id}"
  end

  # Returns the customer's full name.
  # Joins first and last name with a space.
  #
  # @return [String, nil] full name or nil if both names are blank
  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end

  # Returns the customer's initials.
  # Takes the first letter of each name part.
  #
  # @return [String] initials (e.g., "JD") or "?" if no name
  def initials
    return "?" unless full_name

    full_name.split.map { |n| n[0].upcase }.join
  end

  # ============================================
  # Link Helpers
  # ============================================

  # Returns a mailto link for the customer's email.
  #
  # @return [String, nil] HTML mailto link or nil if no email
  def email_link
    return nil unless email.present?

    h.mail_to(email)
  end

  # Returns a tel: link for the customer's phone.
  #
  # @return [String, nil] HTML phone link or nil if no phone
  def phone_link
    return nil unless phone.present?

    h.link_to(phone, "tel:#{phone}")
  end

  # ============================================
  # Formatting Methods
  # ============================================

  # Returns the total spent as a formatted currency string.
  #
  # @return [String] formatted currency (e.g., "$1,234.56")
  def total_spent_formatted
    h.number_to_currency(total_spent)
  end

  # Returns the address with line breaks preserved.
  #
  # @return [String, nil] HTML formatted address or nil if no address
  def address_formatted
    return nil unless address.present?

    h.simple_format(address)
  end
end
