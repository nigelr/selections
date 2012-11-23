require "spec_helper"


include Selections::FormBuilderExtensions
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
    before { all_selections }

    it "returns all children items" do
      expect(SelectionTag.new(form, ticket, :priority, {}, {}).items.all).to eq(parent.children)
    end
    context "archived" do
      before { selection_2.update_attribute(:archived, "1") }
      it "returns only non archived items" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items).to eq(parent.children - [selection_2])
      end
      it "returns archived items when selected" do
        ticket.update_attribute(:priority_id, selection_2.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).items.all).to eq(parent.children)
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
    before { all_selections }

    context "when not set" do
      context "new form" do
        it("has blank") { expect(SelectionTag.new(form, Ticket.new, :priority, {}, {}).include_blank?).to be_true }
        it "has no blank when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, Ticket.new, :priority, {}, {}).include_blank?).to be_false
        end
      end
      context "edit form" do
        it("has no blank when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(SelectionTag.new(form, ticket, :priority, {}, {}).include_blank?).to be_false
        end
        it("has blank when ticket.priority_id is nil") { expect(SelectionTag.new(form, ticket, :priority, {}, {}).include_blank?).to be_true }
        it "has no blank when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, ticket, :priority, {}, {}).include_blank?).to be_false
        end
      end
    end

    context "when set false" do
      context "new form" do
        it("has no blank") { expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).include_blank?).to be_false }
        it "has no blank when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).include_blank?).to be_false
        end
      end
      context "edit form" do
        it("has no blank when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).include_blank?).to be_false
        end
        it("has no blank even when ticket.priority_id is nil") { expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).include_blank?).to be_false }
        it "has no blank when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: false}).include_blank?).to be_false
        end
      end
    end

    context "when set to true" do
      context "new form" do
        it("has blank") { expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: true}).include_blank?).to be_true }
        it "has blank even when default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: true}).include_blank?).to be_true
        end
      end
      context "edit form" do
        it("has blank even when ticket.priority_id is set") do
          ticket.update_attribute(:priority_id, selection_3.id)
          expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: true}).include_blank?).to be_true
        end
        it("has blank even when ticket.priority_id is nil") { expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: true}).include_blank?).to be_true }
        it "has blank even when ticket.priority_id is nil and default set" do
          selection_1.update_attribute(:is_default, true)
          expect(SelectionTag.new(form, ticket, :priority, {}, {include_blank: true}).include_blank?).to be_true
        end
      end
    end
  end

  context ".default_item" do
    before { all_selections }
    it "returns nil when no default set" do
      expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).default_item).to be_blank
    end
    it "should set to default item" do
      selection_2.update_attribute(:is_default, true)
      expect(SelectionTag.new(form, Ticket.new, :priority, {}, {include_blank: false}).default_item).to eq(selection_2.id.to_s)
    end
  end

  context ".selected_item" do
    before { all_selections }

    context "when default not set" do
      it("when new form") { expect(SelectionTag.new(form, Ticket.new, :priority, {}, {}).selected_item).to eq("") }
      it "when edit form with ticket.priority_id set" do
        ticket.update_attribute(:priority_id, selection_3.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).selected_item).to eq(selection_3.id.to_s)
      end
      it("when edit form with no ticket.priority_id set") { expect(SelectionTag.new(form, ticket, :priority, {}, {}).selected_item).to eq("") }
    end
    context "when default is set" do
      before { selection_2.update_attribute(:is_default, true) }
      it("when new form") { expect(SelectionTag.new(form, Ticket.new, :priority, {}, {}).selected_item).to eq(selection_2.id.to_s) }
      it "when edit form with ticket.priority_id set" do
        ticket.update_attribute(:priority_id, selection_3.id)
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).selected_item).to eq(selection_3.id.to_s)
      end
      it("when edit form with no ticket.priority_id set") { expect(SelectionTag.new(form, ticket, :priority, {}, {}).selected_item).to eq("") }
    end
  end

  describe ".to_tag" do
    it "displays warning when system_code does not exist" do
      expect(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).to eq("Invalid system_code of 'priority'")
    end
    context "valid system_code" do
      before { all_selections }

      context "new form" do
        context "no default" do
          it("has no selected item") { expect(Nokogiri::HTML(SelectionTag.new(form, Ticket.new, :priority, {}, {}).to_tag).search("option[selected]")).to be_empty }
          it("has a blank option") { expect(Nokogiri::HTML(SelectionTag.new(form, Ticket.new, :priority, {}, {}).to_tag).search("option[value='']").count).to eq(1) }
        end
        context "default is set" do
          before { selection_3.update_attribute(:is_default, true) }

          it("has selection_3 selected") { expect(Nokogiri::HTML(SelectionTag.new(form, Ticket.new, :priority, {}, {}).to_tag).search("option[selected]").first.content).to eq(selection_3.name) }
          it("has no blank option") { expect(Nokogiri::HTML(SelectionTag.new(form, Ticket.new, :priority, {}, {}).to_tag).search("option[value='']").count).to eq(0) }
        end
      end

      context "edit form" do
        context "relation (priority_id) is nil" do
          it("has no selected item") { expect(Nokogiri::HTML(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).search("option[selected]")).to be_empty }
          it("has a blank option") { expect(Nokogiri::HTML(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).search("option[value='']").count).to eq(1) }
        end
        context "when relation (priority_id) is set to selection_3" do
          before { ticket.update_attribute(:priority_id, selection_3.id) }

          it("item is selected") { expect(Nokogiri::HTML(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).search("option[selected]").first.content).to eq(selection_3.name) }
          it("has no blank option") { expect(Nokogiri::HTML(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).search("option[value='']").count).to eq(0) }
        end
      end
      it "returns valid html" do
        expect(SelectionTag.new(form, ticket, :priority, {}, {}).to_tag).to eq "<select id=\"ticket_priority_id\" name=\"ticket[priority_id]\"><option value=\"\"></option>\n<option value=\"4\">high</option>\n<option value=\"2\">low</option>\n<option value=\"3\">medium</option></select>"
      end
    end
  end
end
