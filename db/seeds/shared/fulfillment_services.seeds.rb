# frozen_string_literal: true

# Shared fulfillment services seeds
# These are common carriers used across all environments

after "development:01_accounts" do
  puts "Seeding fulfillment services..."

  Account.find_each do |account|
    fulfillment_services = [
      { name: "Colissimo", provider: "colissimo" },
      { name: "Chronopost", provider: "chronopost" },
      { name: "DHL Express", provider: "dhl" },
      { name: "UPS", provider: "ups" },
      { name: "FedEx", provider: "fedex" },
      { name: "GLS", provider: "gls" },
      { name: "TNT", provider: "tnt" },
      { name: "Mondial Relay", provider: "mondial_relay" }
    ]

    fulfillment_services.each do |service_attrs|
      FulfillmentService.find_or_create_by!(
        account: account,
        name: service_attrs[:name]
      ) do |service|
        service.provider = service_attrs[:provider]
        service.active = true
      end
    end
  end

  puts "  -> #{FulfillmentService.count} fulfillment services created"
end
