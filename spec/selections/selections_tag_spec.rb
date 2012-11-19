require "spec_helper"


include Selections::FormBuilderExtensions
describe SelectionTag do
  let(:parent) { Selection.create(name: "priority") }
  let(:model_parent) { Selection.create(name: "ticket_priority") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id) }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id) }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:ticket, ticket, ActionView::Base.new, {}, Proc.new {}) }
  let(:ticket) { Ticket.create(:name=>"railscamp") }
  let(:all_selections) do
    parent
    selection_1
    selection_2
    selection_3
  end


  describe ".system_code" do
    context "direct parent" do
      before { parent }
      it "returns priority selection item" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).system_code).to eq(parent)
      end
      it "does not find" do
        expect(SelectionTag.new(form, ticket, :non_existent, {}, {}).system_code).to be_nil
      end
    end

    it "finds with form model prefixed" do
      model_parent
      expect(SelectionTag.new(form, ticket, :priority, {}, {}).system_code).to eq(model_parent)
    end
  end

  describe ".items" do
    before do
      parent
      selection_1
      selection_2
      selection_3
    end

    it "returns all children items" do
      expect(SelectionTag.new(form, ticket, :priority, {}, {}).items.all).to eq(parent.children)
    end
    context "archived" do
      before { selection_2.update_attribute(:archived, true) }
      it "returns only non archived items" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items).to eq(parent.children - [selection_2])
      end
      it "returns archived items when selected" do
        ticket.update_attribute(:priority_id, selection_2.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items.all).to eq(parent.children )
      end
    end
  end

  describe ".field_id" do
    it("when string") { expect(SelectionTag.new(nil, nil, "priority", {}, {}).field_id).to eq(:priority_id) }
    it("when symbol") { expect(SelectionTag.new(nil, nil, :priority, {}, {}).field_id).to eq(:priority_id) }
  end

  describe ".system_code_name" do
    it("sets to field name") { expect(SelectionTag.new(nil, nil, :priority, {}, {}).system_code_name).to eq(:priority) }
    it("when override system_code") { expect(SelectionTag.new(nil, nil, :hello, {}, {system_code: :priority}).system_code_name).to eq(:priority) }
  end

  context "include blank" do
    context "new form" do
      it "and include_blank not set" do
        expect(SelectionTag.new(form, Ticket.new, :priority, {}, {}).options[:include_blank]).to be_true
      end
      it "and include_blank is set to false" do
        expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).options[:include_blank]).to be_false
      end
      it "and include_blank is set to true" do
        expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: true}).options[:include_blank]).to be_true
      end
    end
    context "edit form" do
      it "and include_blank not set" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).options[:include_blank]).to be_false
      end
      it "and include_blank is set to true" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: true}).options[:include_blank]).to be_true
      end
      it "and include_blank is set to false" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).options[:include_blank]).to be_false
      end
    end
  end

  context ".default" do
    before { all_selections }
    it "returns nil when no default set" do
      expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).default_item).to be_blank
    end
    context "when a default is set" do
      before { selection_2.update_attribute(:is_default, true) }
      it "should set when new form" do
        expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).default_item).to eq(selection_2.id.to_s)
      end
      it "should not set when editing form" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).default_item).to be_blank
      end
      it "should be set selected item when editing form" do
        ticket.update_attribute(:priority_id, selection_3.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).default_item).to eq(selection_3.id.to_s)
      end
    end
  end

  describe ".to_tag" do

    #TODO need to create a form action with a related table so new_record? will work
    it "new_record?" do
      parent
      selection_1
      selection_2
      selection_3
      puts SelectionTag.new(form, ticket, :priority, {}, {}).to_tag
    end
  end
end