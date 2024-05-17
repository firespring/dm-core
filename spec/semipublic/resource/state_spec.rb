require_relative '../../spec_helper'

describe DataMapper::Resource::PersistenceState do
  before :all do
    class ::Author
      include DataMapper::Resource

      property :id,      Serial
      property :name,    String
      property :private, Boolean, :accessor => :private

      belongs_to :parent, self, :required => false
    end

    DataMapper.finalize

    @model = Author
  end

  before do
    @resource = @model.new(:name => 'Dan Kubb')

    @state = DataMapper::Resource::PersistenceState.new(@resource)
  end

  describe '.new' do
    subject { DataMapper::Resource::PersistenceState.new(@resource) }

    it { is_expected.to be_kind_of(DataMapper::Resource::PersistenceState) }
  end

  describe '#==' do
    subject { @state == @other }

    supported_by :all do
      describe 'with the same class and resource' do
        before do
          @other = DataMapper::Resource::PersistenceState.new(@resource)
        end

        it { is_expected.to be(true) }

        it 'Is symmetric' do
          is_expected.to eq(@other == @state)
        end
      end

      describe 'with the same class and different resource' do
        before do
          @other = DataMapper::Resource::PersistenceState.new(@model.new)
        end

        it { is_expected.to be(false) }

        it 'Is symmetric' do
          is_expected.to eq(@other == @state)
        end
      end

      describe 'with a different class and the same resource' do
        before do
          @other = DataMapper::Resource::PersistenceState::Clean.new(@resource)
        end

        it 'Is true for a subclass' do
          is_expected.to be(true)
        end

        it 'Is symmetric' do
          is_expected.to eq(@other == @state)
        end
      end

      describe 'with a different class and different resource' do
        before do
          @other = DataMapper::Resource::PersistenceState::Clean.new(@model.new)
        end

        it { is_expected.to be(false) }

        it 'Is symmetric' do
          is_expected.to eq(@other == @state)
        end
      end
    end
  end

  [ :commit, :delete, :rollback ].each do |method|
    describe "##{method}" do
      subject { @state.send(method) }

      it 'Raises an exception' do
        expect { method(:subject) }.to raise_error(NotImplementedError, "DataMapper::Resource::PersistenceState##{method} should be implemented")
      end
    end
  end

  describe '#eql?' do
    subject { @state.eql?(@other) }

    supported_by :all do
      describe 'with the same class and resource' do
        before do
          @other = DataMapper::Resource::PersistenceState.new(@resource)
        end

        it { is_expected.to be(true) }

        it 'Is symmetric' do
          is_expected.to eq @other.eql?(@state)
        end
      end

      describe 'with the same class and different resource' do
        before do
          @other = DataMapper::Resource::PersistenceState.new(@model.new)
        end

        it { is_expected.to be(false) }

        it 'Is symmetric' do
          is_expected.to eq @other.eql?(@state)
        end
      end

      describe 'with a different class and the same resource' do
        before do
          @other = DataMapper::Resource::PersistenceState::Clean.new(@resource)
        end

        it { is_expected.to be(false) }

        it 'Is symmetric' do
          is_expected.to eq @other.eql?(@state)
        end
      end

      describe 'with a different class and different resource' do
        before do
          @other = DataMapper::Resource::PersistenceState::Clean.new(@model.new)
        end

        it { is_expected.to be(false) }

        it 'Is symmetric' do
          is_expected.to eq @other.eql?(@state)
        end
      end
    end
  end

  describe '#get' do
    subject { @state.get(@key) }

    describe 'with a Property subject' do
      before do
        @key = @model.properties[:name]
      end

      it 'Returns the value' do
        is_expected.to eq 'Dan Kubb'
      end
    end

    describe 'with a Relationship subject' do
      supported_by :all do
        before do
          # set the association
          @resource.parent = @resource

          @key = @model.relationships[:parent]
        end

        it 'Returns the association' do
          is_expected.to eq @resource
        end
      end
    end
  end

  describe '#hash' do
    subject { @state.hash }

    it { is_expected.to eq @state.class.hash ^ @resource.hash }
  end

  describe '#resource' do
    subject { @state.resource }

    it 'Returns the resource' do
      is_expected.to equal(@resource)
    end
  end

  describe '#set' do
    subject { @state.set(@key, @value) }

    describe 'with a Property subject' do
      before do
        @key   = @model.properties[:name]
        @value = 'John Doe'
      end

      it 'Returns a state object' do
        is_expected.to be_kind_of(DataMapper::Resource::PersistenceState)
      end

      it 'Change the object attributes' do
        expect { method(:subject) }.to change(@resource, :attributes).from(:name => 'Dan Kubb').to(:name => 'John Doe')
      end
    end

    describe 'with a Relationship subject' do
      supported_by :all do
        before do
          @key   = @model.relationships[:parent]
          @value = @resource
        end

        it 'Returns a state object' do
          is_expected.to be_kind_of(DataMapper::Resource::PersistenceState)
        end

        it 'Changes the object relationship' do
          expect { method(:subject) }.to change(@resource, :parent).from(nil).to(@resource)
        end
      end
    end
  end
end
