require 'selections'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Migration.create_table :selections do |t|
  t.string :name
  t.string :system_code
  t.integer :parent_id
  t.datetime :archived_at
  t.integer :position_value
  t.boolean :is_default
  t.timestamps
end
ActiveRecord::Base.send(:include, ActsAsTree)

class Selection < ActiveRecord::Base
  selectable
end

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

