module DataMapper
  class Property
    class HugeInteger < DataMapper::Property::String
      def load(value)
        value&.to_i
      end

      def dump(value)
        value&.to_s
      end

      def typecast(value)
        load(value)
      end
    end
  end
end
