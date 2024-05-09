require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#delete when deleting an already included entry' do
  its(:entries) { is_expected.not_to include(entry1) }
  its(:entries) { is_expected.to include(entry2) }
  its(:entries) { is_expected.to include(entry3) }

  it 'corrects the index' do
    expect(ordered_set.index(entry1)).to be_nil
    expect(ordered_set.index(entry2)).to eq 0
    expect(ordered_set.index(entry3)).to eq 1
  end
end

shared_examples 'DataMapper::OrderedSet#delete when deleting a not yet included entry' do
  its(:entries) { is_expected.to include(entry1) }
  its(:entries) { is_expected.to include(entry2) }
  its(:entries) { is_expected.to include(entry3) }

  it 'does not alter the index' do
    expect(ordered_set.index(entry1)).to eq 0
    expect(ordered_set.index(entry2)).to eq 1
    expect(ordered_set.index(entry3)).to eq 2
  end
end
