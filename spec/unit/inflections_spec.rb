require_relative '../spec_helper'
require 'dm-core/support/inflector/inflections'

describe DataMapper::Inflector do
  it "singularizes 'status' correctly" do
    expect(DataMapper::Inflector.singularize('status')).to eql 'status'
    expect(DataMapper::Inflector.singularize('status')).not_to eql 'statu'
  end

  it "singularizes 'alias' correctly" do
    expect(DataMapper::Inflector.singularize('alias')).to eql 'alias'
    expect(DataMapper::Inflector.singularize('alias')).not_to eql 'alia'
  end
end
