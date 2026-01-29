# frozen_string_literal: true

# Development orders seed

after "development:02_customers", "shared:fulfillment_services" do
  puts "Seeding orders..."

  Faker::Config.locale = "fr"

  demo_account = Account.find_by!(name: "Baqio Demo")
  customers = demo_account.customers.to_a
  fulfillment_services = demo_account.fulfillment_services.to_a

  # Generate realistic product catalog
  categories = {
    clothing: {
      prefix: "VET",
      items: [
        "T-shirt", "Polo", "Chemise", "Pull", "Sweat", "Veste", "Manteau",
        "Jean", "Pantalon", "Short", "Jupe", "Robe"
      ],
      price_range: 19.99..199.99
    },
    shoes: {
      prefix: "CHS",
      items: [
        "Baskets", "Mocassins", "Bottes", "Sandales", "Escarpins", "Derbies"
      ],
      price_range: 49.99..249.99
    },
    accessories: {
      prefix: "ACC",
      items: [
        "Ceinture", "Écharpe", "Bonnet", "Casquette", "Sac", "Portefeuille",
        "Montre", "Lunettes", "Bijoux", "Cravate"
      ],
      price_range: 14.99..149.99
    }
  }

  def generate_product(categories)
    category_key = categories.keys.sample
    category = categories[category_key]
    item = category[:items].sample
    color = Faker::Color.color_name.capitalize
    sku = "#{category[:prefix]}-#{Faker::Alphanumeric.alphanumeric(number: 6).upcase}"
    price = Faker::Commerce.price(range: category[:price_range])

    {
      name: "#{item} #{color}",
      sku: sku,
      unit_price: price.round(2)
    }
  end

  statuses = {
    "pending" => 0.15,
    "validated" => 0.25,
    "invoiced" => 0.50,
    "cancelled" => 0.10
  }

  100.times do
    customer = customers.sample
    created_at = Faker::Time.backward(days: 180)

    # Weighted random status selection
    rand_val = rand
    cumulative = 0
    status = statuses.find { |_, weight| (cumulative += weight) > rand_val }&.first || "pending"

    order = Order.create!(
      account: demo_account,
      customer: customer,
      reference: "ORD-#{created_at.strftime('%Y%m%d')}-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}",
      status: "pending",
      total_amount: 0,
      created_at: created_at,
      updated_at: created_at
    )

    # Add 1-6 order lines
    line_count = Faker::Number.between(from: 1, to: 6)
    total = 0

    line_count.times do
      product = generate_product(categories)
      quantity = Faker::Number.between(from: 1, to: 4)
      line_total = (product[:unit_price] * quantity).round(2)
      total += line_total

      OrderLine.create!(
        order: order,
        name: product[:name],
        sku: product[:sku],
        quantity: quantity,
        unit_price: product[:unit_price],
        total_price: line_total
      )
    end

    order.update!(total_amount: total.round(2))

    # Update status based on selection
    case status
    when "validated"
      order.update!(status: "validated")
    when "invoiced"
      order.update!(status: "validated")

      invoice_status = Faker::Base.sample(%w[draft sent sent sent paid paid paid])
      issued_at = created_at + Faker::Number.between(from: 1, to: 3).days
      due_at = issued_at + 30.days
      paid_at = invoice_status == "paid" ? issued_at + Faker::Number.between(from: 5, to: 25).days : nil

      Invoice.create!(
        order: order,
        number: "FAC-#{created_at.strftime('%Y%m%d')}-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}",
        status: invoice_status,
        amount: total.round(2),
        tax_amount: (total * 0.2).round(2),
        total_amount: (total * 1.2).round(2),
        issued_at: issued_at,
        due_at: due_at,
        paid_at: paid_at
      )
      order.update!(status: "invoiced")
    when "cancelled"
      order.update!(status: "cancelled")
    end

    # Add fulfillment for validated/invoiced orders (80% chance)
    if %w[validated invoiced].include?(order.status) && Faker::Boolean.boolean(true_ratio: 0.8)
      fulfillment_service = fulfillment_services.sample
      fulfillment_status = Faker::Base.sample(%w[pending processing shipped shipped shipped delivered delivered])

      fulfillment = Fulfillment.create!(
        fulfillment_service: fulfillment_service,
        status: "pending"
      )

      tracking_number = "#{fulfillment_service.provider.to_s.upcase}#{Faker::Number.number(digits: 12)}"

      case fulfillment_status
      when "processing"
        fulfillment.update!(status: "processing")
      when "shipped"
        shipped_at = created_at + Faker::Number.between(from: 1, to: 4).days
        fulfillment.update!(
          status: "shipped",
          tracking_number: tracking_number,
          carrier: fulfillment_service.name,
          shipped_at: shipped_at
        )
      when "delivered"
        shipped_at = created_at + Faker::Number.between(from: 1, to: 3).days
        delivered_at = shipped_at + Faker::Number.between(from: 1, to: 5).days

        fulfillment.update!(
          status: "shipped",
          tracking_number: tracking_number,
          carrier: fulfillment_service.name,
          shipped_at: shipped_at
        )
        fulfillment.update!(
          status: "delivered",
          delivered_at: delivered_at
        )
      end

      order.update!(fulfillment: fulfillment)
    end
  end

  puts "  -> #{Order.count} orders created"
  puts "  -> #{OrderLine.count} order lines created"
  puts "  -> #{Invoice.count} invoices created"
  puts "  -> #{Fulfillment.count} fulfillments created"
end
