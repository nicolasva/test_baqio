# frozen_string_literal: true

# OrderLine Factory
# =================
# Factory for creating OrderLine (line item) records.
#
# Price traits:
# - :expensive - €199.99 unit price with material name
# - :cheap - €5-20 unit price
#
# Quantity traits:
# - :single - quantity of 1
# - :bulk - quantity of 10
# - :large_quantity - quantity of 50-100 (wholesale)
#
# Product category traits:
# - :clothing - clothing items (T-shirt, Polo, etc.) with VET- SKU
# - :electronics - electronic equipment with ELEC- SKU
# - :accessories - accessories (belt, scarf, etc.) with ACC- SKU
#
# Other traits:
# - :without_sku - line without SKU code
#
# Examples:
#   create(:order_line)
#   create(:order_line, :expensive, quantity: 3)
#   create(:order_line, :clothing)
#   create(:order_line, :bulk, unit_price: 5.99)
#

FactoryBot.define do
  factory :order_line do
    order
    name { Faker::Commerce.product_name }
    sku { "SKU-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    quantity { Faker::Number.between(from: 1, to: 3) }
    unit_price { Faker::Commerce.price(range: 10..200) }
    # total_price is calculated by before_validation callback

    trait :without_sku do
      sku { nil }
    end

    trait :expensive do
      name { "#{Faker::Commerce.material} #{Faker::Commerce.product_name}" }
      unit_price { 199.99 }
    end

    trait :cheap do
      name { "Basic #{Faker::Commerce.product_name}" }
      unit_price { Faker::Commerce.price(range: 5..20) }
    end

    trait :bulk do
      quantity { 10 }
    end

    trait :single do
      quantity { 1 }
    end

    trait :large_quantity do
      quantity { Faker::Number.between(from: 50, to: 100) }
      unit_price { Faker::Commerce.price(range: 1..10) }
    end

    trait :clothing do
      name { "#{Faker::Color.color_name.capitalize} #{%w[T-shirt Polo Chemise Pull Veste Jean Pantalon].sample}" }
      sku { "VET-#{Faker::Alphanumeric.alphanumeric(number: 6).upcase}" }
      unit_price { Faker::Commerce.price(range: 19.99..149.99) }
    end

    trait :electronics do
      name { Faker::Appliance.equipment }
      sku { "ELEC-#{Faker::Alphanumeric.alphanumeric(number: 6).upcase}" }
      unit_price { Faker::Commerce.price(range: 49.99..999.99) }
    end

    trait :accessories do
      name { %w[Ceinture Écharpe Bonnet Casquette Sac Portefeuille Montre Lunettes].sample }
      sku { "ACC-#{Faker::Alphanumeric.alphanumeric(number: 6).upcase}" }
      unit_price { Faker::Commerce.price(range: 14.99..99.99) }
    end
  end
end
