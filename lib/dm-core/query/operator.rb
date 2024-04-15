# TODO: rename this DM::Symbol::Operator

# TODO: add a method to convert it into a DM::Query::AbstractComparison object, eg:
#   operator.comparison_for(repository, model)

# TODO: rename #target to #property_name

module DataMapper
  class Query
    class Operator
      include DataMapper::Assertions
      extend Equalizer

      equalize :target, :operator

      # @api private
      attr_reader :target

      # @api private
      attr_reader :operator

      # @api private
      def inspect
        "#<#{self.class.name} @target=#{target.inspect} @operator=#{operator.inspect}>"
      end

      # @api private
      private def initialize(target, operator)
        @target = target
        @operator = operator.to_sym
      end
    end
  end
end
