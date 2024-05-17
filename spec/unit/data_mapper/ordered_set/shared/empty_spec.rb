require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#empty? with no entries in it' do
  it { is_expected.to be(true) }
end

shared_examples 'DataMapper::OrderedSet#empty? with entries in it' do
  it { is_expected.to be(false) }
end
