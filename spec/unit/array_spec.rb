require_relative '../spec_helper'
require 'dm-core/support/ext/array'
require 'dm-core/support/mash'

describe DataMapper::Ext::Array do
  before :all do
    @array = [ [ :a, [ 1 ] ], [ :b, [ 2 ] ], [ :c, [ 3 ] ] ].freeze
  end

  describe '.to_mash' do
    before :all do
      @return = DataMapper::Ext::Array.to_mash(@array)
    end

    it 'returns a Mash' do
      expect(@return).to be_kind_of(DataMapper::Mash)
    end

    it 'returns expected value' do
      expect(@return).to eq({'a' => [1], 'b' => [2], 'c' => [3]})
    end
  end
end
