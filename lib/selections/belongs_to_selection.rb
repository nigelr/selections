module Selections
  module BelongsToSelection

    # Helper for belongs_to and accepts all the standard rails options
    #
    #Example
    #   belongs_to_selection :priority
    #
    # by default adds - class_name: "Selection"

    def belongs_to_selection(target, options={})
      belongs_to target, options.merge(:class_name => "Selection")
    end

    ActiveSupport.on_load :active_record do
      extend Selections::BelongsToSelection
    end

  end
end