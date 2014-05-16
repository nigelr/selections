require 'acts_as_tree'

module Selections
  module Selectable

    module ModelMixin
      extend ActiveSupport::Concern

      HIDDEN_POSITION = 999888777 #:nodoc:

      included do
        # Setup any required model information for a selectable model.
        acts_as_tree

        validate :name, existence: true
        validates_presence_of :name
        validates_uniqueness_of :name, scope: :parent_id
        validates_uniqueness_of :system_code, scope: :archived_at
        validates_format_of :system_code, :with => /\A[a-z][a-zA-Z_0-9]*\Z/, :message => "can only contain alphanumeric characters and '_', not spaces"

        before_validation :auto_gen_system_code, on: :create
        before_validation :disable_system_code_change, on: :update
        after_validation :check_defaults

        default_scope { order([:position_value, :name]) }

        scope :filter_archived_except_selected, lambda { |selected_id| where(["archived_at is ? or id = ?", nil, selected_id.to_i]) }
      end

      module ClassMethods
        # Dynamic Lookups
        #
        # Assuming there is a list with the following system_codes
        #
        # example of a nested list of system codes:
        # * priority
        # * - high
        # * - medium
        # * - low
        #
        # Selection.priority => return priority instance
        #
        # Selection.priorities => returns [high, medium, low] instances (children)

        def method_missing lookup_code, *options
          if (scope = where(system_code: lookup_code.to_s)).exists?
            scope.first
          elsif (scope = where(system_code: lookup_code.to_s.singularize)).exists?
            scope.first.children
          else
            super
          end
        end

        # label_to_id
        #
        # When using fixtures with the label same as the system_code, use this method to return the ID of the of the fixture
        # and use this in Factories instead of using a lookup as it does not need a DB search.
        #
        # eg:
        # Fixture File
        #----------------------------------------
        # priority_high:
        #   name: Priorities
        #   system_code: priority_high
        #   parent: priority
        #----------------------------------------
        #
        # in Factory
        # ---------------------------------------
        # priority: { Selection.priority_high }     <== Don't do this as it will need a DB lookup
        #
        # priority_id: { Selection.label_to_id(:priority_high) }    <== This will be much quicker
        #
        def label_to_id(label)
          # ActiveRecord::FixtureSet replaces ActiveRecord::Fixtures in Rails 4
          # This helps to ensure backwards compatibility
          if ActiveRecord::VERSION::MAJOR >= 4
            ActiveRecord::FixtureSet.identify(label)
          else
            ActiveRecord::Fixtures.identify(label)
          end
        end
      end


      def to_s #:nodoc:
        name.to_s
      end

      # Returns boolean true if current node has no children
      def leaf?
        children.where(parent_id: self.id).empty?
      end

      # Returns childrens children from root or any point
      def level_2
        Selection.where(parent_id: child_ids)
      end

      def position=(value) #:nodoc:
        self.position_value = value || HIDDEN_POSITION
      end

      def disable_system_code_change #:nodoc:
        errors.add(:system_code, "cannot be changed") if system_code_changed?
      end

      def position #:nodoc:
        position_value unless position_value == HIDDEN_POSITION
      end

      def auto_gen_system_code #:nodoc:
        unless system_code
          self.system_code= name.to_s.underscore.split(" ").join("_").singularize.underscore.gsub(/\W/, "_")
          self.system_code= parent.system_code + "_" + self.system_code if parent
          self.system_code.gsub!(/\_{2,}/, '_')
        end
      end

      def check_defaults #:nodoc:
        siblings_with_default_set.update_attribute(:is_default, false) if self.parent && siblings_with_default_set && self.is_default
        self.is_default = false if archived
      end

      def siblings_with_default_set #:nodoc:
        self.parent.children.where(is_default: true).where("id != ?", self.id.to_i).first
      end

      def archived #:nodoc:
        !!archived_at
      end

      def archived=(archived_checkbox) #:nodoc:
        if archived_checkbox == "1"
          self.archived_at = Time.now unless archived_at
        else
          self.archived_at = nil
        end
      end

      def sub_children
        children.flat_map(&:children)
      end
    end

    def selectable #:nodoc:
      include ModelMixin
    end

    ActiveSupport.on_load :active_record do
      extend Selections::Selectable
    end
  end
end