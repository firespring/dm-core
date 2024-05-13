require_relative '../../spec_helper'

describe DataMapper::Property::Binary do
  before :all do
    @name          = :title
    @type          = described_class
    @value         = 'value'
    @other_value   = 'return value'
    @invalid_value = 1
  end

  it_behaves_like 'A semipublic Property'
end
