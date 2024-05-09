require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/to_ary_spec'

describe 'DataMapper::OrderedSet#to_ary' do
  subject { ordered_set.to_ary }

  let(:ordered_set) { DataMapper::OrderedSet.new(entries) }
  let(:entry1) { 1 }
  let(:entry2) { 2 }

  context 'when no entries are present' do
    let(:entries) { [] }

    it_behaves_like 'DataMapper::OrderedSet#to_ary when no entries are present'
  end

  context 'when entries are present' do
    let(:entries) { [ entry1, entry2 ] }

    it_behaves_like 'DataMapper::OrderedSet#to_ary when entries are present'
  end
end
