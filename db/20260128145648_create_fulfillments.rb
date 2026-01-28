class CreateFulfillments < ActiveRecord::Migration[8.1]
  def change
    create_table :fulfillments do |t|
      t.string :status, null: false, default: 'pending'
      t.string :tracking_number
      t.string :carrier
      t.datetime :shipped_at
      t.datetime :delivered_at

      t.references :fulfillment_service, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_index :fulfillments, :status
    add_index :fulfillments, :tracking_number
  end
end
