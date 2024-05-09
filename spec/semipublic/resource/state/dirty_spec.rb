require_relative '../../../spec_helper'

describe DataMapper::Resource::PersistenceState::Dirty do
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
    @parent = @model.create(:name => 'Jane Doe')

    @resource = @model.create(:id => 2, :name => 'Dan Kubb', :parent => @parent)
    @resource.attributes = { :name => 'John Doe' }

    @state = @resource.persistence_state
    expect(@state).to be_kind_of(DataMapper::Resource::PersistenceState::Dirty)
  end

  after do
    @model.destroy!
  end

  describe '#commit' do
    subject { @state.commit }

    supported_by :all do
      context 'with valid attributes' do
        let(:state) { @state }

        before do
          @new_id = @resource.id = @resource.id.succ
        end

        it 'returns a Clean state' do
          is_expected.to eql(DataMapper::Resource::PersistenceState::Clean.new(@resource))
        end

        it 'sets the child key if the parent key changes' do
          original_id = @parent.id
          expect { @parent.update(id: 42) }.to be(true)
          expect { method(:subject) }.to change(@resource, :parent_id).from(original_id).to(42)
        end

        it 'updates the resource' do
          subject
          expect { @model.get!(*@resource.key) }.to eq @resource
        end

        it 'updates the resource to the identity map if the key changed' do
          identity_map = @resource.repository.identity_map(@model)
          expect(identity_map).to eq({ @resource.key => @resource })
          subject
          expect(identity_map).to eq({[@new_id] => @resource})
        end
      end

      context 'with invalid attributes' do
        before do
          @resource.coding = 'invalid'
        end

        it 'raises InvalidValueError' do
          expect { subject }.to(raise_error(DataMapper::Property::InvalidValueError) do |error|
            expect(error.property).to eq Author.coding
          end)
        end

        it 'does not change the identity map' do
          identity_map = @resource.repository.identity_map(@model).dup
          expect { subject }.to raise_error
          expect(identity_map).to eq @resource.repository.identity_map(@model)
        end
      end
    end
  end

  describe '#delete' do
    subject { @state.delete }

    supported_by :all do
      before do
        @resource.children = [ @resource.parent = @resource ]
      end

      it_behaves_like 'It resets resource state'

      it 'returns a Deleted state' do
        is_expected.to eql(DataMapper::Resource::PersistenceState::Deleted.new(@resource))
      end
    end
  end

  describe '#get' do
    before do
      @loaded_value = 'John Doe'
    end

    it_behaves_like 'Resource::PersistenceState::Persisted#get'
  end

  describe '#rollback' do
    subject { @state.rollback }

    supported_by :all do
      before do
        @resource.children = [ @resource.parent = @resource ]
      end

      it_behaves_like 'It resets resource state'

      it 'returns a Clean state' do
        is_expected.to eql(DataMapper::Resource::PersistenceState::Clean.new(@resource))
      end
    end
  end

  describe '#set' do
    subject { @state.set(@key, @value) }

    supported_by :all do
      describe 'with attributes that keep the resource dirty' do
        before do
          @key   = @model.properties[:id]
          @value = @key.get!(@resource)
        end

        it_behaves_like 'A method that delegates to the superclass #set'

        it 'returns a Dirty state' do
          is_expected.to equal(@state)
        end

        its(:original_attributes) { is_expected.to eq({@model.properties[:name] => 'Dan Kubb'}) }
      end

      describe 'with attributes that make the resource clean' do
        before do
          @key   = @model.properties[:name]
          @value = 'Dan Kubb'
        end

        it_behaves_like 'A method that delegates to the superclass #set'

        it 'returns a Clean state' do
          is_expected.to eql(DataMapper::Resource::PersistenceState::Clean.new(@resource))
        end
      end
    end
  end
end
