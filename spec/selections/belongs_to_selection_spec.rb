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
end
