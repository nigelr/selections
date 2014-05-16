require "spec_helper"

describe Selections do
  let(:parent) { Selection.create(name: "priority") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id) }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id) }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id) }

  describe ".filter_archived_except_selected" do
    before do
      selection_1
      selection_2
    end
    it "returns all when none selected" do
      parent.children.filter_archived_except_selected(nil)
      expect(parent.children.filter_archived_except_selected(nil)).to match_array([selection_2, selection_1])
    end
    it "returns all even when selected" do
      expect(parent.children.filter_archived_except_selected(selection_2.id)).to match_array([selection_2, selection_1])
    end
    context "archived" do
      before :each do
        selection_2.update_attribute(:archived, "1")
      end
      it "returns unarchived items" do
        expect(parent.children.filter_archived_except_selected(nil)).to match_array([selection_1])
      end
      it "returns only unarchived items when archived is not selected" do
        expect(parent.children.filter_archived_except_selected(selection_1.id)).to match_array([selection_1])
      end
      it "returns archived item if selected" do
        expect(parent.children.filter_archived_except_selected(selection_2.id)).to match_array([selection_2, selection_1])
      end
    end
  end

  describe ".to_s" do
    it "returns name" do
      expect(selection_1.to_s).to eq(selection_1.name)
    end
  end

  describe '#fixture_id' do
    context 'returns ID without DB access' do
      if ActiveRecord::VERSION::MAJOR >= 4
        it { expect(Selection.label_to_id('priority_high')).to eq ActiveRecord::FixtureSet.identify(:priority_high) }
        it { expect(Selection.label_to_id(:priority_high)).to eq ActiveRecord::FixtureSet.identify(:priority_high) }
      else
        it { expect(Selection.label_to_id('priority_high')).to eq ActiveRecord::Fixtures.identify(:priority_high) }
        it { expect(Selection.label_to_id(:priority_high)).to eq ActiveRecord::Fixtures.identify(:priority_high) }
      end
    end
  end

  describe ".leaf?" do
    it { selection_1; expect(parent.leaf?).to be_false }
    it { expect(selection_1.leaf?).to be_true }
  end

  describe ".sub_children" do
    before do
      selection_1.children = [Selection.create(name: "sub_1"), Selection.create(name: "sub_2")]
      selection_2.children = [Selection.create(name: "sub_3")]
    end
    it "gets all the childrens children" do
      expect(parent.sub_children).to match_array(selection_1.children + selection_2.children)
    end
    it "return empty array from leaf" do
      expect(selection_1.children.first.sub_children).to eq([])
    end
  end

  describe ".position=" do
    it "sets to HIDDEN_POSITION if blank" do
      expect(Selection.create(name: "position", position: nil).position_value).to eq(Selection::HIDDEN_POSITION)
    end
    it "sets to position_value to 45" do
      expect(Selection.create(name: "position", position: 45).position_value).to eq(45)
    end
  end

  describe ".position" do
    it "should display position if not HIDDEN_POSITION" do
      expect(Selection.create(name: "position", position: 46).position).to eq(46)
    end
    it "should not display position if HIDDEN_POSITION" do
      expect(Selection.create(name: "position", position: nil).position).to be_nil
    end
  end

  describe ".auto_gen_system_code" do
    it "only generates if blank" do
      expect(Selection.create(name: "position", system_code: "hello_world").system_code).to eq("hello_world")
    end

    context "chaining of system_codes" do
      before do
        @parent = Selection.create(name: "Board Chairman")
      end
      it "create system_code from name" do
        expect(@parent.system_code).to eq("board_chairman")
      end
      context "child" do
        before do
          @child = Selection.create(name: "CEO", parent: @parent)
        end
        it "create system_code from name" do
          expect(@child.system_code).to eq("board_chairman_ceo")
        end
        context "child" do
          it "create system_code from name" do
            expect(Selection.create(name: "head janitor", parent: @child).system_code).to eq("board_chairman_ceo_head_janitor")
          end
        end
      end
    end
  end

  describe ".siblings_with_default_set" do
    before do
      selection_1
      selection_2
      selection_3
    end
    it "returns none when no default set" do
      expect(selection_2.siblings_with_default_set).to eq(nil)
    end
    context "default set" do
      before do
        selection_2.update_attribute(:is_default, true)
      end
      it "returns item with default set" do
        expect(selection_1.siblings_with_default_set).to eq(selection_2)
      end
      it "does not returns item with default set when self" do
        expect(selection_2.siblings_with_default_set).to eq(nil)
      end
    end
  end

  describe ".check_defaults" do
    before do
      selection_1
      selection_2
      selection_3
    end
    it("selection_1 should not be set") { expect(selection_1.reload.is_default).to be_false }
    it("selection_2 should not be set") { expect(selection_2.reload.is_default).to be_false }
    it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }

    context "setting one item to default" do
      before { selection_2.update_attributes(is_default: true) }
      it("should set self as default") { expect(selection_2.reload.is_default).to be_true }
      it("selection_1 should not be set") { expect(selection_1.reload.is_default).to be_false }
      it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }
      context "setting same item to default" do
        before { selection_2.update_attributes(is_default: true) }
        it("should set self as default") { expect(selection_2.reload.is_default).to be_true }
        it("selection_1 should not be set") { expect(selection_1.reload.is_default).to be_false }
        it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }
      end
      context "setting other item to default" do
        before { selection_1.update_attributes(is_default: true) }
        it("should set self as default") { expect(selection_1.reload.is_default).to be_true }
        it("selection_2 should not be set") { expect(selection_2.reload.is_default).to be_false }
        it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }
      end
      context "removing default setting" do
        before { selection_2.update_attributes(is_default: false) }
        it("should unset self as default") { expect(selection_1.reload.is_default).to be_false }
        it("selection_2 should not be set") { expect(selection_2.reload.is_default).to be_false }
        it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }
      end
      context "archive item with default" do
        before { selection_2.update_attributes(archived: "1") }
        it("should unset self as default") { expect(selection_2.reload.is_default).to be_false }
        it("selection_1 should not be set") { expect(selection_1.reload.is_default).to be_false }
        it("selection_3 should not be set") { expect(selection_3.reload.is_default).to be_false }
      end
    end
  end

  describe ".archived=" do
    before do
      @stubbed_time = Time.parse("01/01/2010 10:00")
      Time.stub(:now).and_return(@stubbed_time)
      selection_1.update_attributes(archived: "1")
    end

    it "should set archived" do
      expect(selection_1.archived_at).to eq @stubbed_time
    end
    it "remain archived and not change date when set again" do
      Time.stub(:now).and_return(Time.parse("12/12/2012 10:00"))
      selection_1.update_attributes(archived: "1")
      expect(selection_1.archived_at).to eq @stubbed_time
    end
    it "un-archives item" do
      selection_1.update_attributes(archived: "0")
      expect(selection_1.archived_at).to be_nil
    end
  end

  describe ".archived" do
    it "when archived set" do
      selection_1.update_attributes(archived: "1")
      expect(selection_1.archived).to be_true
    end
    it "when archived set" do
      selection_1.update_attributes(archived: "0")
      expect(selection_1.archived).to be_false
    end
  end

  context "selecting" do
    before do
      selection_1
      selection_2
    end
    it "singular" do
      expect(Selection.send(parent.system_code)).to eq(parent)
    end
    it "plural" do
      expect(Selection.send(parent.system_code.pluralize)).to eq(parent.children)
    end
    #TODO this needs to ne an option
    #it "should not error when non existent" do
    #  expect(Selection.non_existent_system_code).to eq([])
    #end
  end
end
