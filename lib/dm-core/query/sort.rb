# TODO: add #reverse and #reverse! methods

module DataMapper
  class Query
    class Sort
      # @api semipublic
      attr_reader :value

      # @api semipublic
      def direction
        @ascending ? :ascending : :descending
      end

      # @api private
      def <=>(other)
        other_value = other.value
        value_nil   = @value.nil?
        other_nil   = other_value.nil?

        cmp = if value_nil
                other_nil ? 0 : 1
              elsif other_nil
                -1
              else
                @value <=> other_value
              end

        @ascending ? cmp : cmp * -1
      end

      # @api private
      private def initialize(value, ascending = true)
        @value     = value
        @ascending = ascending
      end
    end
  end
end
