shared_examples 'An Adapter' do

  def self.adapter_supports?(*methods)

    # FIXME: obviously this needs a real fix!
    # --------------------------------------
    # Probably, delaying adapter_supports?
    # to be executed after DataMapper.setup
    # has been called will solve our current
    # problem with described_type() being nil
    # for as long as DataMapper.setup wasn't
    # called
    return true if ENV['ADAPTER_SUPPORTS'] == 'all'

    methods.all? do |method|
      # TODO: figure out a way to see if the instance method is only inherited
      # from the Abstract Adapter, and not defined in it's class.  If that is
      # the case return false

      # CRUD methods can be inherited from parent class
      described_type.instance_methods.any? { |instance_method| method.to_s == instance_method.to_s }
    end
  end

  # Hack to detect cases a let(:heffalump_model) is not present
  unless instance_methods.map(&:to_s).include?('heffalump_model')
    # This is the default Heffalump model. You can replace it with your own
    # (using let/let!) # but # be sure the replacement provides the required
    # properties.
    let(:heffalump_model) do
      model = Class.new do
        include DataMapper::Resource

        property :id,        DataMapper::Property::Serial
        property :color,     DataMapper::Property::String
        property :num_spots, DataMapper::Property::Integer
        property :striped,   DataMapper::Property::Boolean

        # This is needed for DataMapper.finalize
        def self.name
          'Heffalump'
        end
      end

      DataMapper.finalize

      model
    end
  end

  before :all do
    raise '+#adapter+ should be defined in a let(:adapter) block' unless respond_to?(:adapter)
    raise '+#repository+ should be defined in a let(:repository) block' unless respond_to?(:repository)

    DataMapper.finalize

    # create all tables and constraints before each spec
    if repository.respond_to?(:auto_migrate!)
      heffalump_model.auto_migrate!
    end
  end

  if adapter_supports?(:create)
    describe '#create' do
      after do
        heffalump_model.destroy
      end

      it 'does not raise any errors' do
        expect {
          expect(heffalump_model.new(color: 'peach').save).to be(true)
        }.not_to raise_error
      end

      it 'sets the identity field for the resource' do
        heffalump = heffalump_model.new(color: 'peach')
        expect(heffalump.id).to be_nil
        expect(heffalump.save).to be(true)
        expect(heffalump.id).not_to be_nil
      end
    end
  else
    it 'needs to support #create'
  end

  if adapter_supports?(:read)
    describe '#read' do
      before :all do
        @heffalump = heffalump_model.create(color: 'brownish hue')
        expect(@heffalump).to be_saved
        @query = heffalump_model.all.query
      end

      after :all do
        heffalump_model.destroy
      end

      it 'does not raise any errors' do
        expect {
          heffalump_model.all
        }.not_to raise_error
      end

      it 'returns expected results' do
        expect(heffalump_model.all).to eq [@heffalump]
      end
    end
  else
    it 'needs to support #read'
  end

  if adapter_supports?(:update)
    describe '#update' do
      before do
        @heffalump = heffalump_model.create(color: 'peach', num_spots: 1, striped: false)
        expect(@heffalump).to be_saved
      end

      after do
        heffalump_model.destroy
      end

      it 'does not raise any errors' do
        expect {
          @heffalump.num_spots = 0
          expect(@heffalump.save).to be(true)
        }.not_to raise_error
      end

      it 'does not alter the identity field' do
        key = @heffalump.key
        @heffalump.num_spots = 0
        expect(@heffalump.save).to be(true)
        expect(@heffalump.key).to eq key
      end

      it 'updates altered fields' do
        @heffalump.num_spots = 0
        expect(@heffalump.save).to be(true)
        expect(heffalump_model.get!(*@heffalump.key).num_spots).to be(0)
      end

      it 'does not alter other fields' do
        num_spots = @heffalump.num_spots
        @heffalump.striped = true
        expect(@heffalump.save).to be(true)
        expect(heffalump_model.get!(*@heffalump.key).num_spots).to be(num_spots)
      end
    end
  else
    it 'needs to support #update'
  end

  if adapter_supports?(:delete)
    describe '#delete' do
      before do
        @heffalump = heffalump_model.create(color: 'forest green')
        expect(@heffalump).to be_saved
      end

      after do
        heffalump_model.destroy
      end

      it 'does not raise any errors' do
        expect {
          @heffalump.destroy
        }.not_to raise_error
      end

      it 'deletes the requested resource' do
        key = @heffalump.key
        @heffalump.destroy
        expect(heffalump_model.get(*key)).to be_nil
      end
    end
  else
    it 'needs to support #delete'
  end

  if adapter_supports?(:read, :create)
    describe 'query matching' do
      before :all do
        @red  = heffalump_model.create(color: 'red')
        @two  = heffalump_model.create(num_spots: 2)
        @five = heffalump_model.create(num_spots: 5)
        [@red, @two, @five].each { |resource| expect(resource).to be_saved }
      end

      after :all do
        heffalump_model.destroy
      end

      describe 'conditions' do
        describe 'eql' do
          it 'is able to search for objects included in an inclusive range of values' do
            expect(heffalump_model.all(num_spots: 1..5)).to include(@five)
          end

          it 'is able to search for objects included in an exclusive range of values' do
            expect(heffalump_model.all(num_spots: 1...6)).to include(@five)
          end

          it 'is not able to search for values not included in an inclusive range of values' do
            expect(heffalump_model.all(num_spots: 1..4)).not_to include(@five)
          end

          it 'is not able to search for values not included in an exclusive range of values' do
            expect(heffalump_model.all(num_spots: 1...5)).not_to include(@five)
          end
        end

        describe 'not' do
          it 'is able to search for objects with not equal value' do
            expect(heffalump_model.all(:color.not => 'red')).not_to include(@red)
          end

          it 'includes objects that are not like the value' do
            expect(heffalump_model.all(:color.not => 'black')).to include(@red)
          end

          it 'is able to search for objects with not nil value' do
            expect(heffalump_model.all(:color.not => nil)).to include(@red)
          end

          it 'does not include objects with a nil value' do
            expect(heffalump_model.all(:color.not => nil)).not_to include(@two)
          end

          it 'is able to search for object with a nil value using required properties' do
            expect(heffalump_model.all(:id.not => nil)).to eq [@red, @two, @five]
          end

          it 'is able to search for objects not in an empty list (match all)' do
            expect(heffalump_model.all(:color.not => [])).to eq [@red, @two, @five]
          end

          it 'is able to search for objects in an empty list and another OR condition (match none on the empty list)' do
            expect(heffalump_model.all(
              conditions: DataMapper::Query::Conditions::Operation.new(
                :or,
                DataMapper::Query::Conditions::Comparison.new(:in, heffalump_model.properties[:color], []),
                DataMapper::Query::Conditions::Comparison.new(:in, heffalump_model.properties[:num_spots], [5])
              )
            )).to eq [@five]
          end

          it 'is able to search for objects not included in an array of values' do
            expect(heffalump_model.all(:num_spots.not => [1, 3, 5, 7])).to include(@two)
          end

          it 'is able to search for objects not included in an array of values' do
            expect(heffalump_model.all(:num_spots.not => [1, 3, 5, 7])).not_to include(@five)
          end

          it 'is able to search for objects not included in an inclusive range of values' do
            expect(heffalump_model.all(:num_spots.not => 1..4)).to include(@five)
          end

          it 'is able to search for objects not included in an exclusive range of values' do
            expect(heffalump_model.all(:num_spots.not => 1...5)).to include(@five)
          end

          it 'is not able to search for values not included in an inclusive range of values' do
            expect(heffalump_model.all(:num_spots.not => 1..5)).not_to include(@five)
          end

          it 'is not able to search for values not included in an exclusive range of values' do
            expect(heffalump_model.all(:num_spots.not => 1...6)).not_to include(@five)
          end
        end

        describe 'like' do
          it 'is able to search for objects that match value' do
            expect(heffalump_model.all(:color.like => '%ed')).to include(@red)
          end

          it 'does not search for objects that do not match the value' do
            expect(heffalump_model.all(:color.like => '%blak%')).not_to include(@red)
          end
        end

        describe 'regexp' do
          before do
            if (defined?(DataMapper::Adapters::SqliteAdapter) && adapter.is_a?(DataMapper::Adapters::SqliteAdapter)) ||
               (defined?(DataMapper::Adapters::SqlserverAdapter) && adapter.is_a?(DataMapper::Adapters::SqlserverAdapter))
              pending 'delegate regexp matches to same system that the InMemory and YAML adapters use'
            end
          end

          it 'is able to search for objects that match value' do
            expect(heffalump_model.all(color: /ed/)).to include(@red)
          end

          it 'is not able to search for objects that do not match the value' do
            expect(heffalump_model.all(color: /blak/)).not_to include(@red)
          end

          it 'is able to do a negated search for objects that match value' do
            expect(heffalump_model.all(:color.not => /blak/)).to include(@red)
          end

          it 'is not able to do a negated search for objects that do not match value' do
            expect(heffalump_model.all(:color.not => /ed/)).not_to include(@red)
          end
        end

        describe 'gt' do
          it 'is able to search for objects with value greater than' do
            expect(heffalump_model.all(:num_spots.gt => 1)).to include(@two)
          end

          it 'does not find objects with a value less than' do
            expect(heffalump_model.all(:num_spots.gt => 3)).not_to include(@two)
          end
        end

        describe 'gte' do
          it 'is able to search for objects with value greater than' do
            expect(heffalump_model.all(:num_spots.gte => 1)).to include(@two)
          end

          it 'is able to search for objects with values equal to' do
            expect(heffalump_model.all(:num_spots.gte => 2)).to include(@two)
          end

          it 'does not find objects with a value less than' do
            expect(heffalump_model.all(:num_spots.gte => 3)).not_to include(@two)
          end
        end

        describe 'lt' do
          it 'is able to search for objects with value less than' do
            expect(heffalump_model.all(:num_spots.lt => 3)).to include(@two)
          end

          it 'does not find objects with a value less than' do
            expect(heffalump_model.all(:num_spots.gt => 2)).not_to include(@two)
          end
        end

        describe 'lte' do
          it 'is able to search for objects with value less than' do
            expect(heffalump_model.all(:num_spots.lte => 3)).to include(@two)
          end

          it 'is able to search for objects with values equal to' do
            expect(heffalump_model.all(:num_spots.lte => 2)).to include(@two)
          end

          it 'does not find objects with a value less than' do
            expect(heffalump_model.all(:num_spots.lte => 1)).not_to include(@two)
          end
        end
      end

      describe 'limits' do
        it 'is able to limit the objects' do
          expect(heffalump_model.all(limit: 2).length).to eq 2
        end
      end
    end
  else
    it 'needs to support #read and #create to test query matching'
  end
end
