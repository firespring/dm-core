module DataMapper
  class Property
    class Binary < String
      if RUBY_VERSION >= '1.9'

        def load(value)
          super.dup.force_encoding('BINARY') unless value.nil?
        end

        def dump(value)
          value&.dup&.force_encoding('BINARY')
        rescue
          value
        end

      end
    end
  end
end
