require_relative '../../../../spec_helper'

shared_examples 'DataMapper::SubjectSet#[] when the entry with the given name is not present' do
  it { is_expected.to be_nil }
end

shared_examples 'DataMapper::SubjectSet#[] when the entry with the given name is present' do
  it { is_expected.to eq entry }
end
