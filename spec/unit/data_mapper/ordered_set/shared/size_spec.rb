require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#size when no entry is present' do
  it { is_expected.to eq 0 }
end

shared_examples 'DataMapper::OrderedSet#size when 1 entry is present' do
  it { is_expected.to eq 1 }
end

shared_examples 'DataMapper::OrderedSet#size when more than 1 entry is present' do
  it { is_expected.to eq expected_size }
end
