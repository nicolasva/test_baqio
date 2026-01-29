# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_28_145804) do
  create_table "account_events", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "payload"
    t.integer "resource_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_events_on_account_id"
    t.index ["event_type"], name: "index_account_events_on_event_type"
    t.index ["resource_id"], name: "index_account_events_on_resource_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_accounts_on_name"
  end

  create_table "customers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_customers_on_account_id"
    t.index ["email"], name: "index_customers_on_email"
  end

  create_table "fulfillment_services", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "provider"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_fulfillment_services_on_account_id"
  end

  create_table "fulfillments", force: :cascade do |t|
    t.string "carrier"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.integer "fulfillment_service_id", null: false
    t.datetime "shipped_at"
    t.string "status", default: "pending", null: false
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.index ["fulfillment_service_id"], name: "index_fulfillments_on_fulfillment_service_id"
    t.index ["status"], name: "index_fulfillments_on_status"
    t.index ["tracking_number"], name: "index_fulfillments_on_tracking_number"
  end

  create_table "invoices", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_at"
    t.date "issued_at"
    t.string "number", null: false
    t.integer "order_id", null: false
    t.date "paid_at"
    t.string "status", default: "draft", null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["order_id"], name: "index_invoices_on_order_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.string "sku"
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["sku"], name: "index_order_lines_on_sku"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.integer "fulfillment_id"
    t.text "notes"
    t.string "reference", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["fulfillment_id"], name: "index_orders_on_fulfillment_id"
    t.index ["reference"], name: "index_orders_on_reference", unique: true
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type"], name: "index_resources_on_resource_type"
  end

  add_foreign_key "account_events", "accounts"
  add_foreign_key "account_events", "resources"
  add_foreign_key "customers", "accounts"
  add_foreign_key "fulfillment_services", "accounts"
  add_foreign_key "fulfillments", "fulfillment_services"
  add_foreign_key "invoices", "orders"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "fulfillments"
end
