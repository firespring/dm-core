require_relative '../../../../unit/data_mapper/ordered_set/shared/empty_spec'

shared_examples 'DataMapper::SubjectSet#empty? with no entries in it' do
  it_should_behave_like 'DataMapper::OrderedSet#empty? with no entries in it'
end

shared_examples 'DataMapper::SubjectSet#empty? with entries in it' do
  it_should_behave_like 'DataMapper::OrderedSet#empty? with entries in it'
end
