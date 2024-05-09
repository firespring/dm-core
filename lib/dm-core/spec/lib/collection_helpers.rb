module DataMapper
  module Spec
    module CollectionHelpers
      module GroupMethods
        def self.extended(base)
          base.class_inheritable_accessor :loaded
          base.loaded = false
          super
        end

        def should_not_be_a_kicker(ivar = :@articles)
          return if loaded

          it 'is not a kicker' do
            expect(instance_variable_get(ivar)).not_to be_loaded
          end
        end
      end
    end
  end
end
