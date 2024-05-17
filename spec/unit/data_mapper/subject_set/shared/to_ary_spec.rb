require_relative '../../ordered_set/shared/to_ary_spec'

shared_examples 'DataMapper::SubjectSet#to_ary when no entries are present' do
  it_behaves_like 'DataMapper::OrderedSet#to_ary when no entries are present'
end

shared_examples 'DataMapper::SubjectSet#to_ary when entries are present' do
  it_behaves_like 'DataMapper::OrderedSet#to_ary when entries are present'
end
