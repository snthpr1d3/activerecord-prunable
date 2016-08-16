require 'spec_helper'

describe Prunable do
  describe ".models" do
    it "call rails force load classes when first call" do
      expect(Rails.application).to receive(:eager_load!)
      described_class.models
    end

    it "find all mixed classes" do
      expect(described_class.models).to contain_exactly(SomeMixin, AnotherMixin)
    end
  end

  describe ".prune!" do
    let(:remove_result){ double(any?: true, size: :size) }
    let(:scope){ double(present?: true, destroy_all: remove_result, delete_all: remove_result) }
    let(:logger){ Logger }

    before do
      allow(SomeMixin).to receive(:logger).and_return(logger)
      allow(AnotherMixin).to receive(:logger).and_return(logger)
      allow(ActiveRecord::Base).to receive(:prunable).and_return(scope)
    end

    it "don't call rails force load classes when another call" do
      expect(Rails.application).not_to receive(:eager_load!)
      described_class.prune!
    end

    it "call prune! for mixed classes" do
      expect(SomeMixin).to receive(:prune!)
      expect(AnotherMixin).to receive(:prune!)
      described_class.prune!
    end

    it "call prune! only for selected classes" do
      expect(SomeMixin).to receive(:prune!)
      expect(AnotherMixin).not_to receive(:prune!)
      described_class.prune!(SomeMixin)
    end

    context "default remove method" do
      let(:some_mixin_prunable){ double }
      let(:another_mixin_prunable){ double }

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

      it "call delete_all by defaults if not set :destroy" do
        SomeMixin.prune_method :destroy
        expect(some_mixin_prunable).to receive(:destroy_all).and_return([])
        expect(another_mixin_prunable).to receive(:delete_all).and_return(0)
        described_class.prune!(prune_method: :delete)
      end

      it "call destroy_all by defaults if not set :delete" do
        SomeMixin.prune_method :delete
        expect(some_mixin_prunable).to receive(:delete_all).and_return(0)
        expect(another_mixin_prunable).to receive(:destroy_all).and_return([])
        described_class.prune!(prune_method: :destroy)
      end

      it "call destroy_all by defaults if not set another" do
        expect(some_mixin_prunable).to receive(:destroy_all).and_return([])
        expect(another_mixin_prunable).to receive(:destroy_all).and_return([])
        described_class.prune!
      end
    end

    it "call scope with params" do
      expect(SomeMixin).to receive(:prunable).with(:foo, :bar)
      expect(AnotherMixin ).to receive(:prunable).with(:foo, :bar)
      described_class.prune!(params: [:foo, :bar])
    end
  end
end
