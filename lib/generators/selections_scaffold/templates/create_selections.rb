class CreateSelections < ActiveRecord::Migration
  def change
    create_table :selections do |t|
      t.string :name
      t.integer :parent_id
      t.string :system_code
      t.integer :position_value
      t.boolean :is_default
      t.boolean :is_system
      t.datetime :archived_at

      t.timestamps
    end
  end
end
