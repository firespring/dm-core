require_relative '../../spec_helper'

describe DataMapper::Property, 'Object type' do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,    Serial
        property :title, String
        property :meta,  Object, :required => true
      end
    end

    DataMapper.finalize
    @model    = Blog::Article
    @property = @model.properties[:meta]
  end

  subject { @property }

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to be_empty }
  end

  it { is_expected.to respond_to(:typecast) }

  describe '#typecast' do
    subject { @property.typecast(@value) }

    before do
      @value = { 'lang' => 'en_CA' }
    end

    context 'when the value is a primitive' do
      it { is_expected.to equal(@value) }
    end

    context 'when the value is not a primitive' do
      before do
        # simulate the value not being a primitive
        expect(@property).to receive(:value_loaded?).with(@value).and_return(false)
      end

      it { is_expected.to equal(@value) }
    end
  end

  it { is_expected.to respond_to(:dump) }

  describe '#dump' do
    describe 'with a value' do
      before do
        @value = { 'lang' => 'en_CA' }
      end

      subject { @property.dump(@value) }

      it { expect(@property.load(subject)).to eq @value }
    end

    describe 'with nil' do
      subject { @property.dump(nil) }

      it { is_expected.to be_nil }
    end
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    describe 'with a valid load_as' do
      subject { @property.valid?('lang' => 'en_CA') }

      it { is_expected.to be(true) }
    end

    describe 'with nil and property is not required' do
      before do
        @property = @model.property(:meta, Object, :required => false)
      end

      subject { @property.valid?(nil) }

      it { is_expected.to be(true) }
    end

    describe 'with nil and property is required' do
      subject { @property.valid?(nil) }

      it { is_expected.to be(false) }
    end

    describe 'with nil and property is required, but validity is negated' do
      subject { @property.valid?(nil, true) }

      it { is_expected.to be(true) }
    end
  end

  describe 'persistable' do
    supported_by :all do
      before :all do
        @resource = @model.create(:title => 'Test', :meta => { 'lang' => 'en_CA' })
      end

      subject { @resource.reload.meta }

      it 'loads the correct value' do
        is_expected.to eq({'lang' => 'en_CA'})
      end
    end
  end
end
