class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.string :number, null: false
      t.string :status, null: false, default: 'draft'
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.date :issued_at
      t.date :due_at
      t.date :paid_at

      t.references :order, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_index :invoices, :number, unique: true
    add_index :invoices, :status
  end
end
