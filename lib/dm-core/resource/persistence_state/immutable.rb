module DataMapper
  module Resource
    class PersistenceState
      # a not-persisted/unmodifiable resource
      class Immutable < PersistenceState
        def get(subject, *args)
          unless subject.loaded?(resource) || subject.is_a?(Associations::Relationship)
            raise ImmutableError, 'Immutable resource cannot be lazy loaded'
          end

          super
        end

        def set(_subject, _value)
          raise ImmutableError, 'Immutable resource cannot be modified'
        end

        def delete
          raise ImmutableError, 'Immutable resource cannot be deleted'
        end

        def commit
          self
        end

        def rollback
          self
        end
      end
    end
  end
end
