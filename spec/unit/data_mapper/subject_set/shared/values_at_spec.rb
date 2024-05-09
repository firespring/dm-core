require_relative '../../../../spec_helper'

shared_examples 'DataMapper::SubjectSet#values_at when one name is given and no entry with the given name is present' do
  its(:size) { is_expected.to eq given_names.size }

  it 'contains nil values for the names not found' do
    expect(subject.compact).to be_empty
  end
end

shared_examples 'DataMapper::SubjectSet#values_at when one name is given and an entry with the given name is present' do
  its(:size) { is_expected.to eq given_names.size }

  it { is_expected.to include(entry1) }
end

shared_examples 'DataMapper::SubjectSet#values_at when more than one name is given and no entry with any of the given names is present' do
  its(:size) { is_expected.to eq given_names.size }

  it 'contains nil values for the names not found' do
    expect(subject.compact).to be_empty
  end
end

shared_examples 'DataMapper::SubjectSet#values_at when more than one name is given and one entry with one of the given names is present' do
  it { is_expected.to include(entry1) }

  its(:size) { is_expected.to eq given_names.size }

  it 'contains nil values for the names not found' do
    expect(subject.compact.size).to eq 1
  end
end

shared_examples 'DataMapper::SubjectSet#values_at when more than one name is given and an entry for every given name is present' do
  it { is_expected.to include(entry1) }
  it { is_expected.to include(entry2) }

  its(:size) { is_expected.to eq given_names.size }

  it 'does not contain any nil values' do
    expect(subject.compact.size).to eq given_names.size
  end
end
