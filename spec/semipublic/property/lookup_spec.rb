require_relative '../../spec_helper'
require 'dm-core/property/lookup'

describe DataMapper::Property::Lookup do
  supported_by :all do
    before :all do
      Object.send(:remove_const, :Foo) if defined?(Foo)
      @klass = Class.new { extend DataMapper::Model }

      module Foo
        class OtherProperty < DataMapper::Property::String; end
      end
    end

    it 'provides access to Property classes' do
      expect(@klass::Serial).to eq DataMapper::Property::Serial
    end

    it 'provides access to Property classes from outside of the Property namespace' do
      expect(@klass::OtherProperty).to be(Foo::OtherProperty)
    end

    it 'does not provide access to unknown Property classes' do
      expect {
        @klass::Bla
      }.to raise_error(NameError)
    end
  end
end
