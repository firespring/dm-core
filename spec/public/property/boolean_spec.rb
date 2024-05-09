require_relative '../../spec_helper'

describe DataMapper::Property::Boolean do
  before :all do
    @name          = :active
    @type          = described_class
    @load_as       = TrueClass
    @value         = true
    @other_value   = false
    @invalid_value = 1
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as) }
  end
end
