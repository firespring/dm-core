require_relative '../../spec_helper'

describe DataMapper::Property::Class do
  before :all do
    Object.send(:remove_const, :Foo) if defined?(Foo)
    Object.send(:remove_const, :Bar) if defined?(Bar)

    class ::Foo; end
    class ::Bar; end

    @name          = :type
    @type          = described_class
    @value         = Foo
    @other_value   = Bar
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'

  describe '#typecast_to_primitive' do
    it 'returns same value if a class' do
      expect(@property.typecast(@model)).to equal(@model)
    end

    it 'returns the class if found' do
      expect(@property.typecast(@model.name)).to eql(@model)
    end

    it 'does not typecast non-class values' do
      expect(@property.typecast('NoClass')).to eql('NoClass')
    end
  end
end
