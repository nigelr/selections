require 'spec_helper'

include Selections::FormBuilderExtensions

def edit_form args = {}
  args[:object] ||= ticket
  common_form args
end

def new_form args = {}
  args[:object] ||= Ticket.new
  common_form args
end

def common_form args = {}
  args[:form] ||= form
  args[:field] ||= :priority
  args[:html_options] ||= {}
  args[:options] ||= {}
  SelectionTag.new(args[:form], args[:object], args[:field], args[:options], args[:html_options])
end

describe SelectionTag do
  let(:parent) { Selection.create(name: "priority") }
  let(:model_parent) { Selection.create(name: "ticket_priority") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id) }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id) }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id) }
  if ActiveRecord::VERSION::MAJOR >= 4
    let(:form) { ActionView::Helpers::FormBuilder.new(:ticket, ticket, ActionView::Base.new, {}) }
    let(:form_user) { ActionView::Helpers::FormBuilder.new(:user, :user, ActionView::Base.new, {}) }
  else
    let(:form) { ActionView::Helpers::FormBuilder.new(:ticket, ticket, ActionView::Base.new, {}, Proc.new {}) }
    let(:form_user) { ActionView::Helpers::FormBuilder.new(:user, :user, ActionView::Base.new, {}, Proc.new {}) }
  end
  let(:ticket) { Ticket.create(:name => "railscamp") }
  let(:all_selections) do
    parent
    selection_1
    selection_2
    selection_3
  end


  describe ".system_code" do
    context "direct parent" do
      before { parent }
      it("returns priority selection item") { expect(edit_form.system_code).to eq(parent) }
      it("does not find") { expect(edit_form(field: "non_existent").system_code).to be_nil }
      context "when more explicit route should found first" do
        before { model_parent }
        it("should find more explicit route of model parent") { expect(edit_form.system_code).to eq(model_parent) }
        it "should use priority system_code when model is not ticket" do
          expect(edit_form(form: form_user ).system_code).to eq(parent)
        end
      end
    end

    context "system_code override" do
      it 'passes through system code' do
        hello = Selection.create(name: "hello")
        parent
        expect(new_form(options: {system_code: :hello} ).system_code).to eq hello
      end
    end

    it "finds with form model prefixed" do
      model_parent
      expect(edit_form.system_code).to eq(model_parent)
    end
  end

  describe ".items" do
    before { all_selections }

    it "returns all children items" do
      expect(edit_form.items.to_a).to eq(parent.children)
    end
    context "archived" do
      before { selection_2.update_attribute(:archived, "1") }
      it "returns only non archived items" do
        expect(edit_form.items).to eq(parent.children - [selection_2])
      end
      it "returns archived items when selected" do
        ticket.update_attribute(:priority_id, selection_2.id)
        expect(edit_form.items.to_a).to eq(parent.children)
      end
    end
  end

  describe ".field_id" do
    it("when string") { expect(edit_form(field: "priority").field_id).to eq(:priority_id) }
    it("when symbol") { expect(edit_form(field: :priority).field_id).to eq(:priority_id) }
  end

  describe ".system_code_name" do
    it("sets to field name") { expect(edit_form.system_code_name).to eq(:priority) }
    it("when override system_code") { expect(edit_form(field: :hello, options: {system_code: :priority}).system_code_name).to eq(:priority) }
  end

  context "include blank" do
    before { all_selections }

    context "when not set" do
      context "new form" do
        it("has blank") { expect(new_form.include_blank?).to be_true }
        it "has no blank when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(new_form.include_blank?).to be_false
        end
      end
      context "edit form" do
        it("has no blank when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(edit_form.include_blank?).to be_false
        end
        it("has blank when ticket.priority_id is nil") { expect(edit_form.include_blank?).to be_true }
        it "has no blank when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(edit_form.include_blank?).to be_false
        end
      end
    end

    context "when set false" do
      context "new form" do
        it("has no blank") { expect(new_form(options: {include_blank: false}).include_blank?).to be_false }
        it "has no blank when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(new_form(options: {include_blank: false}).include_blank?).to be_false
        end
      end
      context "edit form" do
        it("has no blank when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(edit_form(options: {include_blank: false}).include_blank?).to be_false
        end
        it("has no blank even when ticket.priority_id is nil") { expect(edit_form(options: {include_blank: false}).include_blank?).to be_false }
        it "has no blank when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(edit_form(options: {include_blank: false}).include_blank?).to be_false
        end
      end
    end

    context "when set to true" do
      context "new form" do
        it("has blank") { expect(new_form(options: {include_blank: true}).include_blank?).to be_true }
        it "has blank even when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(new_form(options: {include_blank: true}).include_blank?).to be_true
        end
      end
      context "edit form" do
        it("has blank even when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(edit_form(options: {include_blank: true}).include_blank?).to be_true
        end
        it("has blank even when ticket.priority_id is nil") { expect(edit_form(options: {include_blank: true}).include_blank?).to be_true }
        it "has blank even when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(edit_form(options: {include_blank: true}).include_blank?).to be_true
        end
      end
    end
  end

  context ".default_item" do
    before { all_selections }
    it "returns nil when no default set" do
      expect(new_form.default_item).to be_blank
    end
    it "should set to default item" do
      selection_2.update_attribute(:is_default, true)
      expect(new_form.default_item).to eq(selection_2.id.to_s)
    end
  end

  context ".selected_item" do
    before { all_selections }

    context "when default not set" do
      context "when new form" do
        it 'has no value' do
          expect(new_form.selected_item).to eq("")
        end
        it 'priority value is already set (simulating a failed validation)' do
          expect(new_form(object: Ticket.new(priority_id: selection_3.id)).selected_item).to eq(selection_3.id.to_s)
        end
      end
      context "when edit form" do
        context "ticket.priority_id set" do
          before { ticket.update_attribute(:priority_id, selection_3.id) }

          it { expect(edit_form.selected_item).to eq(selection_3.id.to_s) }
          it 'priority value is changed (simulating a failed validation)' do
            expect(edit_form(object: ticket.assign_attributes(priority_id: selection_2.id)).selected_item).to eq(selection_2.id.to_s)
          end
        end
        context 'no ticket.priority_id set' do
          it { expect(edit_form.selected_item).to eq("") }
          it 'priority value is changed (simulating a failed validation)' do
            expect(edit_form(object: ticket.assign_attributes(priority_id: selection_2.id)).selected_item).to eq(selection_2.id.to_s)
          end
        end
      end
    end
    context "when default is set" do
      before { selection_2.update_attribute(:is_default, true) }

      context 'new form' do
        it { expect(new_form.selected_item).to eq(selection_2.id.to_s) }
        it 'priority value is already set (simulating a failed validation)' do
          expect(new_form(object: Ticket.new(priority_id: selection_3.id)).selected_item).to eq(selection_3.id.to_s)
        end
      end

      context 'edit form' do
        it('has no ticket.priority_id set') { expect(edit_form.selected_item).to eq("") }
        context 'has ticket.priority_id set' do
          before { ticket.update_attribute(:priority_id, selection_3.id) }

          it 'should not change' do
            expect(edit_form.selected_item).to eq(selection_3.id.to_s)
          end
          it 'priority value is changed (simulating a failed validation)' do
            expect(edit_form(object: ticket.assign_attributes(priority_id: selection_2.id)).selected_item).to eq(selection_2.id.to_s)
          end
        end
      end
    end
  end

  describe '.blank_content' do
    it 'when nothing set' do
      expect(new_form.blank_content).to eq('none')
    end
    it 'when set' do
      expect(new_form(options: {blank_content: 'hello'}).blank_content).to eq('hello')
    end
  end

  context 'html output' do
    describe '.select_tag' do
      context 'invalid' do
        it 'displays warning when system_code does not exist' do
          expect(edit_form.select_tag).to eq("Could not find system_code of 'priority' or 'ticket_priority'")
        end
        it 'displays warning for system_code override' do
          expect(edit_form(options: {system_code: 'hello'}).select_tag).to eq("Could not find system_code of 'hello' or 'ticket_hello'")
        end
      end
      context 'valid system_code' do
        before { all_selections }

        context 'new form' do
          context 'no default' do
            it('has no selected item') { expect(Nokogiri::HTML(new_form.select_tag).search('option[selected]')).to be_empty }
            it('has a blank option') { expect(Nokogiri::HTML(new_form.select_tag).search("option[value='']").count).to eq(1) }
          end
          context 'default is set' do
            before { selection_3.update_attribute(:is_default, true) }

            it('has selection_3 selected') { expect(Nokogiri::HTML(new_form.select_tag).search('option[selected]').first.content).to eq(selection_3.name) }
            it('has no blank option') { expect(Nokogiri::HTML(new_form.select_tag).search("option[value='']").count).to eq(0) }
          end
        end

        context 'edit form' do
          context 'relation (priority_id) is nil' do
            it('has no selected item') { expect(Nokogiri::HTML(edit_form.select_tag).search('option[selected]')).to be_empty }
            it('has a blank option') { expect(Nokogiri::HTML(edit_form.select_tag).search("option[value='']").count).to eq(1) }
          end
          context 'when relation (priority_id) is set to selection_3' do
            before { ticket.update_attribute(:priority_id, selection_3.id) }

            it('item is selected') { expect(Nokogiri::HTML(edit_form.select_tag).search('option[selected]').first.content).to eq(selection_3.name) }
            it('has no blank option') { expect(Nokogiri::HTML(edit_form.select_tag).search("option[value='']").count).to eq(0) }
          end
        end
        it 'returns valid html' do
          expect(edit_form.select_tag).to eq "<select id=\"ticket_priority_id\" name=\"ticket[priority_id]\"><option value=\"\"></option>\n<option value=\"4\">high</option>\n<option value=\"2\">low</option>\n<option value=\"3\">medium</option></select>"
        end
      end
    end
    describe '.radio_tag' do
      context 'invalid' do
        it 'displays warning when system_code does not exist' do
          expect(edit_form.radio_tag).to eq("Could not find system_code of 'priority' or 'ticket_priority'")
        end
        it 'displays warning for system_code override' do
          expect(edit_form(options: {system_code: "hello"}).radio_tag).to eq("Could not find system_code of 'hello' or 'ticket_hello'")
        end
      end
      context 'valid system_code' do
        before { all_selections }

        context 'new form' do
          context 'no default' do
            it('has no selected item') { expect(Nokogiri::HTML(new_form.radio_tag).search('input[checked]')).to be_empty }
            it('has a blank option') { expect(Nokogiri::HTML(new_form.radio_tag).search('label').first.content).to eq('none') }
            it('has a custom blank option') { expect(Nokogiri::HTML(new_form(options: {blank_content: 'hello'}).radio_tag).search('label').first.content).to eq('hello') }
          end
          context 'default is set' do
            before { selection_3.update_attribute(:is_default, true) }

            it('has selection_3 selected') { expect(Nokogiri::HTML(new_form.radio_tag).search('input[checked]').first['value']).to eq(selection_3.id.to_s) }
            it('has no blank option') { expect(Nokogiri::HTML(new_form.radio_tag).search('label').first.content).to eq(selection_3.name) }
          end
        end

        context 'edit form' do
          context 'relation (priority_id) is nil' do
            it('has no selected item') { expect(Nokogiri::HTML(edit_form.radio_tag).search('input[checked]')).to be_empty }
            it('has a blank option') { expect(Nokogiri::HTML(edit_form.radio_tag).search('label').first.content).to eq('none') }
          end
          context 'when relation (priority_id) is set to selection_3' do
            before { ticket.update_attribute(:priority_id, selection_3.id) }

            it('item is selected') { expect(Nokogiri::HTML(edit_form.radio_tag).search('input[checked]').first['value']).to eq(selection_3.id.to_s) }
            it('has no blank option') { expect(Nokogiri::HTML(edit_form.radio_tag).search('label').first.content).to eq(selection_3.name) }
            it('has a blank option when include_blank set') { expect(Nokogiri::HTML(edit_form(options: {include_blank: true}).radio_tag).search('label').first.content).to eq('none') }
          end
        end
        it 'returns valid html' do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(edit_form(options: {include_blank: true}, html_options: {class: 'fred'}).radio_tag).to eq "<label class=\"fred\" for=\"ticket_priority_id\"><input class=\"fred\" id=\"ticket_priority_id\" name=\"ticket[priority_id]\" type=\"radio\" />none</label><label class=\"fred\" for=\"ticket_priority_id_4\"><input checked=\"checked\" class=\"fred\" id=\"ticket_priority_id_4\" name=\"ticket[priority_id]\" type=\"radio\" value=\"4\" />high</label><label checked=\"checked\" class=\"fred\" for=\"ticket_priority_id_2\"><input class=\"fred\" id=\"ticket_priority_id_2\" name=\"ticket[priority_id]\" type=\"radio\" value=\"2\" />low</label><label class=\"fred\" for=\"ticket_priority_id_3\"><input class=\"fred\" id=\"ticket_priority_id_3\" name=\"ticket[priority_id]\" type=\"radio\" value=\"3\" />medium</label>"
        end
      end
    end
  end
end
