class Selection < ActiveRecord::Base
  attr_accessible :archived, :is_default, :is_system, :name, :parent_id, :position_value, :system_code

  selectable
end
