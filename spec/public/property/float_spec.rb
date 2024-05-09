require_relative '../../spec_helper'

describe DataMapper::Property::Float do
  before :all do
    @name          = :rating
    @type          = described_class
    @load_as       = Float
    @dump_as       = String
    @value         = 0.1
    @other_value   = 0.2
    @invalid_value = '1'
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as, precision: 10, scale: nil) }
  end
end
