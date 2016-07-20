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
    let(:logger){ Logger }

    before do
      allow(SomeMixin).to receive(:logger).and_return(logger)
      allow(AnotherMixin).to receive(:logger).and_return(logger)
      allow_any_instance_of(ActiveRecord::Relation).to receive(:present?).and_return(true)
      allow_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all).and_return(:some_result)
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
