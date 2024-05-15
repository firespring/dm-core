require_relative '../../spec_helper'

describe DataMapper::Property::Decimal do
  before :all do
    @name          = :rate
    @type          = described_class
    @options       = { :precision => 5, :scale => 2 }
    @value         = BigDecimal('1.0')
    @other_value   = BigDecimal('2.0')
    @invalid_value = true
  end

  it_behaves_like 'A semipublic Property'

  describe '#typecast_to_primitive' do
    it 'returns same value if a decimal' do
      @value = BigDecimal('24.0')
      expect(@property.typecast(@value)).to equal(@value)
    end

    it 'returns decimal representation of a zero string integer' do
      expect(@property.typecast('0')).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string integer' do
      expect(@property.typecast('24')).to eql(BigDecimal('24.0'))
    end

    it 'returns decimal representation of a negative string integer' do
      expect(@property.typecast('-24')).to eql(BigDecimal('-24.0'))
    end

    it 'returns decimal representation of a zero string float' do
      expect(@property.typecast('0.0')).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string float' do
      expect(@property.typecast('24.35')).to eql(BigDecimal('24.35'))
    end

    it 'returns decimal representation of a negative string float' do
      expect(@property.typecast('-24.35')).to eql(BigDecimal('-24.35'))
    end

    it 'returns decimal representation of a zero string float, with no leading digits' do
      expect(@property.typecast('.0')).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string float, with no leading digits' do
      expect(@property.typecast('.41')).to eql(BigDecimal('0.41'))
    end

    it 'returns decimal representation of a zero integer' do
      expect(@property.typecast(0)).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive integer' do
      expect(@property.typecast(24)).to eql(BigDecimal('24.0'))
    end

    it 'returns decimal representation of a negative integer' do
      expect(@property.typecast(-24)).to eql(BigDecimal('-24.0'))
    end

    it 'returns decimal representation of a zero float' do
      expect(@property.typecast(0.0)).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive float' do
      expect(@property.typecast(24.35)).to eql(BigDecimal('24.35'))
    end

    it 'returns decimal representation of a negative float' do
      expect(@property.typecast(-24.35)).to eql(BigDecimal('-24.35'))
    end

    [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
      it "does not typecast non-numeric value #{value.inspect}" do
        expect(@property.typecast(value)).to equal(value)
      end
    end
  end
end
