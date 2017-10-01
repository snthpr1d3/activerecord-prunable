# frozen_string_literal: true

require 'spec_helper'

describe Prunable do
  describe '.models' do
    it 'gets rails to load classes forcely fot the first time' do
      expect(Rails.application).to receive(:eager_load!)
      described_class.models
    end

    it 'finds all mixed classes' do
      expect(described_class.models).to contain_exactly(SomeMixin, AnotherMixin)
    end
  end

  describe '.prune!' do
    let(:remove_result) { double(any?: true, size: 0) }
    let(:scope) { double(present?: true, destroy_all: remove_result, delete_all: remove_result) }
    let(:logger) { Logger }

    before do
      allow(SomeMixin).to receive(:logger).and_return(logger)
      allow(AnotherMixin).to receive(:logger).and_return(logger)
      allow(ActiveRecord::Base).to receive(:prunable).and_return(scope)
    end

    it "doesn't call rails force load classes when another call" do
      expect(Rails.application).not_to receive(:eager_load!)
      described_class.prune!
    end

    it 'calls prune! for mixed classes' do
      expect(SomeMixin).to receive(:prune!)
      expect(AnotherMixin).to receive(:prune!)
      described_class.prune!
    end

    it 'calls prune! only for selected classes' do
      expect(SomeMixin).to receive(:prune!)
      expect(AnotherMixin).not_to receive(:prune!)
      described_class.prune!(SomeMixin)
    end

    context 'default remove method' do
      let(:some_mixin_prunable) { double }
      let(:another_mixin_prunable) { double }

      before do
        allow(SomeMixin).to receive(:prunable).and_return(some_mixin_prunable)
        allow(AnotherMixin).to receive(:prunable).and_return(another_mixin_prunable)
        allow(SomeMixin).to receive(:check_scope).and_return(true)
        allow(AnotherMixin).to receive(:check_scope).and_return(true)

        if SomeMixin.class_variable_defined?(:@@prune_method)
          SomeMixin.remove_class_variable(:@@prune_method)
        end

        if AnotherMixin.class_variable_defined?(:@@prune_method)
          AnotherMixin.remove_class_variable(:@@prune_method)
        end
      end

      it "calls delete_all by default if :destroy isn't set" do
        SomeMixin.prune_method :destroy
        expect(some_mixin_prunable).to receive(:destroy_all).and_return([])
        expect(another_mixin_prunable).to receive(:delete_all).and_return(0)
        described_class.prune!(prune_method: :delete)
      end

      it "calls destroy_all by default if :delete isn't set" do
        SomeMixin.prune_method :delete
        expect(some_mixin_prunable).to receive(:delete_all).and_return(0)
        expect(another_mixin_prunable).to receive(:destroy_all).and_return([])
        described_class.prune!(prune_method: :destroy)
      end

      it "calls destroy_all by default if another isn't set" do
        expect(some_mixin_prunable).to receive(:destroy_all).and_return([])
        expect(another_mixin_prunable).to receive(:destroy_all).and_return([])
        described_class.prune!
      end
    end

    it 'calls scope with params' do
      expect(SomeMixin).to receive(:prunable).with(:foo, :bar).and_return(double.as_null_object)
      expect(AnotherMixin ).to receive(:prunable).with(:foo, :bar).and_return(double.as_null_object)
      described_class.prune!(params: [:foo, :bar])
    end
  end
end
