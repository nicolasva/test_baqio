class CreateAccountEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :account_events do |t|
      t.string :event_type, null: false
      t.text :payload

      t.references :account, foreign_key: true, null: false, index: true
      t.references :resource, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_index :account_events, :event_type
  end
end
