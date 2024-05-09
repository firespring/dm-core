require_relative '../../spec_helper'

describe DataMapper::Model::Hook do
  before :all do
    class ::ModelHookSpecs
      include DataMapper::Resource

      property :id, Serial
      property :value, Integer, :required => true, :default => 1

      def an_instance_method
      end
    end

    class ::ModelHookSpecsSubclass < ModelHookSpecs; end

    DataMapper.finalize
  end

  before :all do
    @resource = ModelHookSpecs.new
  end

  describe '#before' do
    describe 'an instance method' do
      before do
        @hooks = hooks = []
        ModelHookSpecs.before(:an_instance_method) { hooks << :before_instance_method }

        @resource.an_instance_method
      end

      it 'executes before instance method hook' do
        expect(@hooks).to eq [:before_instance_method]
      end
    end

    describe 'save' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.before(:save) { hooks << :before_save }

          @resource.save
        end

        it 'executes before save hook' do
          expect(@hooks).to eq [:before_save]
        end
      end
    end

    describe 'create' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.before(:create) { hooks << :before_create }

          @resource.save
        end

        it 'executes before create hook' do
          expect(@hooks).to eq [:before_create]
        end
      end
    end

    describe 'update' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.before(:update) { hooks << :before_update }

          @resource.save
          @resource.update(:value => 2)
        end

        it 'executes before update hook' do
          expect(@hooks).to eq [:before_update]
        end
      end
    end

    describe 'destroy' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.before(:destroy) { hooks << :before_destroy }

          @resource.save
          @resource.destroy
        end

        it 'executes before destroy hook' do
          expect(@hooks).to eq [:before_destroy]
        end
      end
    end

    describe 'with an inherited hook' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.before(:an_instance_method) { hooks << :inherited_hook }
        end

        it 'executes inherited hook' do
          ModelHookSpecsSubclass.new.an_instance_method
          expect(@hooks).to eq [:inherited_hook]
        end
      end
    end

    describe 'with a hook declared in the subclasss' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecsSubclass.before(:an_instance_method) { hooks << :hook }
        end

        it 'executes hook' do
          ModelHookSpecsSubclass.new.an_instance_method
          expect(@hooks).to eq [:hook]
        end

        it 'does not alter hooks in the parent class' do
          expect(@hooks).to be_empty
          ModelHookSpecs.new.an_instance_method
          expect(@hooks).to eq []
        end
      end
    end
  end

  describe '#after' do
    describe 'an instance method' do
      before do
        @hooks = hooks = []
        ModelHookSpecs.after(:an_instance_method) { hooks << :after_instance_method }

        @resource.an_instance_method
      end

      it 'executes after instance method hook' do
        expect(@hooks).to eq [:after_instance_method]
      end
    end

    describe 'save' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.after(:save) { hooks << :after_save }

          @resource.save
        end

        it 'executes after save hook' do
          expect(@hooks).to eq [:after_save]
        end
      end
    end

    describe 'create' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.after(:create) { hooks << :after_create }

          @resource.save
        end

        it 'executes after create hook' do
          expect(@hooks).to eq [:after_create]
        end
      end
    end

    describe 'update' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.after(:update) { hooks << :after_update }

          @resource.save
          @resource.update(:value => 2)
        end

        it 'executes after update hook' do
          expect(@hooks).to eq [:after_update]
        end
      end
    end

    describe 'destroy' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.after(:destroy) { hooks << :after_destroy }

          @resource.save
          @resource.destroy
        end

        it 'executes after destroy hook' do
          expect(@hooks).to eq [:after_destroy]
        end
      end
    end

    describe 'with an inherited hook' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecs.after(:an_instance_method) { hooks << :inherited_hook }
        end

        it 'executes inherited hook' do
          ModelHookSpecsSubclass.new.an_instance_method
          expect(@hooks).to eq [:inherited_hook]
        end
      end
    end

    describe 'with a hook declared in the subclasss' do
      supported_by :all do
        before do
          @hooks = hooks = []
          ModelHookSpecsSubclass.after(:an_instance_method) { hooks << :hook }
        end

        it 'executes hook' do
          ModelHookSpecsSubclass.new.an_instance_method
          expect(@hooks).to eq [:hook]
        end

        it 'does not alter hooks in the parent class' do
          expect(@hooks).to be_empty
          ModelHookSpecs.new.an_instance_method
          expect(@hooks).to eq []
        end
      end
    end
  end
end
