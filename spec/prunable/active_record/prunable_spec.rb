require 'spec_helper'

describe ActiveRecord::Prunable do
  subject{ SomeMixin }

  describe "includes" do
    it "has array with all prunable models" do
      expect(described_class.includes).to contain_exactly(SomeMixin, AnotherMixin)
    end
  end

  describe "prune!" do
    before do
      allow(subject).to receive(:logger).and_return(logger)
    end

    let(:correct_scope){ ->(){ ActiveRecord::Relation.new(FakeActiveRecord, FakeActiveRecord.arel_table) } }
    let(:incorrect_scope){ ->(){ 123 } }
    let(:logger){ Logger }

    context "when scope is empty" do
      it "raise error when scope result is not ActiveRecord::Relation" do
        expect(subject.respond_to?(:prunable)).to eq(false)
        expect_any_instance_of(ActiveRecord::Relation).not_to receive(:present?)
        expect_any_instance_of(ActiveRecord::Relation).not_to receive(:destroy_all)
        expect{ subject.prune! }.not_to raise_error
      end
    end

    context "when scope is correct" do
      before do
        subject.scope(:prunable, correct_scope)
      end

      it "call destroy_all if scope not empty" do
        allow_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all).and_return([:some_result])
        allow_any_instance_of(ActiveRecord::Relation).to receive(:present?).and_return(true)
        expect_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all)
        expect(subject.prune!).to eq([:some_result])
      end

      it "if scope empty" do
        allow_any_instance_of(ActiveRecord::Relation).to receive(:present?).and_return(false)
        allow_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all).and_return([])
        expect(subject.prune!).to eq([])
      end
    end

    context "when scope is incorrect" do
      it "return nil" do
        subject.scope(:prunable, incorrect_scope)
        expect(subject.prune!).to be_nil
      end
    end
  end
end
