class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :reference, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :total_amount, precision: 10, scale: 2
      t.text :notes

      t.references :account, foreign_key: true, null: false, index: true
      t.references :customer, foreign_key: true, null: false, index: true
      t.references :fulfillment, foreign_key: true, null: true, index: true

      t.timestamps
    end

    add_index :orders, :reference, unique: true
    add_index :orders, :status
  end
end
