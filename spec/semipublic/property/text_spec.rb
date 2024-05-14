require_relative '../../spec_helper'

describe DataMapper::Property::Text do
  before :all do
    @name          = :title
    @type          = described_class
    @value         = 'value'
    @other_value   = 'return value'
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'

  describe '#load' do
    before :all do
      @value = double('value')
    end

    subject { @property.load(@value) }

    before do
      @property = @type.new(@model, @name)
    end

    it 'delegates to #type.load' do
      return_value = double('return value')
      expect(@property).to receive(:load).with(@value).and_return(return_value)
      is_expected.to eq return_value
    end
  end
end
