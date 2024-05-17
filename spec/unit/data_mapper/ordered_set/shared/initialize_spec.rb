require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#initialize when no entries are given' do
  it { is_expected.to be_empty }

  its(:entries) { is_expected.to be_empty }
  its(:size) { is_expected.to eq 0 }
end

shared_examples 'DataMapper::OrderedSet#initialize when entries are given and they do not contain duplicates' do
  it { is_expected.not_to be_empty }
  it { is_expected.to include(entry1) }
  it { is_expected.to include(entry2) }

  its(:size) { is_expected.to eq 2 }

  it 'retains insertion order' do
    expect(subject.index(entry1)).to eq 0
    expect(subject.index(entry2)).to eq 1
  end
end

shared_examples 'DataMapper::OrderedSet#initialize when entries are given and they contain duplicates' do
  it { is_expected.not_to be_empty }
  it { is_expected.to include(entry1) }

  its(:size) { is_expected.to eq 1 }
end
