require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#include? when the entry is present' do
  it { is_expected.to be(true) }
end

shared_examples 'DataMapper::OrderedSet#include? when the entry is not present' do
  it { is_expected.to be(false) }
end
