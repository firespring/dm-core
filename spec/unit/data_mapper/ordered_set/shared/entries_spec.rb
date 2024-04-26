require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#entries with no entries' do
  it { should be_empty }
end

shared_examples 'DataMapper::OrderedSet#entries with entries' do
  it { should include(entry) }
end
