class CreateFulfillmentServices < ActiveRecord::Migration[8.1]
  def change
    create_table :fulfillment_services do |t|
      t.string :name, null: false
      t.string :provider
      t.boolean :active, default: true, null: false

      t.references :account, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
