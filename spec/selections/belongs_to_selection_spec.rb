require 'spec_helper'
require 'shoulda/matchers'

describe Selections::BelongsToSelection do

  let(:parent) { Selection.create(name: "priority", system_code: "ticket_priority") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id, system_code: "ticket_priority_low") }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id, system_code: "ticket_priority_medium") }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id, system_code: "ticket_priority_high") }

  let(:ticket_class) do
    # create the priority records *before* using belongs_to_selection on the class.
    selection_1; selection_2; selection_3

    Class.new(ActiveRecord::Base) do
      self.table_name = "tickets"

      # anonymous class has no name, so fake the "Ticket" name
      def self.name
        "Ticket"
      end

      belongs_to_selection :priority
    end
  end

  before do
    ticket_class
  end

  context 'relationships' do
    it "creates a belongs to relationship" do
      assc = ticket_class.reflect_on_association(:priority)
      expect(assc.macro).to eq :belongs_to
    end
  end

  context 'dynamic methods' do
    subject { ticket_class.new }
    %w{low medium high}.each do |p|
      it "creates the method #priority_#{p}?" do
        expect(subject.respond_to? "priority_#{p}?".to_sym).to be_truthy
      end
    end

    context 'high priority' do
      before { subject.priority = selection_3 }

      it("#priority_high? is true") do
        expect(subject.priority_high?).to be_truthy
      end
      it("#priority_medium? is false") do
        expect(subject.priority_medium?).to be_falsey
      end
      it("#priority_low? is false") do
        expect(subject.priority_low?).to be_falsey
      end
    end

    context 'with no matching selections' do
      it "does not create any methods" do
        # ensure only the method we expect is called
        expect(ticket_class).to receive(:define_method).with(:autosave_associated_records_for_wrong)
        # Test it doesnt reach define method stage
        expect_any_instance_of(Selection).not_to receive(:children)
        ticket_class.belongs_to_selection :wrong
      end
    end
  end
end
