module Selections
  module FormBuilderExtensions
    def selections(field, options = {}, html_options = {})
      SelectionTag.new(self, object, field, html_options, options).to_tag
    end

    class SelectionTag
      attr_reader :form, :object, :field, :html_options, :options, :selection, :field_id

      def initialize(form, object, field, html_options, options)
        @form = form
        @object = object
        @field = field
        @html_options = html_options || {}
        @options = options || {}
        @system_code_name = options[:system_code] || field
        @selection = Selections.model
        @field_id ||= (field.to_s + "_id").to_sym
      end

      def system_code
        #TODO convert to using where
        @system_code ||= selection.find_by_system_code(@system_code_name.to_s)
        @system_code ||= selection.find_by_system_code(form.object_name.to_s + "_" + @system_code_name.to_s)
      end

      def to_tag
        if system_code
          items = system_code.children
          if object.new_record? && object.send(field_id).nil?
            default = items.find_by_is_default(true)
            object.send("#{field_id}=", default.id) if default && !default.archived
          end
          options[:include_blank] = true if object.send(field_id).blank? && options[:include_blank].nil?
          #TODO add default style
          #html_options[:style] ||=
          form.select field_id, items.filter_archived_except_selected(object.send(field_id)).map { |item| [item.name, item.id] }, options, html_options
        else
          "Invalid system_code of '#{system_code_name}'"
        end
      end

    end

    ActiveSupport.on_load :action_view do
      ActionView::Helpers::FormBuilder.class_eval do
        include Selections::FormBuilderExtensions
      end
    end

  end
end