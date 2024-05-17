require_relative '../../ordered_set/shared/entries_spec'

shared_examples 'DataMapper::SubjectSet#entries with no entries' do
  it_behaves_like 'DataMapper::OrderedSet#entries with no entries'
end

shared_examples 'DataMapper::SubjectSet#entries with entries' do
  it_behaves_like 'DataMapper::OrderedSet#entries with entries'
end
