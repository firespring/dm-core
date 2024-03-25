module DataMapper
  class Property
    class Text < String
      length  65_535
      lazy    true

      def primitive?(value)
        value.is_a?(::String)
      end
    end
  end
end
