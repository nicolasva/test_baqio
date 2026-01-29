class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.text :address

      t.references :account, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_index :customers, :email
  end
end
