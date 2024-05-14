require_relative '../../spec_helper'

describe 'AbstractAdapter' do
  before :all do
    @adapter = DataMapper::Adapters::AbstractAdapter.new(:abstract, :foo => 'bar')
    @adapter_class = @adapter.class
    @scheme        = DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(@adapter_class).chomp('Adapter'))
    @adapter_name  = "test_#{@scheme}".to_sym
  end

  describe 'initialization' do

    describe 'name' do
      it 'has a name' do
        expect(@adapter.name).to eq :abstract
      end
    end

    it 'sets options' do
      expect(@adapter.options).to eq({foo: 'bar'})
    end

    it 'sets naming conventions' do
      expect(@adapter.resource_naming_convention).to eq DataMapper::NamingConventions::Resource::UnderscoredAndPluralized
      expect(@adapter.field_naming_convention).to eq DataMapper::NamingConventions::Field::Underscored
    end

  end

end
