module DataMapper
  class Query
    # The Conditions module contains classes used as part of a Query when
    # filtering collections of resources.
    #
    # The Conditions module contains two types of class used for filtering
    # queries: Comparison and Operation. Although these are used on all
    # repository types -- not just SQL-based repos -- these classes are best
    # thought of as being the DataMapper counterpart to an SQL WHERE clause.
    #
    # Comparisons compare properties and relationships with values, while
    # operations tie Comparisons together to form more complex expressions.
    #
    # For example, the following SQL query fragment:
    #
    #   ... WHERE my_field = my_value AND another_field = another_value ...
    #
    # ... would be represented as two EqualToComparison instances tied
    # together with an AndOperation.
    #
    # Conditions -- together with the Query class -- allow DataMapper to
    # represent SQL-like expressions in an ORM-agnostic manner, and are used
    # for both in-memory filtering of loaded Collection instances, and by
    # adapters to retrieve records directly from your repositories.
    #
    # The classes contained in the Conditions module are for internal use by
    # DataMapper and DataMapper plugins, and are not intended to be used
    # directly in your applications.
    module Conditions
      # An abstract class which provides easy access to comparison operators
      #
      # @example Creating a new comparison
      #   Comparison.new(:eql, MyClass.my_property, "value")
      #
      class Comparison
        # Creates a new Comparison instance
        #
        # The returned instance will be suitable for matching the given
        # subject (property or relationship) against the value.
        #
        # @param [Symbol] slug
        #   The type of comparison operator required. One of: :eql, :in, :gt,
        #   :gte, :lt, :lte, :regexp, :like.
        # @param [Property, Associations::Relationship]
        #   The subject of the comparison - the value of the subject will be
        #   matched against the given value parameter.
        # @param [Object] value
        #   The value for the comparison.
        #
        # @return [DataMapper::Query::Conditions::AbstractComparison]
        #
        # @example
        #   Comparison.new(:eql, MyClass.properties[:id], 1)
        #
        # @api semipublic
        def self.new(slug, subject, value)
          raise ArgumentError, "No Comparison class for #{slug.inspect} has been defined" unless (klass = comparison_class(slug))

          klass.new(subject, value)
        end

        # Returns an array of all slugs registered with Comparison
        #
        # @return [Array<Symbol>]
        #
        # @api private
        def self.slugs
          AbstractComparison.descendants.map(&:slug)
        end

        class << self
          # Holds comparison subclasses keyed on their slug
          #
          # @return [Hash]
          #
          # @api private
          private def comparison_classes
            @comparison_classes ||= {}
          end

          # Returns the comparison class identified by the given slug
          #
          # @param [Symbol] slug
          #   See slug parameter for Comparison.new
          #
          # @return [AbstractComparison, nil]
          #
          # @api private
          private def comparison_class(slug)
            comparison_classes[slug] ||= AbstractComparison.descendants.detect { |comparison_class| comparison_class.slug == slug }
          end
        end
      end

      # A base class for the various comparison classes.
      class AbstractComparison
        extend Equalizer

        equalize :subject, :value

        # @api semipublic
        attr_accessor :parent

        # The property or relationship which is being matched against
        #
        # @return [Property, Associations::Relationship]
        #
        # @api semipublic
        attr_reader :subject

        # Value to be compared with the subject
        #
        # This value is compared against that contained in the subject when
        # filtering collections, or the value in the repository when
        # performing queries.
        #
        # In the case of primitive property, this is the value as it
        # is stored in the repository.
        #
        # @return [Object]
        #
        # @api semipublic
        def value
          dumped_value
        end

        # The loaded/typecast value
        #
        # In the case of primitive types, this will be the same as +value+,
        # however when using primitive property this stores the loaded value.
        #
        # If writing an adapter, you should use +value+, while plugin authors
        # should refer to +loaded_value+.
        #
        #--
        # As an example, you might use symbols with the Enum type in dm-types
        #
        #   property :myprop, Enum[:open, :closed]
        #
        # These are stored in repositories as 1 and 2, respectively. +value+
        # returns the 1 or 2, while +loaded_value+ returns the symbol.
        #++
        #
        # @return [Object]
        #
        # @api semipublic
        attr_reader :loaded_value

        # Keeps track of AbstractComparison subclasses (used in Comparison)
        #
        # @return [Set<AbstractComparison>]
        # @api private
        def self.descendants
          @descendants ||= DescendantSet.new
        end

        # Registers AbstractComparison subclasses (used in Comparison)
        #
        # @api private
        def self.inherited(descendant)
          descendants << descendant
          super
        end

        # Setter/getter: allows subclasses to easily set their slug
        #
        # @param [Symbol] slug
        #   The slug to be set for this class. Passing nil returns the current
        #   value instead.
        #
        # @return [Symbol]
        #   The current slug set for the Comparison.
        #
        # @example Creating a MyComparison compairson with slug :exact.
        #   class MyComparison < AbstractComparison
        #     slug :exact
        #   end
        #
        # @api semipublic
        def self.slug(slug = nil)
          slug ? @slug = slug : @slug
        end

        # Return the comparison class slug
        #
        # @return [Symbol]
        #   the comparison class slug
        #
        # @api private
        def slug
          self.class.slug
        end

        # Test that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          match_property?(record)
        end

        # Tests that the Comparison is valid
        #
        # Subclasses can overload this to customise the means by which they
        # determine the validity of the comparison. #valid? is called prior to
        # performing a query on the repository: each Comparison within a Query
        # must be valid otherwise the query will not be performed.
        #
        # @see DataMapper::Property#valid?
        # @see DataMapper::Associations::Relationship#valid?
        #
        # @return [Boolean]
        #
        # @api semipublic
        def valid?
          valid_for_subject?(loaded_value)
        end

        # Returns whether the subject is a Relationship
        #
        # @return [Boolean]
        #
        # @api semipublic
        def relationship?
          false
        end

        # Returns whether the subject is a Property
        #
        # @return [Boolean]
        #
        # @api semipublic
        def property?
          subject.is_a?(Property)
        end

        # Returns a human-readable representation of this object
        #
        # @return [String]
        #
        # @api semipublic
        def inspect
          "#<#{self.class} @subject=#{@subject.inspect} " \
            "@dumped_value=#{@dumped_value.inspect} @loaded_value=#{@loaded_value.inspect}>"
        end

        # Returns a string version of this Comparison object
        #
        # @example
        #   Comparison.new(:==, MyClass.my_property, "value")
        #   # => "my_property == value"
        #
        # @return [String]
        #
        # @api semipublic
        def to_s
          "#{subject.name} #{comparator_string} #{dumped_value.inspect}"
        end

        # @api private
        def negated?
          parent = self.parent
          parent ? parent.negated? : false
        end

        # @api private
        attr_reader :dumped_value

        # Creates a new AbstractComparison instance with +subject+ and +value+
        #
        # @param [Property, Associations::Relationship] subject
        #   The subject of the comparison - the value of the subject will be
        #   matched against the given value parameter.
        # @param [Object] value
        #   The value for the comparison.
        #
        # @api semipublic
        private def initialize(subject, value)
          @subject      = subject
          @loaded_value = typecast(value)
          @dumped_value = dump
        end

        # @api private
        private def match_property?(record, operator = :===)
          expected.send(operator, record_value(record))
        end

        # Typecasts the given +val+ using subject#typecast
        #
        # If the subject has no typecast method the value is returned without
        # any changes.
        #
        # @param [Object] value
        #   The object to attempt to typecast.
        #
        # @return [Object]
        #   The typecasted object.
        #
        # @see Property#typecast
        #
        # @api private
        private def typecast(value)
          typecast_property(value)
        end

        # @api private
        private def typecast_property(value)
          subject.typecast(value)
        end

        # Dumps the given loaded_value using subject#value
        #
        # This converts property values to the primitive as stored in the
        # repository.
        #
        # @return [Object]
        #   The raw (dumped) object.
        #
        # @see Property#value
        #
        # @api private
        private def dump
          dump_property(loaded_value)
        end

        # @api private
        private def dump_property(value)
          subject.dump(value)
        end

        # Returns a value for the comparison +subject+
        #
        # Extracts value for the +subject+ property or relationship from the
        # given +record+, where +record+ is a Resource instance or a Hash.
        #
        # @param [DataMapper::Resource, Hash] record
        #   The resource or hash from which to retrieve the value.
        # @param [Property, Associations::Relationship]
        #   The subject of the comparison. For example, if this is a property,
        #   the value for the resources +subject+ property is retrieved.
        # @param [Symbol] key_type
        #   In the event that +subject+ is a relationship, key_type indicated
        #   which key should be used to retrieve the value from the resource.
        #
        # @return [Object]
        #
        # @api semipublic
        private def record_value(record, key_type = :source_key)
          subject = self.subject
          case record
          when Hash
            record_value_from_hash(record, subject, key_type)
          when Resource
            record_value_from_resource(record, subject, key_type)
          else
            record
          end
        end

        # Returns a value from a record hash
        #
        # Retrieves value for the +subject+ property or relationship from the
        # given +hash+.
        #
        # @return [Object]
        #
        # @see AbstractComparison#record_value
        #
        # @api private
        private def record_value_from_hash(hash, subject, key_type)
          hash.fetch subject, case subject
                              when Property
                                subject.load(hash[subject.field])
                              when Associations::Relationship
                                subject.send(key_type).map { |property| record_value_from_hash(hash, property, key_type) }
                              end
        end

        # Returns a value from a resource
        #
        # Extracts value for the +subject+ property or relationship from the
        # given +resource+.
        #
        # @return [Object]
        #
        # @see AbstractComparison#record_value
        #
        # @api private
        private def record_value_from_resource(resource, subject, key_type)
          case subject
          when Property
            subject.get!(resource)
          when Associations::Relationship
            subject.send(key_type).get!(resource)
          end
        end

        # Retrieves the value of the +subject+
        #
        # @return [Object]
        #
        # @api semipublic
        private def expected(value = @loaded_value)
          expected = record_value(value, :target_key)

          if @subject.respond_to?(:source_key)
            @subject.source_key.typecast(expected)
          else
            expected
          end
        end

        # Test the value to see if it is valid
        #
        # @return [Boolean] true if the value is valid
        #
        # @api semipublic
        private def valid_for_subject?(loaded_value)
          subject.valid?(loaded_value, negated?)
        end
      end

      # Included into comparisons which are capable of supporting
      # Relationships.
      module RelationshipHandler
        # Returns whether this comparison subject is a Relationship
        #
        # @return [Boolean]
        #
        # @api semipublic
        def relationship?
          subject.is_a?(Associations::Relationship)
        end

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          if relationship? && expected.respond_to?(:query)
            match_relationship?(record)
          else
            super
          end
        end

        # Returns the conditions required to match the subject relationship
        #
        # @return [Hash]
        #
        # @api semipublic
        def foreign_key_mapping
          relationship = subject.inverse
          relationship = relationship.links.first if relationship.respond_to?(:links)

          Query.target_conditions(value, relationship.source_key, relationship.target_key)
        end

        # @api private
        private def match_relationship?(record)
          expected.query.conditions.matches?(record_value(record))
        end

        # Typecasts each value in the inclusion set
        #
        # @return [Array<Object>]
        #
        # @see AbstractComparison#typecast
        #
        # @api private
        private def typecast(value)
          if relationship?
            typecast_relationship(value)
          else
            super
          end
        end

        # @api private
        private def dump
          if relationship?
            dump_relationship(loaded_value)
          else
            super
          end
        end

        # @api private
        private def dump_relationship(value)
          value
        end
      end

      # Tests whether the value in the record is equal to the expected
      # set for the Comparison.
      class EqualToComparison < AbstractComparison
        include RelationshipHandler

        slug :eql

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          if expected.nil?
            record_value(record).nil?
          else
            super
          end
        end

        # @api private
        private def typecast_relationship(value)
          case value
          when Hash     then typecast_hash(value)
          when Resource then typecast_resource(value)
          end
        end

        # @api private
        private def typecast_hash(hash)
          subject = self.subject
          subject.target_model.new(subject.query.merge(hash))
        end

        # @api private
        private def typecast_resource(resource)
          resource
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '='
        end
      end

      # Tests whether the value in the record is contained in the
      # expected set for the Comparison, where expected is an
      # Array, Range, or Set.
      class InclusionComparison < AbstractComparison
        include RelationshipHandler

        slug :in

        # Checks that the Comparison is valid
        #
        # @see DataMapper::Query::Conditions::AbstractComparison#valid?
        #
        # @return [Boolean]
        #
        # @api semipublic
        def valid?
          loaded_value = self.loaded_value
          case loaded_value
          when Collection then valid_collection?(loaded_value)
          when Range      then valid_range?(loaded_value)
          when Enumerable then valid_enumerable?(loaded_value)
          else
            false
          end
        end

        # @api private
        private def match_property?(record)
          super(record, :include?)
        end

        # Overloads AbstractComparison#expected
        #
        # @return [Array<Object>]
        # @see AbstractComparison#expected
        #
        # @api private
        private def expected
          loaded_value = self.loaded_value
          if loaded_value.is_a?(Range)
            typecast_range(loaded_value)
          elsif loaded_value.respond_to?(:map)
            # FIXME: causes a lazy load when a Collection
            loaded_value.map { |val| super(val) }
          else
            super
          end
        end

        # @api private
        private def valid_collection?(collection)
          valid_for_subject?(collection)
        end

        # @api private
        private def valid_range?(range)
          (range.any? || negated?) && valid_for_subject?(range.first) && valid_for_subject?(range.last)
        end

        # @api private
        private def valid_enumerable?(enumerable)
          (!enumerable.empty? || negated?) && enumerable.all? { |entry| valid_for_subject?(entry) }
        end

        # @api private
        private def typecast_property(value)
          if value.is_a?(Range)
            typecast_range(value)
          elsif value.respond_to?(:map) && !value.is_a?(String)
            value.map { |entry| super(entry) }
          else
            super
          end
        end

        # @api private
        private def typecast_range(range)
          range.class.new(typecast_property(range.first), typecast_property(range.last), range.exclude_end?)
        end

        # @api private
        private def typecast_relationship(value)
          case value
          when Hash       then typecast_hash(value)
          when Resource   then typecast_resource(value)
          when Collection then typecast_collection(value)
          when Enumerable then typecast_enumerable(value)
          end
        end

        # @api private
        private def typecast_hash(hash)
          subject = self.subject
          subject.target_model.all(subject.query.merge(hash))
        end

        # @api private
        private def typecast_resource(resource)
          resource.collection_for_self
        end

        # @api private
        private def typecast_collection(collection)
          collection
        end

        # @api private
        private def typecast_enumerable(enumerable)
          collection = nil
          enumerable.each do |entry|
            typecasted = typecast_relationship(entry)
            if collection
              collection |= typecasted
            else
              collection = typecasted
            end
          end
          collection
        end

        # Dumps the given +val+ using subject#value
        #
        # @return [Array<Object>]
        #
        # @see AbtractComparison#dump
        #
        # @api private
        private def dump
          loaded_value = self.loaded_value
          if subject.respond_to?(:dump) && loaded_value.respond_to?(:map) && !loaded_value.is_a?(Range)
            dumped_value = loaded_value.map { |value| dump_property(value) }
            dumped_value.uniq!
            dumped_value
          else
            super
          end
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          'IN'
        end
      end

      # Tests whether the value in the record matches the expected
      # regexp set for the Comparison.
      class RegexpComparison < AbstractComparison
        slug :regexp

        # Checks that the Comparison is valid
        #
        # @see AbstractComparison#valid?
        #
        # @api semipublic
        def valid?
          loaded_value.is_a?(Regexp)
        end

        # Returns the value untouched
        #
        # @return [Object]
        #
        # @api private
        private def typecast(value)
          value
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '=~'
        end
      end

      # Tests whether the value in the record is like the expected set
      # for the Comparison. Equivalent to a LIKE clause in an SQL database.
      #
      # TODO: move this to dm-more with DataObjectsAdapter plugins
      class LikeComparison < AbstractComparison
        slug :like

        # Overloads the +expected+ method in AbstractComparison
        #
        # Return a regular expression suitable for matching against the
        # records value.
        #
        # @return [Regexp]
        #
        # @see AbstractComparison#expected
        #
        # @api semipublic
        private def expected
          Regexp.new('\A' << super.gsub('%', '.*').tr('_', '.') << '\z')
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          'LIKE'
        end
      end

      # Tests whether the value in the record is greater than the
      # expected set for the Comparison.
      class GreaterThanComparison < AbstractComparison
        slug :gt

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          return false if expected.nil?

          record_value = record_value(record)
          !record_value.nil? && record_value > expected
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '>'
        end
      end

      # Tests whether the value in the record is less than the expected
      # set for the Comparison.
      class LessThanComparison < AbstractComparison
        slug :lt

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          return false if expected.nil?

          record_value = record_value(record)
          !record_value.nil? && record_value < expected
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '<'
        end
      end

      # Tests whether the value in the record is greater than, or equal to,
      # the expected set for the Comparison.
      class GreaterThanOrEqualToComparison < AbstractComparison
        slug :gte

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          return false if expected.nil?

          record_value = record_value(record)
          !record_value.nil? && record_value >= expected
        end

        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '>='
        end
      end

      # Tests whether the value in the record is less than, or equal to, the
      # expected set for the Comparison.
      class LessThanOrEqualToComparison < AbstractComparison
        slug :lte

        # Tests that the record value matches the comparison
        #
        # @param [Resource, Hash] record
        #   The record containing the value to be matched
        #
        # @return [Boolean]
        #
        # @api semipublic
        def matches?(record)
          return false if expected.nil?

          record_value = record_value(record)
          !record_value.nil? && record_value <= expected
        end

        # @return [String]
        #
        # @see AbstractComparison#to_s
        #
        # @api private
        private def comparator_string
          '<='
        end
      end
    end
  end
end
