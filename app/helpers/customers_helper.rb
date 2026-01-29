# frozen_string_literal: true

module CustomersHelper
  # Returns a mailto link for the customer's email.
  #
  # @param customer [Customer] the customer record
  # @return [String, nil] HTML mailto link or nil if no email
  def customer_email_link(customer)
    return nil unless customer.email.present?

    mail_to(customer.email)
  end

  # Returns a tel: link for the customer's phone.
  #
  # @param customer [Customer] the customer record
  # @return [String, nil] HTML phone link or nil if no phone
  def customer_phone_link(customer)
    return nil unless customer.phone.present?

    link_to(customer.phone, "tel:#{customer.phone}")
  end

  # Returns the address with line breaks preserved.
  #
  # @param customer [Customer] the customer record
  # @return [String, nil] HTML formatted address or nil if no address
  def customer_address_formatted(customer)
    return nil unless customer.address.present?

    simple_format(customer.address)
  end
end
