module DataMapper
  class Property
    class Integer < Numeric
      load_as ::Integer
      dump_as ::Integer

      accept_options :serial

      # @api semipublic
      protected def initialize(model, name, options = {})
        if options.key?(:serial) && !is_a?(Serial)
          raise "Integer #{name} with explicit :serial option is deprecated, use Serial instead (#{caller[2]})"
        end

        super
      end

      # Typecast a value to an Integer
      #
      # @param [#to_str, #to_i] value
      #   value to typecast
      #
      # @return [Integer]
      #   Integer constructed from value
      #
      # @api private
      protected def typecast_to_primitive(value)
        typecast_to_numeric(value, :to_i)
      end
    end
  end
end
