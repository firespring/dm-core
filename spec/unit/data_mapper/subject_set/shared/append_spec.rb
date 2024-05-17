require_relative '../../ordered_set/shared/append_spec'

shared_examples 'DataMapper::SubjectSet#<< when appending a not yet included entry' do
  it_behaves_like 'DataMapper::OrderedSet#<< when appending a not yet included entry'
end

shared_examples 'DataMapper::SubjectSet#<< when updating an entry with the same cache key and the new entry is already included' do
  it_behaves_like 'DataMapper::OrderedSet#<< when updating an already included entry'
end

shared_examples 'DataMapper::SubjectSet#<< when updating an entry with the same cache key and the new entry is not yet included' do
  its(:entries) { is_expected.not_to include(entry1) }
  its(:entries) { is_expected.to include(entry2) }

  it 'inserts the new entry at the old position' do
    subject.entries.index(entry2).is_expected.to eq @old_index
  end
end
