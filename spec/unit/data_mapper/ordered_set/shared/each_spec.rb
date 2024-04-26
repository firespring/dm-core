require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet' do
  it { should be_kind_of(Enumerable) }

  it 'case matches Enumerable' do
    subject.is_a?(Enumerable).should be(true)
  end
end

shared_examples 'DataMapper::OrderedSet#each' do
  it { should equal(set) }

  it 'yields each column' do
    expect { subject }.to change { yields.dup }.from([]).to([ entry ])
  end
end
