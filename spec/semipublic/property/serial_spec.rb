require_relative '../../spec_helper'

describe DataMapper::Property::Serial do
  before :all do
    @name          = :id
    @type          = described_class
    @value         = 1
    @other_value   = 2
    @invalid_value = 'foo'
  end

  it_behaves_like 'A semipublic Property'
end
