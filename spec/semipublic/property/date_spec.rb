require_relative '../../spec_helper'

describe DataMapper::Property::Date do
  before :all do
    @name          = :created_on
    @type          = described_class
    @value         = Date.today
    @other_value   = Date.today + 1
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'

  describe '#typecast_to_primitive' do
    describe 'and value given as a hash with keys like :year, :month, etc' do
      it 'builds a Date instance from hash values' do
        result = @property.typecast(
          'year'  => '2007',
          'month' => '3',
          'day'   => '25'
        )

        expect(result).to be_kind_of(Date)
        expect(result.year).to eql(2007)
        expect(result.month).to eql(3)
        expect(result.day).to eql(25)
      end
    end

    describe 'and value is a string' do
      it 'parses the string' do
        result = @property.typecast('Dec 20th, 2006')
        expect(result.month).to eq 12
        expect(result.day).to eq 20
        expect(result.year).to eq 2006
      end
    end

    it 'does not typecast non-date values' do
      expect(@property.typecast('not-date')).to eql('not-date')
    end
  end
end
