require_relative '../../spec_helper'

describe DataMapper::Property::String do
  before :all do
    @name          = :name
    @type          = described_class
    @load_as       = String
    @value         = 'value'
    @other_value   = 'return value'
    @invalid_value = 1
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as, length: 50) }
  end
end
