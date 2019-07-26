module Selections
  module FormBuilderExtensions
    # Create a select list based on the field name finding items within Selection.
    #
    # Example
    #   form_for(@ticket) do |f|
    #     f.select("priority")
    #
    # Uses priority_id from the ticket table and creates options list based on items in Selection table with a system_code of
    # either priority or ticket_priority
    #
    # options = {} and html_options = {} suport all the keys as the rails library select_tag does.
    #
    # options
    # * +system_code+ - Overrides the automatic system_code name based on the fieldname and looks up the list of items in Selection
    # * +as+ - Changes the input type used. Defaults to a select_tag

    def selections(field, options = {}, html_options = {})
      if options[:as].to_s == 'radio'
        SelectionTag.new(self, object, field, options, html_options).radio_tag
      elsif options[:as].to_s == 'check_boxes'
        SelectionTag.new(self, object, field, options, html_options).check_box_tag
      else
        SelectionTag.new(self, object, field, options, html_options).select_tag
      end
    end

    class SelectionTag #:nodoc:
      attr_reader :form, :object, :field, :options, :html_options, :selection, :field_id, :system_code_name

      def initialize(form, object, field, options, html_options)
        @form = form
        @object = object
        @field = field
        @html_options = html_options || {}

        @system_code_name = options[:system_code] || field
        @selection = Selections.model
        @field_id ||= options[:field_id] || (field.to_s + "_id").to_sym
        @options = options || {}
      end

      def include_blank?
        if options[:include_blank].nil?
          !!((object.try(:new_record?) || !object.send(field_id))) && default_item.blank?
        else
          !!options[:include_blank]
        end
      end

      def system_code
        @system_code ||= selection.where(system_code: "#{form.object_name}_#{system_code_name}").first
        @system_code ||= selection.where(system_code: system_code_name.to_s).first
      end

      def items
        @items ||= system_code.children.filter_archived_except_selected(Array(object.send(field_id)))
      end

      def select_tag
        if system_code
          html_options[:class] ||= ''
          html_options[:class] << ' selection select'
          options[:include_blank] = include_blank?
          options[:selected] = selected_item
          form.select field_id, items.map { |item| [item.name, item.id] }, options, html_options
        else
          error_message
        end
      end

      def radio_tag
        if system_code
          html_options[:class] ||= ''
          html_options[:class] << ' selection radio-button'
          items.inject('') do |build, item|
            label_html_options = item.id ? html_options.merge(value: item.id.to_s) : html_options
            html_options[:checked] = selected_item.include?(item.id.to_s) && !item.new_record?
            build + form.label(field_id, label_html_options) do
              form.radio_button(field_id, item.id, html_options) + item.name
            end
          end.html_safe
        else
          error_message
        end
      end

      def check_box_tag
        if system_code
          html_options[:class] ||= ''
          html_options[:class] << ' selection check-box'
          items.inject('') do |build, item|
            html_options[:checked] = selected_item.include?(item.id.to_s) && !item.new_record?
            html_options[:value] = item.id.to_s
            html_options[:multiple] = options[:multiple]
            label_html_options = html_options

            build + form.label(field_id, label_html_options) do
              form.check_box(field_id, html_options, item.id, false) + item.name
            end
          end.html_safe
        else
          error_message
        end
      end

      def error_message
        "Could not find system_code of '#{system_code_name}' or '#{form.object_name}_#{system_code_name}'"
      end

      def selected_item
        if object.new_record? && object.send(field_id).blank?
           Array(default_item)
        else
          Array(object.send(field_id)).map(&:to_s)
        end
      end

      def default_item
        items.where(is_default: true).first.try(:id).to_s
      end

      def blank_content
        options[:blank_content] || 'none'
      end
    end

    ActiveSupport.on_load :action_view do
      ActionView::Helpers::FormBuilder.class_eval do
        include Selections::FormBuilderExtensions
      end
    end

  end
end
