require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/delete_spec'

describe 'DataMapper::OrderedSet#delete' do
  subject { ordered_set }

  let(:ordered_set) { DataMapper::OrderedSet.new([ entry1, entry2, entry3 ]) }
  let(:entry1)      { 1                                                      }
  let(:entry2)      { 2                                                      }
  let(:entry3)      { 3                                                      }

  before do
    ordered_set.delete(entry)
  end

  context 'when deleting an already included entry' do
    let(:entry) { entry1 }

    it_behaves_like 'DataMapper::OrderedSet#delete when deleting an already included entry'
  end

  context 'when deleting a not yet included entry' do
    let(:entry) { 4 }

    it_behaves_like 'DataMapper::OrderedSet#delete when deleting a not yet included entry'
  end
end
