require_relative '../../ordered_set/shared/each_spec'

shared_examples 'DataMapper::SubjectSet' do
  it_behaves_like 'DataMapper::OrderedSet'
end

shared_examples 'DataMapper::SubjectSet#each' do
  it_behaves_like 'DataMapper::OrderedSet#each'
end
