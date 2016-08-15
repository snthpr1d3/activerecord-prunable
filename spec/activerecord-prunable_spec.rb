require 'spec_helper'

describe Prunable do
  describe "models" do
    it "call rails force load classes when first call" do
      expect(Rails.application).to receive(:eager_load!)
      described_class.models
    end

    it "find all mixed classes" do
      expect(described_class.models).to contain_exactly(SomeMixin, AnotherMixin)
    end
  end

  context "removal" do
    let(:remove_result){ double(any?: true, size: :size) }
    let(:scope){ double(present?: true, destroy_all: remove_result, delete_all: remove_result) }
    let(:logger){ Logger }

    before do
      allow(SomeMixin).to receive(:logger).and_return(logger)
      allow(AnotherMixin).to receive(:logger).and_return(logger)
      allow(ActiveRecord::Base).to receive(:prunable).and_return(scope)
    end

    describe "prune!" do
      after do
        described_class.prune!
      end

      it "don't call rails force load classes when another call" do
        expect(Rails.application).not_to receive(:eager_load!)
      end

      it "call prune! for mixed classes" do
        expect(SomeMixin).to receive(:prune!)
        expect(AnotherMixin).to receive(:prune!)
      end
    end

    describe "prune_models!" do
      it "call prune! only for models in array" do
        expect(SomeMixin).to receive(:prune!)
        expect(AnotherMixin).not_to receive(:prune!)
        described_class.prune!(SomeMixin)
      end
    end
  end
end
