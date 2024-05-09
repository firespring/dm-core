require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#<< when appending a not yet included entry' do
  its(:size) { is_expected.to eq 2 }
  its(:entries) { is_expected.to include(entry1) }
  its(:entries) { is_expected.to include(entry2) }

  it 'does not alter the position of the existing entry' do
    expect(subject.entries.index(entry1)).to eq @old_index
  end

  it 'appends columns at the end of the set' do
    expect(subject.entries.index(entry2)).to eq @old_index + 1
  end
end

shared_examples 'DataMapper::OrderedSet#<< when updating an already included entry' do
  its(:size) { is_expected.to eq 1 }
  its(:entries) { is_expected.to include(entry2) }

  it 'does not alter the position of the existing entry' do
    expect(subject.entries.index(entry2)).to eq @old_index
  end
end
