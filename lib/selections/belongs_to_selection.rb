module Selections
  module BelongsToSelection

    def belongs_to_selection(target, options={})
      belongs_to target, options.merge(:class_name => "Selection")
    end

    ActiveSupport.on_load :active_record do
      extend Selections::BelongsToSelection
    end

  end
end