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
      expect(SelectionTag.new(form, ticket, :priority, {}, {}).items).to eq(parent.children)
    end
    context "archived" do
      before { selection_2.update_attribute(:archived, true) }
      it "returns only non archived items" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items).to eq(parent.children - [selection_2])
      end
      it "returns archived items when selected" do
        ticket.update_attribute(:priority_id, selection_2.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items).to eq(parent.children )
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