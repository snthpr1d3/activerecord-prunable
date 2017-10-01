# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::Prunable do
  subject { SomeMixin }

  before do
    allow(subject).to receive(:logger).and_return(Logger)

    if subject.class_variable_defined?(:@@prune_created_after)
      subject.remove_class_variable(:@@prune_created_after)
    end

    if subject.class_variable_defined?(:@@prune_updated_after)
      subject.remove_class_variable(:@@prune_updated_after)
    end

    if subject.class_variable_defined?(:@@prune_method)
      subject.remove_class_variable(:@@prune_method)
    end
  end

  describe '.includes' do
    it 'has array with all prunable models' do
      expect(described_class.includes).to contain_exactly(SomeMixin, AnotherMixin)
    end
  end

  describe '.prune_method' do
    context 'incorrect prune method' do
      it 'returns false' do
        expect(subject.prune_method(123)).to be false
        expect(subject.prune_method(:something)).to be false
      end

      it "doesn't change @@prune_method variable" do
        expect { subject.prune_method(:incorrect) }
          .not_to(change { subject.class_variable_defined?(:@@prune_method) })
      end
    end

    context 'correct prune method' do
      it 'returns method name' do
        expect(subject.prune_method(:destroy)).to eq(:destroy)
        expect(subject.prune_method(:delete)).to eq(:delete)
      end

      it 'sets @@prune_method_variable' do
        subject.prune_method(:destroy)

        expect { subject.prune_method(:delete) }
          .to change { subject.class_variable_get(:@@prune_method) }
          .from(:destroy)
          .to(:delete)
      end
    end
  end

  describe '.prune!' do
    let(:correct_scope) { ->() { ActiveRecord::Relation.new(FakeActiveRecord, FakeActiveRecord.arel_table) } }
    let(:incorrect_scope) { ->() { 123 } }
    let(:prunable) { double(is_a?: true, destroy_all: [], delete_all: 0) }

    it 'returns result of .prune_by_method' do
      prune_result = double(:prune_result).as_null_object
      allow(subject).to receive(:prunable).and_return(correct_scope)
      allow(subject).to receive(:prune_by_method).and_return(prune_result)
      expect(subject.prune!).to eq(prune_result)
    end

    context 'by prune_created_after method' do
      let(:scope) { double(:scope).as_null_object }
      let(:current_time) { Time.parse('2017-10-07 00:00:00') }

      before do
        subject.prune_created_after(7.days)
        expect(scope).to receive(:destroy_all)
      end

      it 'resolves removing scope correctly' do
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject).to receive(:where)
          .with('created_at < ?', Time.parse('2017-09-30 00:00:00'))
          .and_return(scope)

        subject.prune!
      end

      it 'resolves removing scope correctly with forced time' do
        expect(subject).to receive(:where)
          .with('created_at < ?', Time.parse('2017-09-30 00:00:00'))
          .and_return(scope)

        subject.prune!(current_time: current_time)
      end
    end

    context 'by prune_updated_after method' do
      let(:scope) { double(:scope).as_null_object }
      let(:current_time) { Time.parse('2017-10-07 00:00:00') }

      before do
        subject.prune_updated_after(7.days)
        expect(scope).to receive(:destroy_all)
      end

      it 'resolves removing scope correctly' do
        allow(Time).to receive(:current).and_return(current_time)

        expect(subject).to receive(:where)
          .with('updated_at < ?', Time.parse('2017-09-30 00:00:00'))
          .and_return(scope)

        subject.prune!
      end

      it 'resolves removing scope correctly with forced time' do
        expect(subject).to receive(:where)
          .with('updated_at < ?', Time.parse('2017-09-30 00:00:00'))
          .and_return(scope)

        subject.prune!(current_time: current_time)
      end
    end

    context 'by prunable scope' do
      before do
        allow(subject).to receive(:prunable).and_return(prunable)
      end

      it 'resolves removing scope correctly' do
        expect(prunable).to receive(:destroy_all)
        subject.prune!
      end

      context 'with params' do
        it 'calls scope with params' do
          expect(subject).to receive(:prunable)
            .with(:foo, :bar)
            .and_return(double.as_null_object)

          subject.prune!(:foo, :bar)
        end
      end
    end

    context 'prune method has been set' do
      before do
        allow(subject).to receive(:prunable).and_return(prunable)
      end

      it 'removes records by destroy_all method' do
        subject.prune_method(:destroy)
        expect(prunable).to receive(:destroy_all)
        subject.prune!
      end

      it 'removes records by delete_all method' do
        subject.prune_method(:delete)
        expect(prunable).to receive(:delete_all)
        subject.prune!
      end
    end
  end
end
