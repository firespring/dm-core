require_relative '../spec_helper'
require 'dm-core/support/ext/hash'
require 'dm-core/support/mash'

describe DataMapper::Ext::Hash, "only" do
  before do
    @hash = { :one => 'ONE', 'two' => 'TWO', 3 => 'THREE', 4 => nil }
  end

  it 'returns a hash with only the given key(s)' do
    expect(DataMapper::Ext::Hash.only(@hash, :not_in_there)).to eq({})
    expect(DataMapper::Ext::Hash.only(@hash, 4)).to eq({4 => nil})
    expect(DataMapper::Ext::Hash.only(@hash, :one)).to eq({ one: 'ONE' })
    expect(DataMapper::Ext::Hash.only(@hash, :one, 3)).to eq({one: 'ONE', 3 => 'THREE'})
  end
end

describe Hash, 'to_mash' do
  before do
    @hash = Hash.new(10)
  end

  it 'copies default Hash value to Mash' do
    @mash = DataMapper::Ext::Hash.to_mash(@hash)
    expect(@mash[:merb]).to eq 10
  end
end
