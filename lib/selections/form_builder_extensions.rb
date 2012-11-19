module Selections
  module FormBuilderExtensions
    def selections(field, options = {}, html_options = {})
      SelectionTag.new(self, object, field, html_options, options).to_tag
    end

    class SelectionTag
      attr_reader :form, :object, :field, :html_options, :options, :selection, :field_id, :system_code_name

      def initialize(form, object, field, html_options, options)
        @form = form
        @object = object
        @field = field
        @html_options = html_options || {}

        @system_code_name = options[:system_code] || field
        @selection = Selections.model
        @field_id ||= (field.to_s + "_id").to_sym
        @options = options || {}
        @options[:include_blank] = true if object.try(:new_record?) && options[:include_blank].nil?
      end

      def system_code
        @system_code ||= selection.where(system_code: system_code_name.to_s).first
        @system_code ||= selection.where(system_code: "#{form.object_name}_#{system_code_name}").first
      end

      def items
        @items ||= system_code.children.filter_archived_except_selected(object.send(field_id))
      end

      def to_tag
        if system_code
          #if object.new_record? && object.send(field_id).nil?
          #  default = items.find_by_is_default(true)
          #  object.send("#{field_id}=", default.id) if default && !default.archived
          #end
          #TODO add default style
          #html_options[:style] ||=
          form.select field_id, items.map { |item| [item.name, item.id] }, options, html_options
        else
          "Invalid system_code of '#{system_code_name}'"
        end
      end

      def default_item
        if object.new_record?
          items.where(:is_default => true).first.try(:id).to_s
        else
          object.send(field_id).to_s
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