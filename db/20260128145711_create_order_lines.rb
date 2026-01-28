class CreateOrderLines < ActiveRecord::Migration[8.1]
  def change
    create_table :order_lines do |t|
      t.string :name, null: false
      t.string :sku
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false

      t.references :order, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_index :order_lines, :sku
  end
end
