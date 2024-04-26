require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#clear when no entries are present' do
  it { should be_empty }
end

shared_examples 'DataMapper::OrderedSet#clear when entries are present' do
  it { should be_empty }
end
