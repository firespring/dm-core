require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#empty? with no entries in it' do
  it { should be(true) }
end

shared_examples 'DataMapper::OrderedSet#empty? with entries in it' do
  it { should be(false) }
end
