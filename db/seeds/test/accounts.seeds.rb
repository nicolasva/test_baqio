# frozen_string_literal: true

# Test accounts seed
# Minimal data for testing

puts "Seeding test accounts..."

Account.find_or_create_by!(name: "Test Account")

puts "  -> #{Account.count} test accounts created"
