require_relative '../spec_helper'
require 'dm-core/support/ext/try_dup'

describe 'try_dup' do
  it 'returns a duplicate version on regular objects' do
    obj = Object.new
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).not_to eq oth
  end

  it 'returns self on Numerics' do
    obj = 12
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).to eq oth
  end

  it 'returns self on Symbols' do
    obj = :test
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).to eq oth
  end

  it 'returns self on true' do
    obj = true
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).to eq oth
  end

  it 'returns self on false' do
    obj = false
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).to eq oth
  end

  it 'returns self on nil' do
    obj = nil
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj).to eq oth
  end

  it 'returns self on modules' do
    obj = Module.new
    oth = DataMapper::Ext.try_dup(obj)
    expect(obj.object_id).to eq oth.object_id
  end
end
