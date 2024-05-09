shared_examples 'A semipublic Resource' do
  before :all do
    %w[ @user_model @user ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end
  end

  it { expect(@user).to respond_to(:attribute_dirty?) }

  describe '#attribute_dirty?' do
    describe 'on a non-dirty record' do
      it { expect(@user.attribute_dirty?(:age)).to be(false) }
    end

    describe 'on a dirty record' do
      before { @user.age = 100 }

      it { expect(@user.attribute_dirty?(:age)).to be(true) }
    end

    describe 'on a new record' do
      before { @user = @user_model.new }

      it { expect(@user.attribute_dirty?(:age)).to be(false) }
    end
  end

  it { expect(@user).to respond_to(:dirty_attributes) }

  describe '#dirty_attributes' do
    describe 'on a saved/clean record' do
      it { expect(@user.dirty_attributes).to be_empty }
    end

    describe 'on a saved/dirty record' do
      before { @user.age = 100 }

      it { expect(@user.dirty_attributes).to eq({@user_model.properties[:age] => 100}) }
    end

    describe 'on an saved/set/unset record' do
      before do
        @user.age = 100
        @user.age = 25
      end

      it { expect(@user.dirty_attributes).to be_empty }
    end

    describe 'on an saved/unchanged record' do
      before do
        @user.age = 25
      end

      it { expect(@user.dirty_attributes).to be_empty }
    end

    describe 'on a new/clean record' do
      before { @user = @user_model.new }

      it { expect(@user.dirty_attributes).to be_empty }
    end

    describe 'on a new/dirty record' do
      before { @user = @user_model.new(:age => 100) }

      it { expect(@user.original_attributes).to eq({@user_model.properties[:age] => nil}) }
    end

    describe 'on an new/set/unset record' do
      before do
        @user = @user_model.new(:age => 100)
        @user.age = nil
      end

      it { expect(@user.dirty_attributes).to eq({@user_model.properties[:age] => nil}) }
    end

    describe 'on an new/unchanged record' do
      before do
        @user = @user_model.new(:age => nil)
      end

      it { expect(@user.dirty_attributes).to eq({@user_model.properties[:age] => nil}) }
    end
  end

  it { expect(@user).to respond_to(:original_attributes) }

  describe '#original_attributes' do
    describe 'on a saved/clean record' do
      it { expect(@user.original_attributes).to be_empty }
    end

    describe 'on a saved/dirty record' do
      before { @user.age = 100 }

      it { expect(@user.original_attributes).to eq({@user_model.properties[:age] => 25}) }
    end

    describe 'on an saved/set/unset record' do
      before do
        @user.age = 100
        @user.age = 25
      end

      it { expect(@user.original_attributes).to be_empty }
    end

    describe 'on an saved/unchanged record' do
      before do
        @user.age = 25
      end

      it { expect(@user.original_attributes).to be_empty }
    end

    describe 'on a new/clean record' do
      before { @user = @user_model.new }

      it { expect(@user.original_attributes).to be_empty }
    end

    describe 'on a new/dirty record' do
      before { @user = @user_model.new(:age => 100) }

      it { expect(@user.original_attributes).to eq({@user_model.properties[:age] => nil}) }
    end

    describe 'on an new/set/unset record' do
      before do
        @user = @user_model.new(:age => 100)
        @user.age = nil
      end

      it { expect(@user.original_attributes).to eq({@user_model.properties[:age] => nil}) }
    end

    describe 'on an new/unchanged record' do
      before do
        @user = @user_model.new(:age => nil)
      end

      it { expect(@user.original_attributes).to eq({@user_model.properties[:age] => nil}) }
    end
  end

  it { expect(@user).to respond_to(:repository) }

  describe '#repository' do
    before :all do
      class ::Statistic
        include DataMapper::Resource

        def self.default_repository_name
          :alternate
        end

        property :id,    Serial
        property :name,  String
        property :value, Integer
      end
    end

    with_alternate_adapter do
      before :all do
        if @user_model.respond_to?(:auto_migrate!)
          # force the user model to be available in the alternate repository
          @user_model.auto_migrate!(@adapter.name)
        end
      end

      it 'Returns the default repository when nothing is specified' do
        default_repository = DataMapper.repository(:default)
        expect(@user_model.create(name: 'carl').repository).to eq default_repository
        expect(@user_model.new.repository).to eq default_repository
        expect(@user_model.get('carl').repository).to eq default_repository
      end

      it 'Returns the default repository for the model' do
        statistic = Statistic.create(name: 'visits', value: 2)
        expect(statistic.repository).to eq @repository
        expect(Statistic.new.repository).to eq @repository
        expect(Statistic.get(statistic.id).repository).to eq @repository
      end

      it 'Returns the repository defined by the current context' do
        @repository.scope do
          expect(@user_model.new.repository).to eq @repository
          expect(@user_model.create(name: 'carl').repository).to eq @repository
          expect(@user_model.get('carl').repository).to eq @repository
        end

        expect(@repository.scope { @user_model.get('carl') }.repository).to eq @repository
      end
    end
  end
end
