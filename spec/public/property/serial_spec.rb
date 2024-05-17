require_relative '../../spec_helper'

describe DataMapper::Property::Serial do
  before :all do
    @name          = :id
    @type          = described_class
    @load_as       = Integer
    @dump_as       = Integer
    @value         = 1
    @other_value   = 2
    @invalid_value = 'foo'
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as, min: 1, serial: true) }
  end
end
