class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string :name, null: false
      t.string :resource_type, null: false

      t.timestamps
    end

    add_index :resources, :resource_type
  end
end
