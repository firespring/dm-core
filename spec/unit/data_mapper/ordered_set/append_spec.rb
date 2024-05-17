require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/append_spec'

describe 'DataMapper::OrderedSet#<<' do
  subject { set << entry2 }

  let(:set)    { DataMapper::OrderedSet.new([ entry1 ]) }
  let(:entry1) { Object.new                             }

  before do
    @old_index = set.index(entry1)
  end

  context 'when appending a not yet included entry' do
    let(:entry2) { Object.new }

    it_behaves_like 'DataMapper::OrderedSet#<< when appending a not yet included entry'
  end

  context 'when updating an already included entry' do
    let(:entry2) { entry1 }

    it_behaves_like 'DataMapper::OrderedSet#<< when updating an already included entry'
  end
end
