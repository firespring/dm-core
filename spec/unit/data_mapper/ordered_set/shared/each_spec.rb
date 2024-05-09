require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet' do
  it { is_expected.to be_kind_of(Enumerable) }

  it 'case matches Enumerable' do
    expect(subject.is_a?(Enumerable)).to be(true)
  end
end

shared_examples 'DataMapper::OrderedSet#each' do
  it { is_expected.to equal(set) }

  it 'yields each column' do
    expect { subject }.to change { yields.dup }.from([]).to([entry])
  end
end
