require_relative '../spec_helper'
require 'dm-core/support/mash'

class AwesomeHash < Hash
end

describe DataMapper::Mash do
  before(:each) do
    @hash = { "mash" => "indifferent", :hash => "different" }
    @sub  = AwesomeHash.new("mash" => "indifferent", :hash => "different")
  end

  describe '#initialize' do
    it 'converts all keys into strings when param is a Hash' do
      mash = DataMapper::Mash.new(@hash)

      expect(mash.keys.any? { |key| key.is_a?(Symbol) }).to be(false)
    end

    it 'converts all pure Hash values into Mashes if param is a Hash' do
      mash = DataMapper::Mash.new :hash => @hash

      expect(mash['hash']).to be_an_instance_of(DataMapper::Mash)
      # sanity check
      expect(mash['hash']['hash']).to eq 'different'
    end

      mash = DataMapper::Mash.new :sub => @sub
    it 'does not convert Hash subclass values into Mashes' do
      expect(mash['sub']).to be_an_instance_of(AwesomeHash)
    end

    it 'converts all value items if value is an Array' do
      mash = DataMapper::Mash.new :arry => { :hash => [@hash] }

      expect(mash['arry']).to be_an_instance_of(DataMapper::Mash)
      # sanity check
      expect(mash['arry']['hash'].first['hash']).to eq 'different'
    end

    it 'delegates to superclass constructor if param is not a Hash' do
      mash = DataMapper::Mash.new("dash berlin")

      expect(mash['unexisting key']).to eq 'dash berlin'
    end
  end # describe "#initialize"

  describe '#update' do
    it 'converts all keys into strings when param is a Hash' do
      mash = DataMapper::Mash.new(@hash)
      mash.update("starry" => "night")

      expect(mash.keys.any? { |key| key.is_a?(Symbol) }).to be(false)
    end

    it 'converts all Hash values into Mashes if param is a Hash' do
      mash = DataMapper::Mash.new :hash => @hash
      mash.update(:hash => { :hash => "is buggy in Ruby 1.8.6" })

      expect(mash['hash']).to be_an_instance_of(DataMapper::Mash)
    end
  end # describe "#update"

  describe '#[]=' do
    it 'converts key into string' do
      mash = DataMapper::Mash.new(@hash)
      mash[:hash] = { "starry" => "night" }

      expect(mash.keys.any? { |key| key.is_a?(Symbol) }).to be(false)
    end

    it 'converts all Hash value into Mash' do
      mash = DataMapper::Mash.new :hash => @hash
      mash[:hash] = { :hash => "is buggy in Ruby 1.8.6" }

      expect(mash['hash']).to be_an_instance_of(DataMapper::Mash)
    end
  end # describe "#[]="

  describe '#key?' do
    before(:each) do
      @mash = DataMapper::Mash.new(@hash)
    end

    it 'converts key before lookup' do
      expect(@mash.key?('mash')).to be(true)
      expect(@mash.key?(:mash)).to be(true)

      expect(@mash.key?('hash')).to be(true)
      expect(@mash.key?(:hash)).to be(true)

      expect(@mash.key?(:rainclouds)).to be(false)
      expect(@mash.key?('rainclouds')).to be(false)
    end

    it 'is aliased as include?' do
      expect(@mash.include?('mash')).to be(true)
      expect(@mash.include?(:mash)).to be(true)

      expect(@mash.include?('hash')).to be(true)
      expect(@mash.include?(:hash)).to be(true)

      expect(@mash.include?(:rainclouds)).to be(false)
      expect(@mash.include?('rainclouds')).to be(false)
    end

    it 'is aliased as member?' do
      expect(@mash.member?('mash')).to be(true)
      expect(@mash.member?(:mash)).to be(true)

      expect(@mash.member?('hash')).to be(true)
      expect(@mash.member?(:hash)).to be(true)

      expect(@mash.member?(:rainclouds)).to be(false)
      expect(@mash.member?('rainclouds')).to be(false)
    end
  end

  describe '#dup' do
    it 'returns instance of Mash' do
      expect(DataMapper::Mash.new(@hash).dup).to be_an_instance_of(DataMapper::Mash)
    end

    it 'preserves keys' do
      mash = DataMapper::Mash.new(@hash)
      dup  = mash.dup

      expect(mash.keys.sort).to eq dup.keys.sort
    end

    it 'preserves value' do
      mash = DataMapper::Mash.new(@hash)
      dup  = mash.dup

      expect(mash.values.sort).to eq dup.values.sort
    end
  end

  describe '#to_hash' do
    it 'returns instance of Mash' do
      expect(DataMapper::Mash.new(@hash).to_hash).to be_an_instance_of(Hash)
    end

    it 'preserves keys' do
      mash = DataMapper::Mash.new(@hash)
      converted  = mash.to_hash

      expect(mash.keys.sort).to eq converted.keys.sort
    end

    it 'preserves value' do
      mash = DataMapper::Mash.new(@hash)
      converted = mash.to_hash

      expect(mash.values.sort).to eq converted.values.sort
    end
  end

  describe '#symbolize_keys' do
    it 'returns instance of Mash' do
      expect(DataMapper::Mash.new(@hash).symbolize_keys).to be_an_instance_of(Hash)
    end

    it 'converts keys to symbols' do
      mash = DataMapper::Mash.new(@hash)
      converted  = mash.symbolize_keys

      converted_keys = converted.keys.sort{|k1, k2| k1.to_s <=> k2.to_s}
      orig_keys = mash.keys.map{|k| k.to_sym}.sort{|i1, i2| i1.to_s <=> i2.to_s}

      expect(converted_keys).to eq orig_keys
    end

    it 'preserves value' do
      mash = DataMapper::Mash.new(@hash)
      converted = mash.symbolize_keys

      expect(mash.values.sort).to eq converted.values.sort
    end
  end

  describe '#delete' do
    it 'converts Symbol key into String before deleting' do
      mash = DataMapper::Mash.new(@hash)

      mash.delete(:hash)
      expect(mash.key?('hash')).to be(false)
    end

    it 'works with String keys as well' do
      mash = DataMapper::Mash.new(@hash)

      mash.delete("mash")
      expect(mash.key?('mash')).to be(false)
    end
  end

  describe '#except' do
    it 'converts Symbol key into String before calling super' do
      mash = DataMapper::Mash.new(@hash)

      hashless_mash = mash.except(:hash)
      expect(hashless_mash.key?('hash')).to be(false)
    end

    it 'works with String keys as well' do
      mash = DataMapper::Mash.new(@hash)

      mashless_mash = mash.except("mash")
      expect(mashless_mash.key?('mash')).to be(false)
    end

    it 'works with multiple keys' do
      mash = DataMapper::Mash.new(@hash)

      mashless = mash.except("hash", :mash)
      expect(mashless.key?(:hash)).to be(false)
      expect(mashless.key?('mash')).to be(false)
    end

    it 'returns a mash' do
      mash = DataMapper::Mash.new(@hash)

      hashless_mash = mash.except(:hash)
      expect(hashless_mash.class).to be(DataMapper::Mash)
    end
  end

  describe '#merge' do
    before(:each) do
      @mash = DataMapper::Mash.new(@hash).merge(:no => "in between")
    end

    it 'returns instance of Mash' do
      expect(@mash).to be_an_instance_of(DataMapper::Mash)
    end

    it 'merges in give Hash' do
      expect(@mash['no']).to eq 'in between'
    end
  end

  describe '#fetch' do
    before(:each) do
      @mash = DataMapper::Mash.new(@hash).merge(:no => "in between")
    end

    it 'converts key before fetching' do
      expect(@mash.fetch('no')).to eq 'in between'
    end

    it 'returns alternative value if key lookup fails' do
      expect(@mash.fetch('flying', 'screwdriver')).to eq 'screwdriver'
    end
  end

  describe '#default' do
    before(:each) do
      @mash = DataMapper::Mash.new(:yet_another_technical_revolution)
    end

    it 'returns default value unless key exists in mash' do
      expect(@mash.default('peak oil is now behind, baby')).to eq :yet_another_technical_revolution
    end

    it 'returns existing value if key is Symbol and exists in mash' do
      @mash.update(:no => "in between")
      expect(@mash.default(:no)).to eq 'in between'
    end
  end

  describe '#values_at' do
    before(:each) do
      @mash = DataMapper::Mash.new(@hash).merge(:no => "in between")
    end

    it 'is indifferent to whether keys are strings or symbols' do
      expect(@mash.values_at('hash', :mash, :no)).to eq ['different', 'indifferent', 'in between']
    end
  end

  describe '#stringify_keys!' do
    it 'returns the mash itself' do
      mash = DataMapper::Mash.new(@hash)

      expect(mash.stringify_keys!.object_id).to eq mash.object_id
    end
  end
end
