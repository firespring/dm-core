require_relative '../../spec_helper'

# TODO: combine this into many_to_one_spec.rb

describe 'Many to One Associations when foreign key is a property subclass' do
  before :all do
    class ::CustomPK < DataMapper::Property::String
      key true
    end

    class ::Animal
      include DataMapper::Resource

      property :id,   Serial
      property :name, String

      belongs_to :zoo
    end

    class ::Zoo
      include DataMapper::Resource

      property :id, ::CustomPK

      has n, :animals
    end

    DataMapper.finalize
  end

  supported_by :all do
    before :all do
      @zoo    = Zoo.create(:id => 'foo')
      @animal = @zoo.animals.create(:name => 'marty')
    end

    it 'has FK of the same property type as zoo PK' do
      expect(Animal.properties[:zoo_id].class).to be(Zoo.properties[:id].class)
    end

    it 'is able to access parent' do
      expect(@animal.zoo).to eq @zoo
    end

    it 'is able to access the children' do
      expect(@zoo.animals).to eq [@animal]
    end
  end
end
