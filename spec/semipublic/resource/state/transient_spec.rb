require_relative '../../../spec_helper'

describe DataMapper::Resource::PersistenceState::Transient do
  before :all do
    class ::Author
      include DataMapper::Resource

      property :id,          Serial
      property :name,        String
      property :age,         Integer
      property :description, Text,    :default => lambda { |resource, property| resource.name }
      property :active,      Boolean, :default => true
      property :coding,      Boolean, :default => true

      belongs_to :parent, self, :required => false
      has n, :children, self, :inverse => :parent

      belongs_to :with_default, self, :required => false, :default => proc { first(:name => 'John Doe') }
    end

    DataMapper.finalize

    @model = Author
  end

  before do
    @parent   = @model.create(:name => 'John Doe')
    @resource = @model.new(:name => 'Dan Kubb', :coding => false, :parent => @parent)

    @state = @resource.persistence_state
    expect(@state).to be_kind_of(DataMapper::Resource::PersistenceState::Transient)
  end

  after do
    @model.destroy!
  end

  describe '#commit' do
    subject { @state.commit }

    supported_by :all do
      it 'Returns the expected Clean state' do
        is_expected.to eql(DataMapper::Resource::PersistenceState::Clean.new(@resource))
      end

      it 'Sets the serial property' do
        expect { method(:subject) }.to change(@resource, :id).from(nil)
      end

      it 'Sets the child key if the parent key changes' do
        # SqlServer does not allow updating IDENTITY columns.
        if defined?(DataMapper::Adapters::SqlserverAdapter) &&
           @adapter.kind_of?(DataMapper::Adapters::SqlserverAdapter)
          return
        end

        original_id = @parent.id
        expect { @parent.update(id: 42) }.to be(true)
        expect { method(:subject) }.to change(@resource, :parent_id).from(original_id).to(42)
      end

      it 'Sets the default values' do
        expect { method(:subject) }.to change { @model.relationships[:with_default].get!(@resource) }.from(nil).to(@parent)
      end

      it "Doesn't set default values when they are already set" do
        expect { method(:subject) }.not_to change(@resource, :coding)
      end

      it 'Creates the resource' do
        subject
        expect { @model.get(*@resource.key) }.to eq @resource
      end

      it 'resets original attributes' do
        original_attributes = {
          @model.properties[:name]      => nil,
          @model.properties[:coding]    => nil,
          @model.properties[:parent_id] => nil,
          @model.relationships[:parent] => nil,
        }

        expect do
          @resource.persistence_state = subject
        end.to change { @resource.original_attributes.dup }.from(original_attributes).to({})
      end

      it 'adds the resource to the identity map' do
        DataMapper.repository do |repository|
          identity_map = repository.identity_map(@model)
          expect(identity_map).to be_empty
          subject
          expect(identity_map).to eq({@parent.key => @parent, @resource.key => @resource})
        end
      end
    end
  end

  [ :delete, :rollback ].each do |method|
    describe "##{method}" do
      subject { @state.send(method) }

      supported_by :all do
        it 'is a no-op' do
          is_expected.to equal(@state)
        end
      end
    end
  end

  describe '#get' do
    subject { @state.get(@key) }

    supported_by :all do
      describe 'with a set value' do
        before do
          @key = @model.properties[:coding]
          expect(@key).to be_loaded(@resource)
        end

        it 'returns value' do
          is_expected.to be(false)
        end

        it 'is idempotent' do
          is_expected.to equal(subject)
        end
      end

      describe 'with an unset value and no default value' do
        before do
          @key = @model.properties[:age]
          expect(@key).not_to be_loaded(@resource)
          expect(@key).not_to be_default
        end

        it 'returns nil' do
          is_expected.to be_nil
        end

        it 'is idempotent' do
          is_expected.to equal(subject)
        end
      end

      describe 'with an unset value and a default value' do
        before do
          @key = @model.properties[:description]
          expect(@key).not_to be_loaded(@resource)
          expect(@key).to be_default
        end

        it 'Returns the name' do
          is_expected.to eq 'Dan Kubb'
        end

        it 'Is idempotent' do
          is_expected.to equal(subject)
        end
      end
    end
  end
end
