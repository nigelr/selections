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

      belongs_to_selection :priority, predicates: true, scopes: true
      has_many_selections :other_priorities, predicates: true, scopes: true
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

    context 'predicates' do
      %w{low medium high}.each do |p|
        it "creates the method #priority_#{p}?" do
          expect(subject.respond_to? "ticket_priority_#{p}?".to_sym).to be_truthy
        end
      end

      context 'high priority' do
        before { subject.priority = selection_3 }

        it("#priority_high? is true") do
          expect(subject.ticket_priority_high?).to be_truthy
        end
        it("#priority_medium? is false") do
          expect(subject.ticket_priority_medium?).to be_falsey
        end
        it("#priority_low? is false") do
          expect(subject.ticket_priority_low?).to be_falsey
        end
      end

      context 'with no matching selections' do
        it "only creates the name method" do
          # ensure only the method we expect is called
          expect(ticket_class).to receive(:define_method).with(:autosave_associated_records_for_wrong)
          expect(ticket_class).to receive(:define_method).with('wrong_name')
          # Test it doesnt reach define method stage
          expect_any_instance_of(Selection).not_to receive(:children)
          ticket_class.belongs_to_selection :wrong
        end
      end

      context 'scopes' do
        %w{low medium high}.each do |p|
          it "creates the method #ticket_priority_#{p}s" do
            expect(ticket_class.respond_to? "ticket_priority_#{p}".pluralize.to_sym).to be_truthy
          end
        end

        context 'high priority' do
          before { subject.priority = selection_3 }

          it("#priority_highs is true") do
            subject.save!
            expect(ticket_class.ticket_priority_highs).to eq([subject])
          end
          it("#priority_media is false") do
            expect(ticket_class.ticket_priority_media).to eq([])
          end
          it("#priority_lows is false") do
            expect(ticket_class.ticket_priority_lows).to eq([])
          end
        end
      end

      context 'names' do
        context 'when the selection is nil' do
          it 'returns an empty string' do
            subject.priority = nil
            expect(subject.priority_name).to eq('')
          end
        end

        context 'when the selection is not nil' do
          it 'returns the selection name' do
            subject.priority = selection_3
            expect(subject.priority_name).to eq(selection_3.name)
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
