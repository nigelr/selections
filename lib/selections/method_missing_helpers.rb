module Selections
  module MethodMissingHelpers
    def self.add_method_missing_methods(current_class)
      current_class.class_eval do
        def respond_to_missing?(method_name, include_private = false)
          predicate_method?(method_name) || super
        end

        def method_missing(method, *args, &block)
          if predicate_method?(method)
            predicate_method(method)
          else
            super
          end
        end

        def predicate_method?(method)
          method[-1] == '?' && self.class.reflect_on_all_associations.any? do |relationship|
            if ActiveRecord::VERSION::MAJOR > 4 || relationship.macro == :belongs_to
              relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
            else
              relationship.options[:class_name] == self.class.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
            end
          end
        end

        def predicate_method(method)
          method[-1] == '?' && self.class.reflect_on_all_associations.each do |relationship|
            if ActiveRecord::VERSION::MAJOR > 4 || relationship.macro == :belongs_to
              if relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
                selection = Selection.find_by_system_code(method.to_s.gsub('?', '').singularize) || Selection.find_by_system_code("#{self.class.name.downcase}_#{method}".gsub('?', '').singularize)

                return Array(self.send(relationship.name.to_s)).map(&:id).include?(selection.try(:id))
              end
            else
              if relationship.options[:class_name] == self.class.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
                selection = Selection.find_by_system_code(method.to_s.gsub('?', '').singularize) || Selection.find_by_system_code("#{self.class.name.downcase}_#{method}".gsub('?', '').singularize)

                return Array(self.send(relationship.name.to_s)).map(&:id).include?(selection.try(:id))
              end
            end
          end

          return false
        end

        private :predicate_method?, :predicate_method
      end

      current_class.instance_eval do
        def respond_to_missing?(method_name, include_private = false)
          scope_method?(method_name) || super
        end

        def method_missing(method, *args, &block)
          if scope_method?(method)
            scope_method(method)
          else
            super
          end
        end

        def scope_method?(method)
          self.reflect_on_all_associations.any? do |relationship|
            if ActiveRecord::VERSION::MAJOR > 4 || relationship.macro == :belongs_to
              relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
            else
              relationship.options[:class_name] == self.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
            end
          end
        end

        def scope_method(method)
          self.reflect_on_all_associations.each do |relationship|
            if ActiveRecord::VERSION::MAJOR > 4 || relationship.macro == :belongs_to
              if relationship.options[:class_name] == 'Selection' && method.to_s.starts_with?(relationship.name.to_s.singularize)
                selection = Selection.find_by_system_code(method.to_s.singularize) || Selection.find_by_system_code("#{self.name.downcase}_#{method}".singularize)

                if relationship.macro == :belongs_to
                  return self.where("#{relationship.name}_id = ?", selection.try(:id))
                else
                  return self.where("#{relationship.name.to_s.singularize}_ids LIKE ?", "%#{selection.try(:id)}%")
                end
              end
            else
              if relationship.options[:class_name] == self.name && method.to_s.starts_with?(relationship.name.to_s.singularize)
                selection = Selection.find_by_system_code(method.to_s.singularize) || Selection.find_by_system_code("#{self.name.downcase}_#{method}".singularize)

                return self.where("#{relationship.name.to_s.singularize}_ids LIKE ?", "%#{selection.try(:id)}%")
              end
            end

            return []
          end
        end
      end
    end
  end
end
