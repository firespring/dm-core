require_relative '../../../spec_helper'
require 'dm-core/support/ordered_set'
require_relative 'shared/each_spec'

describe 'DataMapper::OrderedSet' do
  subject { DataMapper::OrderedSet.new }

  it_behaves_like 'DataMapper::OrderedSet'
end

describe 'DataMapper::OrderedSet#each' do
  subject { set.each { |entry| yields << entry } }

  let(:set)    { DataMapper::OrderedSet.new([ entry ]) }
  let(:entry)  { 1                                     }
  let(:yields) { []                                    }

  it_behaves_like 'DataMapper::OrderedSet#each'
end
