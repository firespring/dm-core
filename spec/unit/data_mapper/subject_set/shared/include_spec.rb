require_relative '../../../../unit/data_mapper/ordered_set/shared/include_spec'

shared_examples 'DataMapper::SubjectSet#include? when the entry is present' do
  it_should_behave_like 'DataMapper::OrderedSet#include? when the entry is present'
end

shared_examples 'DataMapper::SubjectSet#include? when the entry is not present' do
  it_should_behave_like 'DataMapper::OrderedSet#include? when the entry is not present'
end
