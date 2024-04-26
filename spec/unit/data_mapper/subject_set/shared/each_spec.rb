require_relative '../../../../unit/data_mapper/ordered_set/shared/each_spec'

shared_examples 'DataMapper::SubjectSet' do
  it_should_behave_like 'DataMapper::OrderedSet'
end

shared_examples 'DataMapper::SubjectSet#each' do
  it_should_behave_like 'DataMapper::OrderedSet#each'
end
