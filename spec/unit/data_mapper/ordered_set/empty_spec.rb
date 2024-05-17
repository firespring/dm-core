require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/empty_spec'

describe 'DataMapper::OrderedSet#empty?' do
  subject { set.empty? }

  context 'with no entries in it' do
    let(:set) { DataMapper::OrderedSet.new }

    it_behaves_like 'DataMapper::OrderedSet#empty? with no entries in it'
  end

  context 'with entries in it' do
    let(:set)   { DataMapper::OrderedSet.new([ entry ]) }
    let(:entry) { 1                                     }

    it_behaves_like 'DataMapper::OrderedSet#empty? with entries in it'
  end
end
