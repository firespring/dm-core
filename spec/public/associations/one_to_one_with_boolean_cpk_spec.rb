require_relative '../../spec_helper'

# TODO: combine this into one_to_one_spec.rb

describe 'One to One Associations when foreign key is part of a composite key and contains a boolean, with an integer and a boolean making up the composite key' do
  before :all do
    class ::ParentModel
      include DataMapper::Resource

      property :integer_key, Integer, :key => true
      property :boolean_key, Boolean, :key => true

      has 1, :child_model, :child_key => [ :integer_key, :boolean_key ]
    end

    class ::ChildModel
      include DataMapper::Resource

      property :integer_key,       Integer, :key => true
      property :other_integer_key, Integer, :key => true
      property :boolean_key,       Boolean, :key => true

      belongs_to :parent_model, :child_key => [ :integer_key, :boolean_key ]
    end
    DataMapper.finalize
  end

  supported_by :all do
    before :all do
      @parent = ParentModel.create(:integer_key => 1, :boolean_key => false)
      @child  = ChildModel.create(:integer_key => 1, :other_integer_key => 1, :boolean_key => false)
    end

    it 'is able to access the child' do
      expect(@parent.child_model).to eq @child
    end

    it 'is able to access the parent' do
      expect(@child.parent_model).to eq @parent
    end

    it 'is able to access the parent_key' do
      expect(@child.parent_model.key).not_to be_nil
    end
  end
end
