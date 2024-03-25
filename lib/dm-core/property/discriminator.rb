module DataMapper
  class Property
    class Discriminator < Class
      default   ->(resource, _property) { resource.model }
      required  true

      # @api private
      def bind
        model.extend Model unless model < Model
      end

      module Model
        def inherited(model)
          super # setup self.descendants
          set_discriminator_scope_for(model)
        end

        def new(*args, &block)
          if args.size == 1 && args.first.is_a?(Hash)
            discriminator = properties(repository_name).discriminator

            if (discriminator_value = args.first[discriminator.name])
              model = discriminator.typecast_to_primitive(discriminator_value)

              return model.new(*args, &block) if model.is_a?(Model) && !model.equal?(self)
            end
          end

          super
        end

        private def set_discriminator_scope_for(model)
          discriminator = properties.discriminator
          default_scope = model.default_scope(discriminator.repository_name)
          default_scope.update(discriminator.name => model.descendants.dup << model)
        end
      end
    end
  end
end
