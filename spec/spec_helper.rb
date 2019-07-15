require 'selections'
require "nokogiri"
require 'active_record/fixtures'

if ActiveRecord::VERSION::MAJOR == 3
  # Rails 3 has some big warning that prints out if this is not there, but this will break Rails 4. :(
  require 'minitest'
end

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

ActiveRecord::Migration.create_table :tickets do |t|
  t.string :name
  t.integer :parent_id
  t.integer :priority_id
  t.text :priority_ids, array: true
  t.integer :other_priority_id
  t.text :other_priority_ids, array: true
  t.timestamps
end

class Selection < ActiveRecord::Base #:nodoc:
  selectable
end

class Ticket < ActiveRecord::Base #:nodoc:

end

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

