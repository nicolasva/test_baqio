# frozen_string_literal: true

# Invoice Factory
# ===============
# Factory for creating Invoice records.
#
# Status traits:
# - :draft - invoice not yet sent (default)
# - :sent - invoice sent to customer, due in 30 days
# - :paid - invoice has been paid
# - :cancelled - invoice has been cancelled
#
# Due date traits:
# - :overdue - invoice past due date (10-30 days overdue)
# - :due_soon - due within 1-7 days
# - :due_today - due date is today
# - :due_tomorrow - due date is tomorrow
# - :due_in_one_week - due in 7 days
# - :significantly_overdue - 60+ days overdue
#
# Payment timing traits:
# - :paid_early - paid 15 days before due
# - :paid_late - paid after due date
# - :paid_on_time - paid just before due
#
# Amount traits:
# - :high_value - €1000-10000
# - :low_value - €10-50
# - :with_specific_amount - custom amount via transient
#
# Tax traits:
# - :no_tax / :zero_tax - no VAT
# - :reduced_tax - 5.5% reduced VAT
# - :intermediate_tax - 10% intermediate VAT
#
# Special traits:
# - :credit_note - negative amount credit note
# - :recent - issued within last 7 days
# - :old - issued 180 days ago, already paid
# - :b2b - business invoice with 45-day payment terms
# - :export - export invoice (no VAT)
# - :partial_payment - invoice for partial payment scenarios
#
# Examples:
#   create(:invoice)
#   create(:invoice, :sent)
#   create(:invoice, :overdue, amount: 500)
#   create(:invoice, :with_specific_amount, specific_amount: 1000, tax_rate: 0.1)
#

FactoryBot.define do
  factory :invoice do
    order
    number { "INV-#{Time.current.strftime('%Y%m%d')}-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    status { "draft" }
    amount { Faker::Commerce.price(range: 50..500) }
    tax_amount { (amount * 0.2).round(2) }
    # total_amount is calculated by before_validation callback
    issued_at { nil }
    due_at { nil }
    paid_at { nil }

    trait :draft do
      status { "draft" }
      issued_at { nil }
      due_at { nil }
    end

    trait :sent do
      status { "sent" }
      issued_at { Date.current }
      due_at { Date.current + 30.days }
    end

    trait :paid do
      status { "paid" }
      issued_at { Faker::Number.between(from: 15, to: 45).days.ago.to_date }
      due_at { issued_at + 30.days }
      paid_at { Faker::Date.between(from: issued_at, to: [ due_at, Date.current ].min) }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :overdue do
      status { "sent" }
      issued_at { Faker::Number.between(from: 45, to: 60).days.ago.to_date }
      due_at { Faker::Number.between(from: 10, to: 30).days.ago.to_date }
    end

    trait :due_soon do
      status { "sent" }
      issued_at { Faker::Number.between(from: 20, to: 28).days.ago.to_date }
      due_at { Faker::Number.between(from: 1, to: 7).days.from_now.to_date }
    end

    trait :due_today do
      status { "sent" }
      issued_at { 30.days.ago.to_date }
      due_at { Date.current }
    end

    trait :high_value do
      amount { Faker::Commerce.price(range: 1000..10000) }
      tax_amount { (amount * 0.2).round(2) }
    end

    trait :low_value do
      amount { Faker::Commerce.price(range: 10..50) }
      tax_amount { (amount * 0.2).round(2) }
    end

    trait :no_tax do
      tax_amount { 0 }
    end

    trait :credit_note do
      number { "CN-#{Time.current.strftime('%Y%m%d')}-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
      amount { -Faker::Commerce.price(range: 50..500) }
      tax_amount { (amount * 0.2).round(2) }
    end

    trait :recent do
      issued_at { Faker::Date.backward(days: 7) }
      due_at { issued_at + 30.days }
    end

    trait :old do
      issued_at { Faker::Date.backward(days: 180) }
      due_at { issued_at + 30.days }
      paid_at { issued_at + Faker::Number.between(from: 10, to: 25).days }
      status { "paid" }
    end

    trait :with_specific_amount do
      transient do
        specific_amount { 100.0 }
        tax_rate { 0.2 }
      end
      amount { specific_amount }
      tax_amount { (specific_amount * tax_rate).round(2) }
    end

    trait :zero_tax do
      tax_amount { 0 }
    end

    trait :reduced_tax do
      tax_amount { (amount * 0.055).round(2) } # TVA réduite 5.5%
    end

    trait :intermediate_tax do
      tax_amount { (amount * 0.10).round(2) } # TVA intermédiaire 10%
    end

    trait :paid_early do
      status { "paid" }
      issued_at { 30.days.ago.to_date }
      due_at { Date.current }
      paid_at { 15.days.ago.to_date }
    end

    trait :paid_late do
      status { "paid" }
      issued_at { 60.days.ago.to_date }
      due_at { 30.days.ago.to_date }
      paid_at { 10.days.ago.to_date }
    end

    trait :paid_on_time do
      status { "paid" }
      issued_at { 45.days.ago.to_date }
      due_at { 15.days.ago.to_date }
      paid_at { 16.days.ago.to_date }
    end

    trait :due_in_one_week do
      status { "sent" }
      issued_at { 23.days.ago.to_date }
      due_at { 7.days.from_now.to_date }
    end

    trait :due_tomorrow do
      status { "sent" }
      issued_at { 29.days.ago.to_date }
      due_at { 1.day.from_now.to_date }
    end

    trait :significantly_overdue do
      status { "sent" }
      issued_at { 90.days.ago.to_date }
      due_at { 60.days.ago.to_date }
    end

    trait :b2b do
      amount { Faker::Commerce.price(range: 1000..10000) }
      tax_amount { (amount * 0.2).round(2) }
      issued_at { Date.current }
      due_at { Date.current + 45.days } # Payment terms 45 days
    end

    trait :export do
      # Export invoice - no VAT
      amount { Faker::Commerce.price(range: 500..5000) }
      tax_amount { 0 }
    end

    trait :partial_payment do
      # Invoice that has been partially paid - would need custom handling
      status { "sent" }
      issued_at { 20.days.ago.to_date }
      due_at { 10.days.from_now.to_date }
    end

  end
end
