require "spec_helper"


include Selections::FormBuilderExtensions
describe SelectionTag do
  let(:parent) { Selection.create(name: "priority") }
  let(:model_parent) { Selection.create(name: "post_other") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id) }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id) }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:post, nil, self, {}, Proc.new {}) }

  describe ".system_code" do
    context "direct parent" do
      before { parent }
      it "returns priority selection item" do
        expect(SelectionTag.new(nil, form, :priority, {}, {}).system_code).to eq(parent)
      end
      it "does not find" do
        expect(SelectionTag.new(nil, form, :non_existent, {}, {}).system_code).to be_nil
      end
    end

    it "finds with form model prefixed" do
      model_parent
      expect(SelectionTag.new(nil, form, :other, {}, {}).system_code).to eq(model_parent)
    end
  end

  describe ".field_id" do
    it("when string") { expect(SelectionTag.new(nil, nil, "priority", {}, {}).field_id).to eq(:priority_id) }
    it("when symbol") { expect(SelectionTag.new(nil, nil, :priority, {}, {}).field_id).to eq(:priority_id) }
  end
end