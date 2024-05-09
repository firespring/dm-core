require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/entries_spec'

describe 'DataMapper::OrderedSet#entries' do
  subject { ordered_set.entries }

  let(:ordered_set) { set }

  context 'with no entries' do
    let(:set) { DataMapper::OrderedSet.new }

    it_behaves_like 'DataMapper::OrderedSet#entries with no entries'
  end

  context 'with entries' do
    let(:set)   { DataMapper::OrderedSet.new([ entry ]) }
    let(:entry) { 1                                     }

    it_behaves_like 'DataMapper::OrderedSet#entries with entries'
  end
end
