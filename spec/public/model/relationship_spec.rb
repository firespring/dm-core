require_relative '../../spec_helper'

class ::Car
  include DataMapper::Resource

  property :id,   Serial
  property :name, String
end

class ::Engine
  include DataMapper::Resource

  property :id, Serial
end

class ::Door
  include DataMapper::Resource

  property :id, Serial
end

class ::Window
  include DataMapper::Resource

  property :id, Serial
end

shared_examples 'it creates a one accessor' do
  describe 'accessor' do
    describe 'when there is no associated resource' do
      describe 'without a query' do
        before :all do
          @return = @car.__send__(@name)
        end

        it 'returns nil' do
          expect(@return).to be_nil
        end
      end

      describe 'with a query' do
        before :all do
          @return = @car.__send__(@name, id: 99)
        end

        it 'returns nil' do
          expect(@return).to be_nil
        end
      end
    end

    describe 'when there is an associated resource' do
      before :all do
        @expected = @model.new
        @car.__send__("#{@name}=", @expected)
      end

      describe 'without a query' do
        before :all do
          @return = @car.__send__(@name)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resource' do
          expect(@return).to equal(@expected)
        end
      end

      describe 'with a query' do
        before :all do
          @car.save  # save @car and @expected to set @expected.id

          expect(@expected.id).not_to be_nil

          @return = @car.__send__(@name, id: @expected.id)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resource' do
          expect(@return).to eq @expected
        end
      end
    end

    describe 'when the target model is scoped' do
      before :all do
        @resource = @model.new
        @car.__send__("#{@name}=", @resource)
        @car.save

        # set the model scope to not match the expected resource
        @model.default_scope.update(:id.not => @resource.id)

        @return = @car.model.get!(*@car.key).__send__(@name)
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end
  end
end

shared_examples 'it creates a one mutator' do
  describe 'mutator' do
    describe 'when setting a Resource' do
      before :all do
        @expected = @model.new

        @return = @car.__send__("#{@name}=", @expected)
      end

      it 'returns the expected Resource' do
        expect(@return).to equal(@expected)
      end

      it 'sets the Resource' do
        expect(@car.__send__(@name)).to equal(@expected)
      end

      it 'relates associated Resource' do
        relationship = Car.relationships[@name]
        many_to_one = relationship.is_a?(DataMapper::Associations::ManyToOne::Relationship)
        one_to_one_through = relationship.is_a?(DataMapper::Associations::OneToOne::Relationship) && relationship.respond_to?(:through)

        pending if many_to_one || one_to_one_through

        expect(@expected.car).to eq @car
      end

      it 'persists the Resource' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @expected
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        expect(@expected).to be_saved
        expect(@expected.model.get!(*@expected.key).car).to eq @car
      end
    end

    describe 'when setting a Hash' do
      before :all do
        @car.__send__("#{@name}=", @model.new)

        attributes = {id: 10}
        @expected  = @model.new(attributes)

        @return = @car.__send__("#{@name}=", attributes)
      end

      it 'returns the expected Resource' do
        expect(@return).to eq @expected
      end

      it 'sets the Resource' do
        expect(@car.__send__(@name)).to equal(@return)
      end

        relationship       = Car.relationships[@name]
        many_to_one        = relationship.is_a?(DataMapper::Associations::ManyToOne::Relationship)
      it 'relates associated Resource' do
        one_to_one_through = relationship.is_a?(DataMapper::Associations::OneToOne::Relationship) && relationship.respond_to?(:through)

        pending if many_to_one || one_to_one_through
        expect(@return.car).to eq @car
      end

      it 'persists the Resource' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @return
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        expect(@return).to be_saved
        expect(@return&.model&.get!(*@return&.key).car).to eq @car
      end
    end

    describe 'when setting nil' do
      before :all do
        @car.__send__("#{@name}=", @model.new)

        @return = @car.__send__("#{@name}=", nil)
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end

      it 'sets nil' do
        expect(@car.__send__(@name)).to be_nil
      end

      it 'persists as nil' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to be_nil
      end
    end

    describe 'when changing the Resource' do
      before :all do
        @car.__send__("#{@name}=", @model.new)
        @expected = @model.new

        @return = @car.__send__("#{@name}=", @expected)
      end

      it 'returns the expected Resource' do
        expect(@return).to equal(@expected)
      end

      it 'sets the Resource' do
        expect(@car.__send__(@name)).to equal(@expected)
      end

        relationship       = Car.relationships[@name]
        many_to_one        = relationship.is_a?(DataMapper::Associations::ManyToOne::Relationship)
      it 'relates associated Resource' do
        one_to_one_through = relationship.is_a?(DataMapper::Associations::OneToOne::Relationship) && relationship.respond_to?(:through)

        pending 'creates back-reference' if many_to_one || one_to_one_through
        expect(@expected.car).to eq @car
      end

      it 'persists the Resource' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @expected
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        expect(@expected).to be_saved
        expect(@expected.model.get!(*@expected.key).car).to eq @car
      end
    end
  end
end

shared_examples 'it creates a many accessor' do
  describe 'accessor' do
    describe 'when there is no child resource and the source is saved' do
      before :all do
        expect(@car.save).to be(true)
        @return = @car.__send__(@name)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns an empty Collection' do
        expect(@return).to be_empty
      end
    end

    describe 'when there is no child resource and the source is not saved' do
      before :all do
        @return = @car.__send__(@name)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns an empty Collection' do
        expect(@return).to be_empty
      end
    end

    describe 'when there is a child resource' do
      before :all do
        @return = nil

        @expected = @model.new
        @car.__send__("#{@name}=", [@expected])

        @return = @car.__send__(@name)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns expected Resources' do
        expect(@return).to eq [@expected]
      end
    end

    describe 'when the target model is scoped' do
      before :all do
        2.times { @car.__send__(@name).new }
        @car.save

        @expected = @car.__send__(@name).first
        expect(@expected).not_to be_nil

        # set the model scope to only return the first record
        @model.default_scope.update(
          @model.key(@repository.name).zip(@expected.key).to_h
        )

        @return = @car.model.get!(*@car.key).__send__(@name)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns expected Resources' do
        expect(@return).to eq [@expected]
      end
    end
  end
end

shared_examples 'it creates a many mutator' do
  describe 'mutator' do
    describe 'when setting an Array of Resources' do
      before :all do
        @expected = [@model.new]

        @return = @car.__send__("#{@name}=", @expected)
      end

      it 'returns the expected Collection' do
        expect(@return).to eq @expected
      end

      it 'sets the Collection' do
        expect(@car.__send__(@name)).to eq @expected
        @car.__send__(@name).zip(@expected) { |value, expected| expect(value).to equal(expected) }
      end

      it 'relates the associated Collection' do
        pending if Car.relationships[@name].is_a?(DataMapper::Associations::ManyToMany::Relationship)
        @expected.each { |resource| expect(resource.car).to eq @car }
      end

      it 'persists the Collection' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @expected
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        @expected.each do |resource|
          expect(resource).to be_saved
          expect(resource.model.get!(*resource.key).car).to eq @car
        end
      end
    end

    describe 'when setting an Array of Hashes' do
      before :all do
        attributes = {id: 11}
        @hashes    = [attributes]
        @expected  = [@model.new(attributes)]

        @return = @car.__send__("#{@name}=", @hashes)
      end

      it 'returns the expected Collection' do
        expect(@return).to eq @expected
      end

      it 'sets the Collection' do
        expect(@car.__send__(@name)).to eq @return
      end

      it 'relates the associated Collection' do
        pending if Car.relationships[@name].is_a?(DataMapper::Associations::ManyToMany::Relationship)
        @return.each { |resource| expect(resource.car).to eq @car }
      end

      it 'persists the Collection' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @return
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        @return&.each do |resource|
          expect(resource).to be_saved
          expect(resource.model.get!(*resource.key).car).to eq @car
        end
      end
    end

    describe 'when setting an empty collection' do
      before :all do
        @car.__send__("#{@name}=", [@model.new])

        @return = @car.__send__("#{@name}=", [])
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'sets an empty Collection' do
        expect(@car.__send__(@name)).to be_empty
      end

      it 'persists as an empty Collection' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to be_empty
      end
    end

    describe 'when changing an associated collection' do
      before :all do
        @car.__send__("#{@name}=", [@model.new])

        @expected = [@model.new]

        @return = @car.__send__("#{@name}=", @expected)
      end

      it 'returns the expected Resource' do
        expect(@return).to eq @expected
      end

      it 'sets the Resource' do
        expect(@car.__send__(@name)).to eq @expected
        @car.__send__(@name).zip(@expected) { |value, expected| expect(value).to equal(expected) }
      end

      it 'relates associated Resource' do
        pending if Car.relationships[@name].is_a?(DataMapper::Associations::ManyToMany::Relationship)
        @expected.each { |resource| expect(resource.car).to eq @car }
      end

      it 'persists the Resource' do
        expect(@car.save).to be(true)
        expect(@car.model.get!(*@car.key).__send__(@name)).to eq @expected
      end

      it 'persists the associated Resource' do
        expect(@car.save).to be(true)
        @expected.each do |resource|
          expect(resource).to be_saved
          expect(resource.model.get!(*resource.key).car).to eq @car
        end
      end
    end
  end
end

describe DataMapper::Associations do
  before :all do
  end

  def n
    1.0/0
  end

  it { expect(Engine).to respond_to(:belongs_to) }

  describe '#belongs_to' do
    before :all do
      @model = Engine
      @name  = :engine

      Car.belongs_to(@name, required: false)
      Engine.has(1, :car)
      DataMapper.finalize
    end

    supported_by :all do
      before :all do
        @car = Car.new
      end

      it { expect(@car).to respond_to(@name) }

      it_behaves_like 'it creates a one accessor'

      it { expect(@car).to respond_to("#{@name}=") }

      it_behaves_like 'it creates a one mutator'

      describe 'with a :key option' do
        before :all do
          @relationship = Car.belongs_to("#{@name}_with_key".to_sym, @model, required: false, key: true)
          DataMapper.finalize
        end

        it 'creates a foreign key that is part of the key' do
          @relationship.child_key.each do |property|
            expect(property).to be_key
          end
        end
      end

      describe 'with a :unique option' do
        let(:unique) { %i(one two three) }

        before :all do
          @relationship = Car.belongs_to("#{@name}_with_unique".to_sym, @model, unique: unique)
          DataMapper.finalize
        end

        it 'creates a foreign key that is unique' do
          @relationship.child_key.each do |property|
            expect(property).to be_unique
          end
        end

        it 'creates a foreign key that has a unique index' do
          @relationship.child_key.each do |property|
            expect(property.unique_index).to equal(unique)
          end
        end
      end
    end

    # TODO: refactor these specs into above structure once they pass
    describe 'pending query specs' do
      before :all do
        Car.has(1, :engine)
        Engine.belongs_to(:car)
        DataMapper.finalize
      end

      supported_by :all do
        describe 'querying for a parent resource when only the foreign key is set' do
          before :all do
            # create a car that would be returned if the query is not
            # scoped properly to retrieve @car
            Car.create

            @car = Car.create
            engine = Engine.new(car_id: @car.id)

            @return = engine.car
          end

          it 'returns a Resource' do
            expect(@return).to be_kind_of(DataMapper::Resource)
          end

          it 'returns expected Resource' do
            expect(@return).to eql(@car)
          end
        end

        describe 'querying for a parent resource' do
          before :all do
            @car = Car.create
            @engine = Engine.create(car: @car)
            @resource = @engine.car(id: @car.id)
          end

          it 'returns a Resource' do
            expect(@resource).to be_kind_of(DataMapper::Resource)
          end

          it 'returns expected Resource' do
            expect(@resource).to eql(@car)
          end
        end

        describe 'querying for a parent resource that does not exist' do
          before :all do
            @car = Car.create
            @engine = Engine.create(car: @car)
            @resource = @engine.car(:id.not => @car.id)
          end

          it 'returns nil' do
            expect(@resource).to be_nil
          end
        end

        describe 'changing the parent resource' do
          before :all do
            @car = Car.create
            @engine = Engine.new
            @engine.car = @car
          end

          it 'sets the associated foreign key' do
            expect(@engine.car_id).to eq @car.id
          end

          it 'adds the engine object to the car' do
            pending 'Changing a belongs_to parent adds the object to the correct association'

            expect(@car.engines).to include(@engine)
          end
        end

        describe 'changing the parent foreign key' do
          before :all do
            @car = Car.create

            @engine = Engine.new(car_id: @car.id)
          end

          it 'sets the associated resource' do
            expect(@engine.car).to eql(@car)
          end
        end

        describe 'changing an existing resource through the relation' do
          before :all do
            @car1 = Car.create
            @car2 = Car.create
            @engine = Engine.create(car: @car1)
            @engine.car = @car2
          end

          it 'also changes the foreign key' do
            expect(@engine.car_id).to eq @car2.id
          end

          it 'adds the engine to the car' do
            pending 'Changing a belongs_to parent adds the object to the correct association'
            expect(@car2.engines).to include(@engine)
          end
        end

        describe 'changing an existing resource through the relation' do
          before :all do
            @car1 = Car.create
            @car2 = Car.create
            @engine = Engine.create(car: @car1)
            @engine.car_id = @car2.id
          end

          it 'also changes the foreign key' do
            expect(@engine.car).to eql(@car2)
          end

          it 'adds the engine to the car' do
            pending 'a change to the foreign key also changes the related object'
            expect(@car2.engines).to include(@engine)
          end
        end
      end
    end

    describe 'with a model' do
      before :all do
        Engine.belongs_to(:vehicle, Car)
        DataMapper.finalize
      end

      it 'sets the relationship target model' do
        expect(Engine.relationships[:vehicle].target_model).to eq Car
      end
    end

    describe 'with a :model option' do
      before :all do
        Engine.belongs_to(:vehicle, model: Car)
        DataMapper.finalize
      end

      it 'sets the relationship target model' do
        expect(Engine.relationships[:vehicle].target_model).to eq Car
      end
    end

    describe 'with a single element as :child_key option' do
      before :all do
        Engine.belongs_to(:vehicle, model: Car, child_key: :bike_id)
        DataMapper.finalize
      end

      it 'sets the relationship child key' do
        expect(Engine.relationships[:vehicle].child_key.map(&:name)).to eq [:bike_id]
      end
    end

    describe 'with an array as :child_key option' do
      before :all do
        Engine.belongs_to(:vehicle, model: Car, child_key: [:bike_id])
        DataMapper.finalize
      end

      it 'sets the relationship child key' do
        expect(Engine.relationships[:vehicle].child_key.map(&:name)).to eq [:bike_id]
      end
    end

    describe 'with a single element as :parent_key option' do
      before :all do
        Engine.belongs_to(:vehicle, model: Car, parent_key: :name)
        DataMapper.finalize
      end

      it 'sets the relationship parent key' do
        expect(Engine.relationships[:vehicle].parent_key.map(&:name)).to eq [:name]
      end
    end

    describe 'with an array as :parent_key option' do
      before :all do
        Engine.belongs_to(:vehicle, model: Car, parent_key: [:name])
        DataMapper.finalize
      end

      it 'sets the relationship parent key' do
        expect(Engine.relationships[:vehicle].parent_key.map(&:name)).to eq [:name]
      end
    end
  end

  it { expect(Car).to respond_to(:has) }

  describe '#has' do
    describe '1' do
      before :all do
        @model = Engine
        @name  = :engine

        Car.has(1, @name)
        Engine.belongs_to(:car)
        DataMapper.finalize
      end

      supported_by :all do
        before :all do
          @car = Car.new
        end

        it { expect(@car).to respond_to(@name) }

        it_behaves_like 'it creates a one accessor'

        it { expect(@car).to respond_to("#{@name}=") }

        it_behaves_like 'it creates a one mutator'
      end
    end

    describe '1 through' do
      before :all do
        @model = Engine
        @name  = :engine

        Car.has(1, @name, through: DataMapper::Resource)
        Engine.has(1, :car, through: DataMapper::Resource)
        DataMapper.finalize
      end

      supported_by :all do
        before :all do
          @no_join = (defined?(DataMapper::Adapters::InMemoryAdapter) && @adapter.is_a?(DataMapper::Adapters::InMemoryAdapter)) ||
                     (defined?(DataMapper::Adapters::YamlAdapter)     && @adapter.is_a?(DataMapper::Adapters::YamlAdapter))
        end

        before :all do
          @car = Car.new
        end

        before do
          pending if @no_join
        end

        it { expect(@car).to respond_to(@name) }

        it_behaves_like 'it creates a one accessor'

        it { expect(@car).to respond_to("#{@name}=") }

        it_behaves_like 'it creates a one mutator'
      end
    end

    describe 'n..n' do
      before :all do
        @model = Door
        @name  = :doors

        Car.has(1..4, @name)
        Door.belongs_to(:car, required: false)
        DataMapper.finalize
      end

      supported_by :all do
        before :all do
          @car = Car.new
        end

        it { expect(@car).to respond_to(@name) }

        it_behaves_like 'it creates a many accessor'

        it { expect(@car).to respond_to("#{@name}=") }

        it_behaves_like 'it creates a many mutator'
      end
    end

    describe 'n..n through' do
      before :all do
        @model = Window
        @name  = :windows

        Window.has(1, :car, through: DataMapper::Resource)
        Car.has(1..4, :windows, through: DataMapper::Resource)
        DataMapper.finalize
      end

      supported_by :all do
        before :all do
          @no_join = (defined?(DataMapper::Adapters::InMemoryAdapter) && @adapter.is_a?(DataMapper::Adapters::InMemoryAdapter)) ||
                     (defined?(DataMapper::Adapters::YamlAdapter)     && @adapter.is_a?(DataMapper::Adapters::YamlAdapter))
        end

        before :all do
          @car = Car.new
        end

        before do
          pending if @no_join
        end

        it { expect(@car).to respond_to(@name) }

        it_behaves_like 'it creates a many accessor'

        it { expect(@car).to respond_to("#{@name}=") }

        it_behaves_like 'it creates a many mutator'
      end
    end

    describe 'when the 3rd argument is a Model' do
      before :all do
        Car.has(1, :engine, Engine)
        DataMapper.finalize
      end

      it 'sets the relationship target model' do
        expect(Car.relationships[:engine].target_model).to eq Engine
      end
    end

    describe 'when the 3rd argument is a String' do
      before :all do
        Car.has(1, :engine, 'Engine')
        DataMapper.finalize
      end

      it 'sets the relationship target model' do
        expect(Car.relationships[:engine].target_model).to eq Engine
      end
    end

    it 'raises an exception if the cardinality is not understood' do
      expect { Car.has(n..n, :doors) }.to raise_error(ArgumentError)
    end

    it 'raises an exception if the minimum constraint is larger than the maximum' do
      expect { Car.has(2..1, :doors) }.to raise_error(ArgumentError)
    end
  end

  describe 'property prefix inference' do
    describe 'when a relationship has an inverse' do
      before :all do
        @engine_relationship = Car.has(1, :engine, inverse: Engine.belongs_to(:sports_car, Car))
        DataMapper.finalize
      end

      supported_by :all do
        it 'has a child key prefix the same as the inverse relationship' do
          expect(@engine_relationship.child_key.map(&:name)).to eq [:sports_car_id]
        end
      end
    end

    describe 'when a relationship does not have an inverse' do
      before :all do
        @engine_relationship = Car.has(1, :engine)
        DataMapper.finalize
      end

      supported_by :all do
        it 'has a child key prefix inferred from the source model name' do
          expect(@engine_relationship.child_key.map(&:name)).to eq [:car_id]
        end
      end
    end

    describe 'when a relationship is inherited' do
      describe 'has an inverse' do
        before :all do
          Car.property(:type, DataMapper::Property::Discriminator)

          class ::ElectricCar < Car; end

          Car.has(1, :engine, inverse: Engine.belongs_to(:sports_car, Car))
          DataMapper.finalize
        end

        supported_by :all do
          before :all do
            @engine_relationship = ElectricCar.relationships(@repository.name)[:engine]
          end

          it 'has a source model equal to the ancestor' do
            expect(@engine_relationship.source_model).to equal(Car)
          end

          it 'has a child key prefix the same as the inverse relationship' do
            expect(@engine_relationship.child_key.map(&:name)).to eq [:sports_car_id]
          end
        end
      end

      describe 'does not have an inverse' do
        before :all do
          Car.property(:type, DataMapper::Property::Discriminator)

          class ::ElectricCar < Car; end

          Car.has(1, :engine)
          DataMapper.finalize
        end

        supported_by :all do
          before :all do
            @engine_relationship = ElectricCar.relationships(@repository.name)[:engine]
          end

          it 'has a source model equal to the ancestor' do
            expect(@engine_relationship.source_model).to equal(Car)
          end

          it 'has a child key prefix inferred from the source model name' do
            expect(@engine_relationship.child_key.map(&:name)).to eq [:car_id]
          end
        end
      end
    end

    describe "when a subclass defines it's own relationship" do
      describe 'has an inverse' do
        before :all do
          Car.property(:type, DataMapper::Property::Discriminator)

          class ::ElectricCar < Car; end

          ElectricCar.has(1, :engine, inverse: Engine.belongs_to(:sports_car, Car))
          DataMapper.finalize
        end

        supported_by :all do
          before :all do
            @engine_relationship = ElectricCar.relationships(@repository.name)[:engine]
          end

          it 'has a source model equal to the descendant' do
            expect(@engine_relationship.source_model).to equal(ElectricCar)
          end

          it 'has a child key prefix the same as the inverse relationship' do
            expect(@engine_relationship.child_key.map(&:name)).to eq [:sports_car_id]
          end
        end
      end

      describe 'does not have an inverse' do
        before :all do
          Car.property(:type, DataMapper::Property::Discriminator)

          class ::ElectricCar < Car; end

          ElectricCar.has(1, :engine)
          DataMapper.finalize
        end

        supported_by :all do
          before :all do
            @engine_relationship = ElectricCar.relationships(@repository.name)[:engine]
          end

          it 'has a source model equal to the descendant' do
            expect(@engine_relationship.source_model).to equal(ElectricCar)
          end

          it 'has a child key prefix inferred from the source model name' do
            expect(@engine_relationship.child_key.map(&:name)).to eq [:electric_car_id]
          end
        end
      end
    end
  end

  describe 'child is also a parent' do
    before :all do
      class ::Employee
        include DataMapper::Resource

        property :id,   Serial
        property :name, String

        belongs_to :company
      end

      class ::Company
        include DataMapper::Resource

        property :id,   Serial
        property :name, String

        belongs_to :owner, Employee, required: false
        has n, :employees
      end
      DataMapper.finalize
    end

    supported_by :all do
      before :all do
        @company  = Company.create(name: 'ACME Inc.')
        @employee = @company.employees.create(name: 'Wil E. Coyote')
      end

      it 'saves the child as a parent' do
        expect {
          @company.owner = @employee
          expect(@company.save).to be(true)
        }.not_to raise_error
      end
    end
  end
end
