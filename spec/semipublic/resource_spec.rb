require_relative '../spec_helper'

describe DataMapper::Resource do
  before :all do
    class ::User
      include DataMapper::Resource

      property :name,        String, :key => true
      property :age,         Integer
      property :description, Text
    end

    @user_model = User
  end

  supported_by :all do
    before :all do
      @user = @user_model.create(:name => 'dbussink', :age => 25, :description => "Test")
    end

    it_behaves_like 'A semipublic Resource'
  end
end
