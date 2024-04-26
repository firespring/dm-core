require_relative '../../../../spec_helper'

shared_examples 'DataMapper::SubjectSet#named? when no entry with the given name is present' do
  it { should be(false) }
end

shared_examples 'DataMapper::SubjectSet#named? when an entry with the given name is present' do
  it { should be(true) }
end
