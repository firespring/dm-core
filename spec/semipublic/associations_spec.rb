require 'spec_helper'

describe DataMapper::Associations do
  before :all do
    class ::Car
      include DataMapper::Resource

      property :id, Serial
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
  end

  def n
    1.0/0
  end

  describe '#has' do
    describe '1' do
      before :all do
        @relationship = Car.has(1, :engine)
      end

      it 'returns a Relationship' do
        expect(@relationship).to be_a_kind_of(DataMapper::Associations::OneToOne::Relationship)
      end

      it 'returns a Relationship with the child model' do
        expect(@relationship.child_model).to eq Engine
      end

      it 'returns a Relationship with a min of 1' do
        expect(@relationship.min).to eq 1
      end

      it 'returns a Relationship with a max of 1' do
        expect(@relationship.max).to eq 1
      end
    end

    describe 'n..n' do
      before :all do
        @relationship = Car.has(1..4, :doors)
      end

      it 'returns a Relationship' do
        expect(@relationship).to be_a_kind_of(DataMapper::Associations::OneToMany::Relationship)
      end

      it 'returns a Relationship with the child model' do
        expect(@relationship.child_model).to eq Door
      end

      it 'returns a Relationship with a min of 1' do
        expect(@relationship.min).to eq 1
      end

      it 'returns a Relationship with a max of 4' do
        expect(@relationship.max).to eq 4
      end
    end

    describe 'n..n through' do
      before :all do
        Door.has(1, :window)
        Car.has(1..4, :doors)

        @relationship = Car.has(1..4, :windows, :through => :doors)
      end

      it 'returns a Relationship' do
        expect(@relationship).to be_a_kind_of(DataMapper::Associations::ManyToMany::Relationship)
      end

      it 'returns a Relationship with the child model' do
        expect(@relationship.child_model).to eq Window
      end

      it 'returns a Relationship with a min of 1' do
        expect(@relationship.min).to eq 1
      end

      it 'returns a Relationship with a max of 4' do
        expect(@relationship.max).to eq 4
      end
    end

    describe 'n' do
      before :all do
        @relationship = Car.has(n, :doors)
      end

      it 'returns a Relationship' do
        expect(@relationship).to be_a_kind_of(DataMapper::Associations::OneToMany::Relationship)
      end

      it 'returns a Relationship with the child model' do
        expect(@relationship.child_model).to eq Door
      end

      it 'returns a Relationship with a min of 0' do
        expect(@relationship.min).to eq 0
      end

      it 'returns a Relationship with a max of n' do
        expect(@relationship.max).to eq n
      end
    end

    describe 'n through' do
      before :all do
        Door.has(1, :windows)
        Car.has(1..4, :doors)

        @relationship = Car.has(n, :windows, :through => :doors)
      end

      it 'returns a Relationship' do
        expect(@relationship).to be_a_kind_of(DataMapper::Associations::ManyToMany::Relationship)
      end

      it 'returns a Relationship with the child model' do
        expect(@relationship.child_model).to eq Window
      end

      it 'returns a Relationship with a min of 0' do
        expect(@relationship.min).to eq 0
      end

      it 'returns a Relationship with a max of n' do
        expect(@relationship.max).to eq n
      end
    end
  end

  describe '#belongs_to' do
    before :all do
      @relationship = Engine.belongs_to(:car)
    end

    it 'returns a Relationship' do
      expect(@relationship).to be_a_kind_of(DataMapper::Associations::ManyToOne::Relationship)
    end

    it 'returns a Relationship with the parent model' do
      expect(@relationship.parent_model).to eq Car
    end

    it 'returns a Relationship with a min of 1' do
      expect(@relationship.min).to eq 1
    end

    it 'returns a Relationship with a max of 1' do
      expect(@relationship.max).to eq 1
    end

    it 'returns a Relationship that is required' do
      expect(@relationship.required?).to be(true)
    end
  end
end
