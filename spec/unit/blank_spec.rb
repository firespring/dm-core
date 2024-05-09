require_relative '../spec_helper'
require 'dm-core/support/ext/blank'

describe 'DataMapper::Ext.blank?', Object do
  it 'is blank if it is nil' do
    object = Object.new
    class << object
      def nil?; true end
    end
    expect(DataMapper::Ext.blank?(object)).to eq true
  end

  it 'is blank if it is empty' do
    expect(DataMapper::Ext.blank?({})).to eq true
    expect(DataMapper::Ext.blank?([])).to eq true
  end

  it 'is not blank if not nil or empty' do
    expect(DataMapper::Ext.blank?(Object.new)).to eq false
    expect(DataMapper::Ext.blank?([nil])).to eq false
    expect(DataMapper::Ext.blank?({nil => 0})).to eq false
  end
end

describe 'DataMapper::Ext.blank?', Numeric do
  it 'is never be blank' do
    expect(DataMapper::Ext.blank?(1)).to eq false
  end
end

describe 'DataMapper::Ext.blank?', NilClass do
  it 'is always blank' do
    expect(DataMapper::Ext.blank?(nil)).to eq true
  end
end

describe 'DataMapper::Ext.blank?', TrueClass do
  it 'is never blank' do
    expect(DataMapper::Ext.blank?(true)).to eq false
  end
end

describe 'DataMapper::Ext.blank?', FalseClass do
  it 'is always blank' do
    expect(DataMapper::Ext.blank?(false)).to eq true
  end
end

describe 'DataMapper::Ext.blank?', String do
  it 'is blank if empty' do
    expect(DataMapper::Ext.blank?('')).to eq true
  end

  it 'is blank if it only contains whitespace' do
    expect(DataMapper::Ext.blank?(' ')).to eq true
    expect(DataMapper::Ext.blank?(" \r \n \t ")).to eq true
  end

  it 'is not blank if it contains non-whitespace' do
    expect(DataMapper::Ext.blank?(' a ')).to eq false
  end
end

describe 'DataMapper::Ext.blank?', 'object with #blank?' do
  subject { DataMapper::Ext.blank?(object) }

  let(:return_value) { double('Return Value') }
  let(:object) { double('Object', blank?: return_value) }

  it 'returns the object#blank? result if supported' do
    is_expected.to equal(return_value)
  end
end
