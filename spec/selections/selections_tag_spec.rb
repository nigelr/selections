require "spec_helper"

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
  args[:form]   ||= form
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
  let(:form) { ActionView::Helpers::FormBuilder.new(:ticket, ticket, ActionView::Base.new, {}, Proc.new {}) }
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
    end

    it "finds with form model prefixed" do
      model_parent
      expect(edit_form.system_code).to eq(model_parent)
    end
  end

  describe ".items" do
    before { all_selections }

    it "returns all children items" do
      expect(edit_form.items.all).to eq(parent.children)
    end
    context "archived" do
      before { selection_2.update_attribute(:archived, "1") }
      it "returns only non archived items" do
        expect(edit_form.items).to eq(parent.children - [selection_2])
      end
      it "returns archived items when selected" do
        ticket.update_attribute(:priority_id, selection_2.id)
        expect(edit_form.items.all).to eq(parent.children)
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
      it("when new form") { expect(new_form.selected_item).to eq("") }
      it "when edit form with ticket.priority_id set" do
        ticket.update_attribute(:priority_id, selection_3.id)
        expect(edit_form.selected_item).to eq(selection_3.id.to_s)
      end
      it("when edit form with no ticket.priority_id set") { expect(edit_form.selected_item).to eq("") }
    end
    context "when default is set" do
      before { selection_2.update_attribute(:is_default, true) }
      it("when new form") { expect(new_form.selected_item).to eq(selection_2.id.to_s) }
      it "when edit form with ticket.priority_id set" do
        ticket.update_attribute(:priority_id, selection_3.id)
        expect(edit_form.selected_item).to eq(selection_3.id.to_s)
      end
      it("when edit form with no ticket.priority_id set") { expect(edit_form.selected_item).to eq("") }
    end
  end

  describe ".to_tag" do
    it "displays warning when system_code does not exist" do
      expect(edit_form.to_tag).to eq("Invalid system_code of 'priority'")
    end
    context "valid system_code" do
      before { all_selections }

      context "new form" do
        context "no default" do
          it("has no selected item") { expect(Nokogiri::HTML(new_form.to_tag).search("option[selected]")).to be_empty }
          it("has a blank option") { expect(Nokogiri::HTML(new_form.to_tag).search("option[value='']").count).to eq(1) }
        end
        context "default is set" do
          before { selection_3.update_attribute(:is_default, true) }

          it("has selection_3 selected") { expect(Nokogiri::HTML(new_form.to_tag).search("option[selected]").first.content).to eq(selection_3.name) }
          it("has no blank option") { expect(Nokogiri::HTML(new_form.to_tag).search("option[value='']").count).to eq(0) }
        end
      end

      context "edit form" do
        context "relation (priority_id) is nil" do
          it("has no selected item") { expect(Nokogiri::HTML(edit_form.to_tag).search("option[selected]")).to be_empty }
          it("has a blank option") { expect(Nokogiri::HTML(edit_form.to_tag).search("option[value='']").count).to eq(1) }
        end
        context "when relation (priority_id) is set to selection_3" do
          before { ticket.update_attribute(:priority_id, selection_3.id) }

          it("item is selected") { expect(Nokogiri::HTML(edit_form.to_tag).search("option[selected]").first.content).to eq(selection_3.name) }
          it("has no blank option") { expect(Nokogiri::HTML(edit_form.to_tag).search("option[value='']").count).to eq(0) }
        end
      end
      it "returns valid html" do
        expect(edit_form.to_tag).to eq "<select id=\"ticket_priority_id\" name=\"ticket[priority_id]\"><option value=\"\"></option>\n<option value=\"4\">high</option>\n<option value=\"2\">low</option>\n<option value=\"3\">medium</option></select>"
      end
    end
  end
end
