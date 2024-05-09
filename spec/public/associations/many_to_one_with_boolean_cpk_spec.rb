require_relative '../../spec_helper'

# TODO: combine this into many_to_one_spec.rb

describe 'Many to One Associations when foreign key is part of a composite key, with an integer and a boolean making up the composite key' do
  before :all do
    class ::ManyModel
      include DataMapper::Resource

      property :integer_key, Integer, :key => true
      property :boolean_key, Boolean, :key => true

      belongs_to :one_model, :child_key => [ :integer_key ]
    end

    class ::OneModel
      include DataMapper::Resource

      property :integer_key, Integer, :key => true

      has n, :many_models, :child_key => [ :integer_key ]
    end
    DataMapper.finalize
  end

  supported_by :all do
    before :all do
      @one  = OneModel.create(:integer_key => 1)
      @many = ManyModel.create(:integer_key => 1, :boolean_key => false)
    end

    it 'is able to access parent' do
      expect(@many.one_model).to eq @one
    end

    it 'is able to access the child' do
      expect(@one.many_models).to eq [@many]
    end
  end
end
