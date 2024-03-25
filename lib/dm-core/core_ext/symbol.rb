class Symbol
  (DataMapper::Query::Conditions::Comparison.slugs | %i(not asc desc)).each do |sym|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{sym}
        #{"raise \"explicit use of '#{sym}' operator is deprecated (#{caller.first})\"" if %i(eql in).include?(sym)}
        DataMapper::Query::Operator.new(self, #{sym.inspect})
      end
    RUBY
  end
end
