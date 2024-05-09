require_relative '../../ordered_set/shared/include_spec'

shared_examples 'DataMapper::SubjectSet#include? when the entry is present' do
  it_behaves_like 'DataMapper::OrderedSet#include? when the entry is present'
end

shared_examples 'DataMapper::SubjectSet#include? when the entry is not present' do
  it_behaves_like 'DataMapper::OrderedSet#include? when the entry is not present'
end
