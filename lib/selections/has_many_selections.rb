module Selections
  module HasManySelections

    # Helper for has_many and accepts all the standard rails options
    #
    # Example
    #   class Thing < ActiveRecord::Base
    #     has_many_selections :priority
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
    def has_many_selections(target, options = {})
      system_code = options[:system_code]
      predicates = !!options[:predicates]
      scopes = !!options[:scopes]
      target_id = "#{target.to_s.singularize}_ids".to_sym

      if ActiveRecord::VERSION::MAJOR > 4
        has_many target, options.reject { |k, v| [:system_code, :scopes, :predicates].include?(k) }.merge(class_name: 'Selection', primary_key: target_id, foreign_key: :id)
      else
        has_many target, options.reject { |k, v| [:system_code, :scopes, :predicates].include?(k) }.merge(class_name: self.name, primary_key: target_id, foreign_key: :id)
      end

      # The "selections" table may not exist during certain rake scenarios such as db:migrate or db:reset.
      ActiveRecord::Base.connection_pool.with_connection(&:active?) rescue return
      if ActiveRecord::VERSION::MAJOR > 4
        table_exists = ActiveRecord::Base.connection.data_source_exists?(Selection.table_name)
      else
        table_exists = ActiveRecord::Base.connection.table_exists?(Selection.table_name)
      end

      if table_exists
        prefix = self.name.downcase
        parent = Selection.where(system_code: system_code).first || Selection.where(system_code: "#{prefix}_#{target.to_s.singularize}").first || Selection.where(system_code: target.to_s.singularize).first
        if parent
          parent.children.each do |s|
            if predicates
              if system_code
                method_name = "#{target.to_s.singularize}_#{s.system_code.to_s.gsub("#{target.to_s.singularize}_", '')}?".to_sym
              else
                method_name = "#{s.system_code.to_s}?".to_sym
              end
              class_eval do
                define_method method_name do
                  Array(self[target_id]).map(&:to_s).include?(s.id.to_s)
                end
              end

              if scopes
                if system_code
                  scope_name = "#{target.to_s.singularize}_#{s.system_code.to_s.gsub("#{target.to_s.singularize}_", '')}".pluralize.to_sym
                else
                  scope_name = "#{s.system_code.to_s}".pluralize.to_sym
                end

                if ActiveRecord::VERSION::MAJOR >= 4
                  scope scope_name, -> { where("#{target_id} LIKE ?", "%#{s.id}%") }
                else
                  scope(scope_name, where("#{target_id} LIKE ?", "%#{s.id}%"))
                end
              end
            end
          end
        end

        class_eval do
          define_method "#{target.to_s.singularize}_names" do
            Selection.where(id: Array(self[target_id]).reject(&:blank?)).map(&:name).join(', ')
          end

          define_method "#{target_id}=" do |values|
            if ActiveRecord::VERSION::MAJOR > 4
              self[target_id] = values
            else
              self[target_id] = values.join(',')
            end
          end
        end

        class_eval do
          def respond_to_missing?(method_name, include_private = false)
            predicate_method?(method_name) || super
          end

          def method_missing(method, *args, &block)
            if predicate_method?(method)
              false
            else
              super
            end
          end

          def predicate_method?(method)
            method[-1] == '?' && self.class.reflect_on_all_associations.any? do |relationship|
              if ActiveRecord::VERSION::MAJOR > 4
                relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
              else
                relationship.options[:class_name] == self.class.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
              end
            end
          end

          private :predicate_method?
        end

        instance_eval do
          def respond_to_missing?(method_name, include_private = false)
            scope_method?(method_name) || super
          end

          def method_missing(method, *args, &block)
            if scope_method?(method)
              []
            else
              super
            end
          end

          def scope_method?(method)
            self.reflect_on_all_associations.any? do |relationship|
              if ActiveRecord::VERSION::MAJOR > 4
                relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
              else
                relationship.options[:class_name] == self.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
              end
            end
          end
        end
      end
    end

    ActiveSupport.on_load :active_record do
      extend Selections::HasManySelections
    end
  end
end
