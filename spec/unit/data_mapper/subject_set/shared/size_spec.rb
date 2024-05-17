require_relative '../../ordered_set/shared/size_spec'

shared_examples 'DataMapper::SubjectSet#size when no entry is present' do
  it_behaves_like 'DataMapper::OrderedSet#size when no entry is present'
end

shared_examples 'DataMapper::SubjectSet#size when 1 entry is present' do
  it_behaves_like 'DataMapper::OrderedSet#size when 1 entry is present'
end

shared_examples 'DataMapper::SubjectSet#size when more than 1 entry is present' do
  it_behaves_like 'DataMapper::OrderedSet#size when more than 1 entry is present'
end
