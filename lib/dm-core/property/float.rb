module DataMapper
  class Property
    class Float < Numeric
      load_as ::Float
      dump_as ::Float

      DEFAULT_PRECISION = 10
      DEFAULT_SCALE     = nil

      precision(DEFAULT_PRECISION)
      scale(DEFAULT_SCALE)

      # Typecast a value to a Float
      #
      # @param [#to_str, #to_f] value
      #   value to typecast
      #
      # @return [Float]
      #   Float constructed from value
      #
      # @api private
      protected def typecast_to_primitive(value)
        typecast_to_numeric(value, :to_f)
      end
    end
  end
end
