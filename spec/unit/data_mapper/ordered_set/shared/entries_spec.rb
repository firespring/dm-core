require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#entries with no entries' do
  it { is_expected.to be_empty }
end

shared_examples 'DataMapper::OrderedSet#entries with entries' do
  it { is_expected.to include(entry) }
end
