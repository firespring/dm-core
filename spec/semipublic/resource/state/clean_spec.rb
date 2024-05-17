require_relative '../../../spec_helper'

describe DataMapper::Resource::PersistenceState::Clean do
  before :all do
    class ::Author
      include DataMapper::Resource

      property :id,     HugeInteger, :key => true, :default => 1
      property :name,   String
      property :active, Boolean,     :default => true
      property :coding, Boolean,     :default => true

      belongs_to :parent, self, :required => false
      has n, :children, self, :inverse => :parent
    end
    DataMapper.finalize

    @model = Author
  end

  before do
    @resource = @model.create(:name => 'Dan Kubb')

    @state = @resource.persistence_state
    expect(@state).to be_kind_of(DataMapper::Resource::PersistenceState::Clean)
  end

  after do
    @model.destroy!
  end

  [ :commit, :rollback ].each do |method|
    describe "##{method}" do
      subject { @state.send(method) }

      supported_by :all do
        it 'is a no-op' do
          is_expected.to equal(@state)
        end
      end
    end
  end

  describe '#delete' do
    subject { @state.delete }

    supported_by :all do
      it 'returns a Deleted state' do
        is_expected.to eql(DataMapper::Resource::PersistenceState::Deleted.new(@resource))
      end
    end
  end

  describe '#get' do
    it_behaves_like 'Resource::PersistenceState::Persisted#get'
  end

  describe '#set' do
    subject { @state.set(@key, @value) }

    supported_by :all do
      describe 'with attributes that make the resource dirty' do
        before do
          @key = @model.properties[:name]
          @value = nil
        end

        it_behaves_like 'A method that delegates to the superclass #set'

        it 'returns a Dirty state' do
          is_expected.to eql(DataMapper::Resource::PersistenceState::Dirty.new(@resource))
        end
      end

      describe 'with attributes that keep the resource clean' do
        before do
          @key   = @model.properties[:name]
          @value = 'Dan Kubb'
        end

        it_behaves_like 'A method that does not delegate to the superclass #set'

        it 'returns a Clean state' do
          is_expected.to equal(@state)
        end
      end
    end
  end
end
