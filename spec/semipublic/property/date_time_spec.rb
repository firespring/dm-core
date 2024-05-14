require_relative '../../spec_helper'

describe DataMapper::Property::DateTime do
  before :all do
    @name          = :created_at
    @type          = described_class
    @value         = DateTime.now
    @other_value   = DateTime.now + 15
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'

  describe '#typecast_to_primitive' do
    describe 'and value given as a hash with keys like :year, :month, etc' do
      it 'builds a DateTime instance from hash values' do
        result = @property.typecast(
          'year'  => '2006',
          'month' => '11',
          'day'   => '23',
          'hour'  => '12',
          'min'   => '0',
          'sec'   => '0'
        )

        expect(result).to be_kind_of(DateTime)
        expect(result.year).to eql(2006)
        expect(result.month).to eql(11)
        expect(result.day).to eql(23)
        expect(result.hour).to eql(12)
        expect(result.min).to eql(0)
        expect(result.sec).to eql(0)
      end
    end

    describe 'and value is a string' do
      it 'parses the string' do
        expect(@property.typecast('Dec, 2006').month).to eq 12
      end
    end

    it 'does not typecast non-datetime values' do
      expect(@property.typecast('not-datetime')).to eql('not-datetime')
    end
  end
end
