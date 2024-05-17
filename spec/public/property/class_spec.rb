require_relative '../../spec_helper'

describe DataMapper::Property::Class do
  before :all do
    Object.send(:remove_const, :Foo) if defined?(Foo)
    Object.send(:remove_const, :Bar) if defined?(Bar)

    class ::Foo; end
    class ::Bar; end

    @name          = :type
    @type          = described_class
    @load_as       = Class
    @value         = Foo
    @other_value   = Bar
    @invalid_value = 1
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as) }
  end
end
