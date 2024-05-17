require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#index when the entry is not present' do
  it { is_expected.to be(nil) }
end

shared_examples 'DataMapper::OrderedSet#index when 1 entry is present' do
  it { is_expected.to eq 0 }
end

shared_examples 'DataMapper::OrderedSet#index when 2 entries are present' do
  it { is_expected.to eq 1 }
end
