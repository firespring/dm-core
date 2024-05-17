require_relative '../../spec_helper'

describe DataMapper::Property::Boolean do
  before :all do
    @name          = :active
    @type          = described_class
    @value         = true
    @other_value   = false
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'

  describe '#valid?' do
    [ true, false ].each do |value|
      it "returns true when value is #{value.inspect}" do
        expect(@property.valid?(value)).to be(true)
      end
    end

    [ 'true', 'TRUE', '1', 1, 't', 'T', 'false', 'FALSE', '0', 0, 'f', 'F' ].each do |value|
      it "returns false for #{value.inspect}" do
        expect(@property.valid?(value)).to be(false)
      end
    end
  end

  describe '#typecast_to_primitive' do
    [ true, 'true', 'TRUE', '1', 1, 't', 'T' ].each do |value|
      it "returns true when value is #{value.inspect}" do
        expect(@property.typecast(value)).to be(true)
      end
    end

    [ false, 'false', 'FALSE', '0', 0, 'f', 'F' ].each do |value|
      it "returns false when value is #{value.inspect}" do
        expect(@property.typecast(value)).to be(false)
      end
    end

    [ 'string', 2, 1.0, BigDecimal('1.0'), DateTime.now, Time.now, Date.today, Class, Object.new, ].each do |value|
      it "does not typecast value #{value.inspect}" do
        expect(@property.typecast(value)).to equal(value)
      end
    end
  end
end
