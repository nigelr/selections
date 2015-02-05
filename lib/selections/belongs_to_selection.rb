module Selections
  module BelongsToSelection

    # Helper for belongs_to and accepts all the standard rails options
    #
    # Example
    #   class Thing < ActiveRecord::Base
    #     belongs_to_selection :priority
    #
    # by default adds - class_name: "Selection"
    #
    # This macro also adds a number of methods onto the class if there is a selection
    # named as the class underscore name (eg: "thing_priority"), then methods are created
    # for all of the selection values under that parent. For example:
    #
    #   thing = Thing.find(x)
    #   thing.priority = Selection.thing_priority_high
    #   thing.priority_high? #=> true
    #   thing.priority_low?  #=> false
    #
    # thing.priority_high? is equivalent to thing.priority == Selection.thing_priority_high
    # except that the id of the selection is cached at the time the class is loaded.
    #
    # Note that this is only appropriate to use for system selection values that are known
    # at development time, and not to values that the users can edit in the live system.
    def belongs_to_selection(target, options={})
      belongs_to target, options.merge(:class_name => "Selection")

      # The "selections" table may not exist during certain rake scenarios such as db:migrate or db:reset.
      if ActiveRecord::Base.connection.table_exists? Selection.table_name
        prefix = self.name.downcase
        parent = Selection.where(system_code: "#{prefix}_#{target}").first
        if parent
          target_id = "#{target}_id".to_sym
          parent.children.each do |s|
            method_name = "#{s.system_code.sub("#{prefix}_", '')}?".to_sym
            class_eval do
              define_method method_name do
                send(target_id) == s.id
              end
            end
          end
        end
      end
    end

    ActiveSupport.on_load :active_record do
      extend Selections::BelongsToSelection
    end

  end
end
