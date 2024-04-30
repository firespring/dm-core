require_relative '../../../../spec_helper'

shared_examples 'DataMapper::OrderedSet#merge when merging two empty sets' do
  it { is_expected.to be_instance_of(set.class) }
  it { is_expected.to equal(set)                }
  it { is_expected.to == set                    }
end

shared_examples 'DataMapper::OrderedSet#merge when merging a set with already present entries' do
  it { is_expected.to equal(set)     }
  it { is_expected.to == set         }
  it { is_expected.to include(entry) }

  it 'does not add an entry to the set' do
    expect { subject }.to_not change { set.size }
  end
end

shared_examples 'DataMapper::OrderedSet#merge when merging a set with not yet present entries' do
  it { is_expected.to equal(set)      }
  it { is_expected.not_to == set          }
  it { is_expected.to include(entry1) }
  it { is_expected.to include(entry2) }

  it 'adds an entry to the set' do
    expect { subject }.to change { set.size }.from(1).to(2)
  end
end
