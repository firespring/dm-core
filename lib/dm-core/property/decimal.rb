module DataMapper
  class Property
    class Decimal < Numeric
      load_as BigDecimal
      dump_as BigDecimal

      DEFAULT_PRECISION = 10
      DEFAULT_SCALE     = 0

      precision(DEFAULT_PRECISION)
      scale(DEFAULT_SCALE)

      protected def initialize(model, name, options = {})
        super

        %i(scale precision).each do |key|
          unless @options.key?(key)
            warn "options[#{key.inspect}] should be set for #{self.class}, defaulting to #{send(key).inspect} (#{caller.first})"
          end
        end

        raise ArgumentError, "scale must be equal to or greater than 0, but was #{@scale.inspect}" unless @scale >= 0

        return if @precision >= @scale

        raise ArgumentError, "precision must be equal to or greater than scale, but was #{@precision.inspect} and scale was #{@scale.inspect}"
      end

      # Typecast a value to a BigDecimal
      #
      # @param [#to_str, #to_d, Integer] value
      #   value to typecast
      #
      # @return [BigDecimal]
      #   BigDecimal constructed from value
      #
      # @api private
      protected def typecast_to_primitive(value)
        if value.is_a?(::Integer)
          value.to_s.to_d
        else
          typecast_to_numeric(value, :to_d)
        end
      end
    end
  end
end
