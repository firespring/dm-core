shared_examples 'A method that delegates to the superclass #set' do
  it 'Delegates to the superclass' do
    # this is the only way I could think of to test if the
    # superclass method is being called
    DataMapper::Resource::PersistenceState.class_eval do
      alias_method :original_set, :set
      undef_method(:set)
    end
    expect { method(:subject) }.to raise_error(NoMethodError)
    DataMapper::Resource::PersistenceState.class_eval do
      alias_method :set, :original_set
      undef_method(:original_set)
    end
  end
end

shared_examples 'A method that does not delegate to the superclass #set' do
  it 'Delegates to the superclass' do
    # this is the only way I could think of to test if the
    # superclass method is not being called
    DataMapper::Resource::PersistenceState.class_eval do
      alias_method :original_set, :set
      undef_method(:set)
    end
    expect { method(:subject) }.not_to raise_error
    DataMapper::Resource::PersistenceState.class_eval do
      alias_method :set, :original_set
      undef_method(:original_set)
    end
  end
end

shared_examples 'It resets resource state' do
  it 'Resets the dirty property' do
    expect { method(:subject) }.to change(@resource, :name).from('John Doe').to('Dan Kubb')
  end

  it 'Resets the dirty m:1 relationship' do
    expect { method(:subject) }.to change(@resource, :parent).from(@resource).to(nil)
  end

  it 'Resets the dirty 1:m relationship' do
    expect { method(:subject) }.to change(@resource, :children).from([@resource]).to([])
  end

  it 'Clear original attributes' do
    expect { method(:subject) }.to change { @resource.original_attributes.dup }.to({})
  end
end

shared_examples 'Resource::PersistenceState::Persisted#get' do
  subject { @state.get(@key) }

  supported_by :all do
    describe 'with an unloaded subject' do
      before do
        @key = @model.relationships[:parent]

        # set the parent relationship
        @resource.attributes = {@key => @resource}
        expect(@resource).to be_dirty
        expect(@resource.save).to be(true)

        attributes = @model.key.zip(@resource.key).to_h
        @resource = @model.first(attributes.merge(fields: @model.key))
        @state = @state.class.new(@resource)

        # make sure the subject is not loaded
        expect(@key).not_to be_loaded(@resource)
      end

      it 'Lazy loads the value' do
        expect(subject.key).to eq @resource.key
      end
    end

    describe 'with a loaded subject' do
      before do
        @key = @model.properties[:name]
        @loaded_value ||= 'Dan Kubb'

        # make sure the subject is loaded
        expect(@key).to be_loaded(@resource)
      end

      it 'Returns value' do
        is_expected.to eq @loaded_value
      end
    end
  end
end
