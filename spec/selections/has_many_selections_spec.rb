require 'spec_helper'
require 'shoulda/matchers'

describe Selections::HasManySelections do
  let(:parent) { Selection.create(name: "priority", system_code: "ticket_priority") }
  let(:selection_1) { Selection.create(name: "low", parent_id: parent.id, system_code: "ticket_priority_low") }
  let(:selection_2) { Selection.create(name: "medium", parent_id: parent.id, system_code: "ticket_priority_medium") }
  let(:selection_3) { Selection.create(name: "high", parent_id: parent.id, system_code: "ticket_priority_high") }

  let(:ticket_class) do
    # create the priority records *before* using has_many_selections on the class.
    selection_1; selection_2; selection_3

    Class.new(ActiveRecord::Base) do
      self.table_name = "tickets"

      # anonymous class has no name, so fake the "Ticket" name
      def self.name
        "Ticket"
      end

      has_many_selections :priorities, predicates: true, scopes: true
      belongs_to_selection :other_priority, predicates: true, scopes: true

      serialize :priority_ids
    end
  end

  before do
    ticket_class
  end

  context 'dynamic methods' do
    subject { ticket_class.new }

    context 'predicates' do
      %w{low medium high}.each do |p|
        it "creates the method #priority_#{p}?" do
          expect(subject.respond_to? "ticket_priority_#{p}?".to_sym).to be_truthy
        end
      end

      context 'high priority' do
        before { subject.priority_ids = [selection_3.id] }

        it("#priorities_high? is true") do
          expect(subject.ticket_priority_high?).to be_truthy
        end
        it("#priorities_medium? is false") do
          expect(subject.ticket_priority_medium?).to be_falsey
        end
        it("#priorities_low? is false") do
          expect(subject.ticket_priority_low?).to be_falsey
        end
      end

      context 'with no matching selections' do
        it "creates no methods" do
          # Test it doesnt reach define method stage
          expect_any_instance_of(Selection).not_to receive(:children)
          ticket_class.has_many_selections :wrong
        end
      end

      context 'scopes' do
        %w{low medium high}.each do |p|
          it "creates the method #ticket_priority_#{p}s" do
            expect(ticket_class.respond_to? "ticket_priority_#{p}".pluralize.to_sym).to be_truthy
          end
        end

        context 'high priority' do
          before { subject.priority_ids = [selection_3.id]; subject.save! }

          it("#priorities_highs is true") do
            expect(ticket_class.ticket_priority_highs).to eq([subject])
          end
          it("#priorities_media is false") do
            expect(ticket_class.ticket_priority_media).to eq([])
          end
          it("#priorities_lows is false") do
            expect(ticket_class.ticket_priority_lows).to eq([])
          end
        end
      end

      context 'names' do
        context 'when the selection is nil' do
          it 'returns an empty string' do
            subject.priority_ids = []
            expect(subject.priority_names).to eq('')
          end
        end

        context 'when the selection is not nil' do
          it 'returns the selection name' do
            subject.priority_ids = [selection_3.id]
            expect(subject.priority_names).to eq(selection_3.name)
          end
        end
      end

      describe '.method_missing' do
        context 'predicates' do
          context 'when it starts with an existing selections name' do
            it 'returns false' do
              expect(subject.priority_lower?).to be_falsey
            end
          end

          context 'when it does not start with an existing selections name' do
            it 'raises an error' do
              expect do
                subject.other_selection?
              end.to raise_error(NoMethodError)
            end
          end
        end

        context 'scopes' do
          context 'when it starts with an existing selections name' do
            it 'returns an empty array' do
              expect(ticket_class.priority_lower).to eq([])
            end
          end

          context 'when it does not start with an existing selections name' do
            it 'raises an error' do
              expect do
                ticket_class.other_selection
              end.to raise_error(NoMethodError)
            end
          end
        end
      end
    end
  end
end
