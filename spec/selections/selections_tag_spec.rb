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

  describe ".field_id" do
    it("when string") { expect(SelectionTag.new(nil, nil, "priority", {}, {}).field_id).to eq(:priority_id) }
    it("when symbol") { expect(SelectionTag.new(nil, nil, :priority, {}, {}).field_id).to eq(:priority_id) }
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