require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#to_ary when no entries are present' do
  it { is_expected.to be_empty   }
  it { is_expected.to eq entries }
end

shared_examples 'DataMapper::OrderedSet#to_ary when entries are present' do
  it { is_expected.not_to be_empty }
  it { is_expected.to eq entries   }
end
