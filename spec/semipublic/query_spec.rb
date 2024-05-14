require_relative '../spec_helper'

require 'ostruct'

# TODO: make some of specs for Query.new shared.  the assertions and
# normalizations should happen for Query#update, Query#relative and
# Query#merge and should probably be in shared specs

# class methods
describe DataMapper::Query do
  before :all do
    class ::Password < DataMapper::Property::String
      length    40
    end

    class ::User
      include DataMapper::Resource

      property :name,     String,   :key => true
      property :password, Password
      property :balance,  Decimal, :precision => 5, :scale => 2

      belongs_to :referrer, self, :required => false
      has n, :referrals, self, :inverse => :referrer
    end

    @repository = DataMapper::Repository.new(:default)
    @model      = User

    @fields       = [ :name ].freeze
    @links        = [ :referrer ].freeze
    @conditions   = { :name => 'Dan Kubb' }
    @offset       = 0
    @limit        = 1
    @order        = [ :name ].freeze
    @unique       = false
    @add_reversed = false
    @reload       = false

    @options = {
      :fields       => @fields,
      :links        => @links,
      :conditions   => @conditions,
      :offset       => @offset,
      :limit        => @limit,
      :order        => @order,
      :unique       => @unique,
      :add_reversed => @add_reversed,
      :reload       => @reload,
    }
  end

  it { expect(DataMapper::Query).to respond_to(:new) }

  describe '.new' do
    describe 'with a repository' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the repository' do
          expect(@return.repository).to eq @repository
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new('invalid', @model, @options)
          }.to raise_error(ArgumentError, '+repository+ should be DataMapper::Repository, but was String')
        end
      end
    end

    describe 'with a model' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the model' do
          expect(@return.model).to eq @model
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, 'invalid', @options)
          }.to raise_error(ArgumentError, '+model+ should be DataMapper::Model, but was String')
        end
      end
    end

    describe 'with a fields option' do
      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the fields' do
          expect(@return.fields).to eq @model.properties.values_at(*@fields)
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:fields] = [ 'name' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the fields' do
          expect(@return.fields).to eq @model.properties.values_at('name')
        end
      end

      describe 'that is an Array containing a Property' do
        before :all do
          @options[:fields] = @model.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the fields' do
          expect(@return.fields).to eq @model.properties.values_at(:name)
        end
      end

      describe 'that is an Array containing a Property from an ancestor' do
        before :all do
          class ::Contact < User; end

          @options[:fields] = User.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, Contact, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the fields' do
          expect(@return.fields).to eq User.properties.values_at(:name)
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:fields).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets fields to the model default properties' do
          expect(@return.fields).to eq @model.properties.defaults
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => :name))
          }.to raise_error(StandardError)
        end
      end

      describe 'that is an Array containing an unknown Symbol' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ :unknown ]))
          }.to raise_error(ArgumentError, "+options[:fields]+ entry :unknown does not map to a property in #{@model}")
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ 'unknown' ]))
          }.to raise_error(ArgumentError, "+options[:fields]+ entry \"unknown\" does not map to a property in #{@model}")
        end
      end
    end

    describe 'with a links option' do
      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the links' do
          expect(@return.links).to eq @model.relationships.values_at(*@links)
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:links] = [ 'referrer' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the links' do
          expect(@return.links).to eq @model.relationships.values_at('referrer')
        end
      end

      describe 'that is an Array containing a Relationship' do
        before :all do
          @options[:links] = @model.relationships.values_at(:referrer)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the links' do
          expect(@return.links).to eq @model.relationships.values_at(:referrer)
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:links).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets links to an empty Array' do
          expect(@return.links).to eq []
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:links => :referral))
          }.to raise_error(StandardError)
        end
      end

      describe 'that is an empty Array' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:links => []))
          }.to raise_error(ArgumentError, '+options[:links]+ should not be empty')
        end
      end

      describe 'that is an Array containing an unknown Symbol' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:links => [ :unknown ]))
          }.to raise_error(ArgumentError, "+options[:links]+ entry :unknown does not map to a relationship in #{@model}")
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:links => [ 'unknown' ]))
          }.to raise_error(ArgumentError, "+options[:links]+ entry \"unknown\" does not map to a relationship in #{@model}")
        end
      end
    end

    describe 'with a conditions option' do
      describe 'that is a valid Hash' do
        describe 'with the Property key' do
          before :all do
            @options[:conditions] = { @model.properties[:name] => 'Dan Kubb' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with the Symbol key mapping to a Property' do
          before :all do
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with the String key mapping to a Property' do
          before :all do
            @options[:conditions] = { 'name' => 'Dan Kubb' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        supported_by :all do
          describe 'with the Symbol key mapping to a Relationship' do
            before :all do
              @user = @model.create(:name => 'Dan Kubb')

              @options[:conditions] = { :referrer => @user }

              @return = DataMapper::Query.new(@repository, @model, @options.freeze)
            end

            it { expect(@return).to be_kind_of(DataMapper::Query) }

            it 'sets the conditions' do
              expect(@return.conditions).to eq
                DataMapper::Query::Conditions::Operation.new(
                  :and,
                  DataMapper::Query::Conditions::Comparison.new(
                    :eql,
                    @model.relationships[:referrer],
                    @user
                  )
                )
            end

            it 'is valid' do
              expect(@return).to be_valid
            end
          end

          describe 'with the String key mapping to a Relationship' do
            before :all do
              @user = @model.create(:name => 'Dan Kubb')

              @options[:conditions] = { 'referrer' => @user }

              @return = DataMapper::Query.new(@repository, @model, @options.freeze)
            end

            it { expect(@return).to be_kind_of(DataMapper::Query) }

            it 'sets the conditions' do
              expect(@return.conditions).to eq
                DataMapper::Query::Conditions::Operation.new(
                  :and,
                  DataMapper::Query::Conditions::Comparison.new(
                    :eql,
                    @model.relationships['referrer'],
                    @user
                  )
                )
            end

            it 'is valid' do
              expect(@return).to be_valid
            end
          end

          describe 'with the Symbol key mapping to a Relationship and a nil value' do
            before :all do
              @options[:conditions] = { :referrer => nil }

              @return = DataMapper::Query.new(@repository, @model, @options.freeze)
            end

            it { expect(@return).to be_kind_of(DataMapper::Query) }

            it 'sets the conditions' do
              expect(@return.conditions).to eq
                DataMapper::Query::Conditions::Operation.new(
                  :and,
                  DataMapper::Query::Conditions::Comparison.new(
                    :eql,
                    @model.relationships[:referrer],
                    nil
                  )
                )
            end

            it 'is valid' do
              expect(@return).to be_valid
            end
          end

          describe 'with the Symbol key mapping to a Relationship and an empty Array' do
            before :all do
              @options[:conditions] = { :referrer => [] }

              @return = DataMapper::Query.new(@repository, @model, @options.freeze)
            end

            it { expect(@return).to be_kind_of(DataMapper::Query) }

            it 'sets the conditions' do
              expect(@return.conditions).to eq
                DataMapper::Query::Conditions::Operation.new(
                  :and,
                  DataMapper::Query::Conditions::Comparison.new(
                    :in,
                    @model.relationships[:referrer],
                    []
                  )
                )
            end

            it 'is invalid' do
              expect(@return).not_to be_valid
            end
          end
        end

        describe 'with the Query::Operator key' do
          before :all do
            @options[:conditions] = { :name.gte => 'Dan Kubb' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :gte,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with the Query::Path key' do
          before :all do
            @options[:conditions] = { @model.referrer.name => 'Dan Kubb' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          xit 'does not set the conditions' do
            expect(@return.conditions).to be_nil
          end

          it 'sets the links' do
            expect(@return.links).to eq [ @model.relationships[:referrals], @model.relationships[:referrer] ]
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with the String key mapping to a Query::Path' do
          before :all do
            @options[:conditions] = { 'referrer.name' => 'Dan Kubb' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          xit 'does not set the conditions' do
            expect(@return.conditions).to be_nil
          end

          it 'sets the links' do
            expect(@return.links).to eq [ @model.relationships[:referrals], @model.relationships[:referrer] ]
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with an Array with 1 entry' do
          before :all do
            @options[:conditions] = { :name => [ 'Dan Kubb' ] }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          xit 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with an Array with no entries' do
          before :all do
            @options[:conditions] = { :name => [] }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          xit 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'
                )
              )
          end

          it 'is not valid' do
            expect(@return).not_to be_valid
          end
        end

        describe 'with an Array with duplicate entries' do
          before :all do
            @options[:conditions] = { :name => [ 'John Doe', 'Dan Kubb', 'John Doe' ] }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :in,
                  @model.properties[:name],
                  [ 'John Doe', 'Dan Kubb' ]
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with a Property subclass' do
          before :all do
            @options[:conditions] = { :password => 'password' }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:password],
                  'password'
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with a Symbol for a String property' do
          before :all do
            @options[:conditions] = { :name => 'Dan Kubb'.to_sym }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:name],
                  'Dan Kubb'  # typecast value
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end

        describe 'with a Float for a Decimal property' do
          before :all do
            @options[:conditions] = { :balance => 50.5 }
            @return = DataMapper::Query.new(@repository, @model, @options.freeze)
          end

          it { expect(@return).to be_kind_of(DataMapper::Query) }

          it 'sets the conditions' do
            expect(@return.conditions).to eq
              DataMapper::Query::Conditions::Operation.new(
                :and,
                DataMapper::Query::Conditions::Comparison.new(
                  :eql,
                  @model.properties[:balance],
                  BigDecimal('50.5')  # typecast value
                )
              )
          end

          it 'is valid' do
            expect(@return).to be_valid
          end
        end
      end

      describe 'that is a valid Array' do
        before :all do
          @options[:conditions] = [ 'name = ?', 'Dan Kubb' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and, [ 'name = ?', [ 'Dan Kubb' ] ])
        end

        it 'is valid' do
          expect(@return).to be_valid
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:conditions).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets conditions to nil by default' do
          expect(@return.conditions).to be_nil
        end

        it 'is valid' do
          expect(@return).to be_valid
        end
      end

      describe 'that is an empty Array' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => []))
          }.to raise_error(ArgumentError, '+options[:conditions]+ should not be empty')
        end
      end

      describe 'that is an Array with a blank statement' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => [ ' ' ]))
          }.to raise_error(ArgumentError, '+options[:conditions]+ should have a statement for the first entry')
        end
      end

      describe 'that is a Hash with a Symbol key that is not for a Property in the model' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => { :unknown => 1 }))
          }.to raise_error(ArgumentError, "condition :unknown does not map to a property or relationship in #{@model}")
        end
      end

      describe 'that is a Hash with a String key that is not for a Property in the model' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => { 'unknown' => 1 }))
          }.to raise_error(ArgumentError, "condition \"unknown\" does not map to a property or relationship in #{@model}")
        end
      end

      describe 'that is a Hash with a String key that is a Path and not for a Relationship in the model' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => { 'unknown.id' => 1 }))
          }.to raise_error(ArgumentError, "condition \"unknown.id\" does not map to a property or relationship in #{@model}")
        end
      end
    end

    describe 'with an offset option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the offset' do
          expect(@return.offset).to eq @offset
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:offset).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets offset to 0' do
          expect(@return.offset).to eq 0
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:offset => '0'))
          }.to raise_error(StandardError)
        end
      end

      describe 'that is less than 0' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:offset => -1))
          }.to raise_error(ArgumentError, '+options[:offset]+ must be greater than or equal to 0, but was -1')
        end
      end

      describe 'that is greater than 0 and a nil limit' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.except(:limit).update(:offset => 1))
          }.to raise_error(ArgumentError, '+options[:offset]+ cannot be greater than 0 if limit is not specified')
        end
      end
    end

    describe 'with a limit option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the limit' do
          expect(@return.limit).to eq @limit
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:limit).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets limit to nil' do
          expect(@return.limit).to be_nil
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:limit => '1'))
          }.to raise_error(StandardError)
        end
      end

      describe 'that is less than 0' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:limit => -1))
          }.to raise_error(ArgumentError, '+options[:limit]+ must be greater than or equal to 0, but was -1')
        end
      end
    end

    describe 'with an order option' do
      describe 'that is a single Symbol' do
        before :all do
          @options[:order] = :name
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is a single String' do
        before :all do
          @options[:order] = 'name'
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is a single Property' do
        before :all do
          @options[:order] = @model.properties.values_at(:name)
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that contains a Query::Direction with a property that is not part of the model' do
        before :all do
          @property = DataMapper::Property::String.new(@model, :unknown)
          @direction = DataMapper::Query::Direction.new(@property, :desc)
          @return = DataMapper::Query.new(@repository, @model, @options.update(:order => [ @direction ]))
        end

        it 'sets the order, since it may map to a joined model' do
          expect(@return.order).to eq [ @direction ]
        end
      end

      describe 'that contains a Property that is not part of the model' do
        before :all do
          @property = DataMapper::Property::String.new(@model, :unknown)
          @return = DataMapper::Query.new(@repository, @model, @options.update(:order => [ @property ]))
        end

        it 'sets the order, since it may map to a joined model' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@property) ]
        end
      end

      describe 'that contains a Query::Path to a property on a linked model' do
        before :all do
          @property = @model.referrer.name
          @return = DataMapper::Query.new(@repository, @model, @options.update(:order => [ @property ]))
        end

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:order] = [ 'name' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a Property' do
        before :all do
          @options[:order] = @model.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a Property from an ancestor' do
        before :all do
          class ::Contact < User; end

          @options[:order] = User.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, Contact, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(User.properties[:name]) ]
        end
      end

      describe 'that is an Array containing an Operator' do
        before :all do
          @options[:order] = [ :name.asc ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name], :asc) ]
        end
      end

      describe 'that is an Array containing an Query::Direction' do
        before :all do
          @options[:order] = [ DataMapper::Query::Direction.new(@model.properties[:name], :asc) ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name], :asc) ]
        end
      end

      describe 'that is an Array containing an Query::Direction with a Property from an ancestor' do
        before :all do
          class ::Contact < User; end

          @options[:order] = [ DataMapper::Query::Direction.new(User.properties[:name], :asc) ]

          @return = DataMapper::Query.new(@repository, Contact, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the order' do
          expect(@return.order).to eq [ DataMapper::Query::Direction.new(User.properties[:name], :asc) ]
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:order).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets order to the model default order' do
          expect(@return.order).to eq @model.default_order(@repository.name)
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:order => 'unknown'))
          }.to raise_error(ArgumentError, "+options[:order]+ entry \"unknown\" does not map to a property in #{@model}")
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [ 'unknown' ]))
          }.to raise_error(ArgumentError, "+options[:order]+ entry \"unknown\" does not map to a property in #{@model}")
        end
      end

      describe 'that contains a Symbol that is not for a Property in the model' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [ :unknown ]))
          }.to raise_error(ArgumentError, "+options[:order]+ entry :unknown does not map to a property in #{@model}")
        end
      end

      describe 'that contains a String that is not for a Property in the model' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [ 'unknown' ]))
          }.to raise_error(ArgumentError, "+options[:order]+ entry \"unknown\" does not map to a property in #{@model}")
        end
      end
    end

    describe 'with a unique option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the unique? flag' do
          expect(@return.unique?).to eq @unique
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:unique, :links).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the query to not be unique' do
          expect(@return).not_to be_unique
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:unique => nil))
          }.to raise_error(ArgumentError, '+options[:unique]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with an add_reversed option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the add_reversed? flag' do
          expect(@return.add_reversed?).to eq @add_reversed
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:add_reversed).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the query to not add in reverse order' do
          # TODO: think about renaming the flag to not sound 'clumsy'
          expect(@return).not_to be_add_reversed
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:add_reversed => nil))
          }.to raise_error(ArgumentError, '+options[:add_reversed]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with a reload option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the reload? flag' do
          expect(@return.reload?).to eq @reload
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:reload).freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the query to not reload' do
          expect(@return).not_to be_reload
        end
      end

      describe 'that is invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, @options.update(:reload => nil))
          }.to raise_error(ArgumentError, '+options[:reload]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with options' do
      describe 'that are unknown' do
        before :all do
          @options.update(@options.delete(:conditions))

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'sets the conditions' do
          expect(@return.conditions).to eq
            DataMapper::Query::Conditions::Operation.new(
              :and,
              DataMapper::Query::Conditions::Comparison.new(
                :eql,
                @model.properties[:name],
                @conditions[:name]
              )
            )
        end
      end

      describe 'that are invalid' do
        it 'raises an exception' do
          expect {
            DataMapper::Query.new(@repository, @model, 'invalid')
          }.to raise_error(StandardError)
        end
      end
    end

    describe 'with no options' do
      before :all do
        @return = DataMapper::Query.new(@repository, @model)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'sets options to an empty Hash' do
        expect(@return.options).to eq {}
      end
    end
  end
end

# instance methods
describe DataMapper::Query do
  before :all do
    class ::User
      include DataMapper::Resource

      property :name,        String, :key => true
      property :citizenship, String

      belongs_to :referrer, self, :required => false
      has n, :referrals,    self, :inverse => :referrer
      has n, :grandparents, self, :through => :referrals, :via => :referrer
    end

    class ::Other
      include DataMapper::Resource

      property :id, Serial
    end

    # finalize the models
    DataMapper.finalize

    @repository = DataMapper::Repository.new(:default)
    @model      = User
    @options    = { :limit => 3 }
    @query      = DataMapper::Query.new(@repository, @model, @options)
    @original   = @query
  end

  before :all do
    @other_options = {
      :fields       => [ @model.properties[:name] ].freeze,
      :links        => [ @model.relationships[:referrer] ].freeze,
      :conditions   => [ 'name = ?', 'Dan Kubb' ].freeze,
      :offset       => 1,
      :limit        => 2,
      :order        => [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ].freeze,
      :unique       => true,
      :add_reversed => true,
      :reload       => true,
    }
  end

  subject { @query }

  it { is_expected.to respond_to(:==) }

  describe '#==' do
    describe 'when other is equal' do
      before :all do
        @return = @query == @query
      end

      it { expect(@return).to be(true) }
    end

    describe 'when other is equivalent' do
      before :all do
        @return = @query == @query.dup
      end

      it { expect(@return).to be(true) }
    end

    DataMapper::Query::OPTIONS.each do |name|
      describe "when other has an inequalvalent #{name}" do
        before :all do
          @return = @query == @query.merge(name => @other_options[name])
        end

        it { expect(@return).to be(false) }
      end
    end

    describe 'when other is a different type of object that can be compared, and is equivalent' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :sorted_fields => @query.sorted_fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => @query.reload?,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query == @other
      end

      it { expect(@return).to be(false) }
    end

    describe 'when other is a different type of object that can be compared, and is not equivalent' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :sorted_fields => @query.sorted_fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => true,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query == @other
      end

      it { expect(@return).to be(false) }
    end

    describe 'when other is a different type of object that cannot be compared' do
      before :all do
        @return = @query == 'invalid'
      end

      it { expect(@return).to be(false) }
    end
  end

  it { is_expected.to respond_to(:conditions) }

  describe '#conditions' do
    before :all do
      @query.update(:name => 'Dan Kubb')

      @return = @query.conditions
    end

    it { expect(@return).to be_kind_of(DataMapper::Query::Conditions::AndOperation) }

    it 'returns expected value' do
      expect(@return).to eq
        DataMapper::Query::Conditions::Operation.new(
          :and,
          DataMapper::Query::Conditions::Comparison.new(
            :eql,
            @model.properties[:name],
            'Dan Kubb'
          )
        )
    end
  end

  [ :difference, :- ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      supported_by :all do
        before :all do
          @key = @model.key(@repository.name)

          @self_relationship = DataMapper::Associations::OneToMany::Relationship.new(
            :self,
            @model,
            @model,
            {
              :child_key              => @key.map { |p| p.name },
              :parent_key             => @key.map { |p| p.name },
              :child_repository_name  => @repository.name,
              :parent_repository_name => @repository.name,
            }
          )

          10.times do |n|
            @model.create(:name => "#{@model} #{n}")
          end
        end

        subject { @query.send(method, @other) }

        describe 'with other matching everything' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model)

            @expected = DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'factors out the operation matching everything' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self matching everything' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:not,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'factors out the operation matching everything, and negate the other' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@other.merge(:fields => @key)))
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@other.merge(:fields => @key)))
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other query' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:in, @self_relationship, @model.all(@other.merge(:fields => @key)))
              )
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together, and negate the other query' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different conditions, no links/offset/limit' do
          before do
            property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model, property.name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, property.name => 'John Doe')

            expect(@query.conditions).not_to eq @other.conditions

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, property, 'Dan Kubb'),
              DataMapper::Query::Conditions::Operation.new(:not,
                DataMapper::Query::Conditions::Comparison.new(:eql, property, 'John Doe')
              )
            )
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it "AND's the conditions together, and negate the other query" do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different fields' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :fields => [ @property ])

            expect(@query.fields).not_to eq @other.fields
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and) }

          it 'uses the other fields' do
            expect(subject.fields).to eq [ @property ]
          end
        end

        describe 'with different order' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :order => [ DataMapper::Query::Direction.new(@property, :desc) ])

            expect(@query.order).not_to eq @other.order
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and) }

          it 'uses the other order' do
            expect(subject.order).to eq [ DataMapper::Query::Direction.new(@property, :desc) ]
          end
        end

        describe 'with different unique' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :unique => true)

            expect(@query.unique?).not_to eq @other.unique?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and) }

          it 'uses the other unique' do
            expect(subject.unique?).to eq true
          end
        end

        describe 'with different add_reversed' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :add_reversed => true)

            expect(@query.add_reversed?).not_to eq @other.add_reversed?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and) }

          it 'uses the other add_reversed' do
            expect(subject.add_reversed?).to eq true
          end
        end

        describe 'with different reload' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :reload => true)

            expect(@query.reload?).not_to eq @other.reload?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and) }

          it 'uses the other reload' do
            expect(subject.reload?).to eq true
          end
        end

        describe 'with different models' do
          before { @other = DataMapper::Query.new(@repository, Other) }

          it { expect { method(:subject) }.to raise_error(ArgumentError) }
        end
      end
    end
  end

  it { is_expected.to respond_to(:dup) }

  describe '#dup' do
    before :all do
      @new = @query.dup
    end

    it 'returns a Query' do
      expect(@new).to be_kind_of(DataMapper::Query)
    end

    it 'does not equal query' do
      expect(@new).not_to equal(@query)
    end

    it "eql's query" do
      expect(@new).to eql(@query)
    end

    it "=='s query" do
      expect(@new).to eq @query
    end
  end

  it { is_expected.to respond_to(:eql?) }

  describe '#eql?' do
    describe 'when other is equal' do
      before :all do
        @return = @query.eql?(@query)
      end

      it { expect(@return).to be(true) }
    end

    describe 'when other is eql' do
      before :all do
        @return = @query.eql?(@query.dup)
      end

      it { expect(@return).to be(true) }
    end

    DataMapper::Query::OPTIONS.each do |name|
      describe "when other has an not eql #{name}" do
        before :all do
          @return = @query.eql?(@query.merge(name => @other_options[name]))
        end

        it { expect(@return).to be(false) }
      end
    end

    describe 'when other is a different type of object' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :sorted_fields => @query.sorted_fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => @query.reload?,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query.eql?(@other)
      end

      it { expect(@return).to be(false) }
    end
  end

  it { is_expected.to respond_to(:fields) }

  describe '#fields' do
    before :all do
      @return = @query.fields
    end

    it { expect(@return).to be_kind_of(Array) }

    it 'returns expected value' do
      expect(@return).to eq [ @model.properties[:name], @model.properties[:citizenship], @model.properties[:referrer_name] ]
    end
  end

  it { is_expected.to respond_to(:filter_records) }

  describe '#filter_records' do
    supported_by :all do
      before :all do
        @john = { 'name' => 'John Doe',  'referrer_name' => nil         }
        @sam  = { 'name' => 'Sam Smoot', 'referrer_name' => nil         }
        @dan  = { 'name' => 'Dan Kubb',  'referrer_name' => 'Sam Smoot' }

        @records = [ @john, @sam, @dan ]

        @query.update(:name.not => @sam['name'])

        @return = @query.filter_records(@records)
      end

      it 'returns Enumerable' do
        expect(@return).to be_kind_of(Enumerable)
      end

      it 'are not the records provided' do
        expect(@return).not_to equal(@records)
      end

      it 'returns expected values' do
        expect(@return).to eq [ @dan, @john ]
      end
    end
  end

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    before :all do
      @return = @query.inspect
    end

    it 'returns expected value' do
      expect(@return).to eq DataMapper::Ext::String.compress_lines(<<-INSPECT)
        #<DataMapper::Query
          @repository=:default
          @model=User
          @fields=[#<DataMapper::Property::String @model=User @name=:name>, #<DataMapper::Property::String @model=User @name=:citizenship>, #<DataMapper::Property::String @model=User @name=:referrer_name>]
          @links=[]
          @conditions=nil
          @order=[#<DataMapper::Query::Direction @target=#<DataMapper::Property::String @model=User @name=:name> @operator=:asc>]
          @limit=3
          @offset=0
          @reload=false
          @unique=false>
      INSPECT
    end
  end

  [ :intersection, :& ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      supported_by :all do
        before :all do
          @key = @model.key(@repository.name)

          @self_relationship = DataMapper::Associations::OneToMany::Relationship.new(
            :self,
            @model,
            @model,
            {
              :child_key              => @key.map { |p| p.name },
              :parent_key             => @key.map { |p| p.name },
              :child_repository_name  => @repository.name,
              :parent_repository_name => @repository.name,
            }
          )

          10.times do |n|
            @model.create(:name => "#{@model} #{n}")
          end
        end

        subject do
          result = @query.send(method, @other)

          if @another
            result = result.send(method, @another)
          end

          result
        end

        describe 'with equivalent query' do
          before { @other = @query.dup }

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { is_expected.to == @query }
        end

        describe 'with other matching everything' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model)
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'factors out the operation matching everything' do
            pending 'TODO: compress Query#conditions for proper comparison'
            is_expected.to eq DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
          end
        end

        describe 'with self matching everything' do
          before do
            @query   = DataMapper::Query.new(@repository, @model)
            @other   = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @another = DataMapper::Query.new(@repository, @model, :citizenship => 'US')
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { is_expected.not_to equal(@another) }

          it 'factors out the operation matching everything' do
            is_expected.to eq DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb', :citizenship => 'US')
          end
        end

        describe 'with self having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,        @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and AND them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different conditions, no links/offset/limit' do
          before do
            property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model, property.name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, property.name => 'John Doe')

            expect(@query.conditions).not_to eq @other.conditions

            @expected = DataMapper::Query::Conditions::Operation.new(:and,
              DataMapper::Query::Conditions::Comparison.new(:eql, property, 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:eql, property, 'John Doe')
            )
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it "AND's the conditions together" do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different fields' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :fields => [ @property ])

            expect(@query.fields).not_to eq @other.fields
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other fields' do
            expect(subject.fields).to eq [ @property ]
          end
        end

        describe 'with different order' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :order => [ DataMapper::Query::Direction.new(@property, :desc) ])

            expect(@query.order).not_to eq @other.order
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other order' do
            expect(subject.order).to eq [ DataMapper::Query::Direction.new(@property, :desc) ]
          end
        end

        describe 'with different unique' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :unique => true)

            expect(@query.unique?).not_to eq @other.unique?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other unique' do
            expect(subject.unique?).to eq true
          end
        end

        describe 'with different add_reversed' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :add_reversed => true)

            expect(@query.add_reversed?).not_to eq @other.add_reversed?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other add_reversed' do
            expect(subject.add_reversed?).to eq true
          end
        end

        describe 'with different reload' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :reload => true)

            expect(@query.reload?).not_to eq @other.reload?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'uses the other reload' do
            expect(subject.reload?).to eq true
          end
        end

        describe 'with different models' do
          before { @other = DataMapper::Query.new(@repository, Other) }

          it { expect { method(:subject) }.to raise_error(ArgumentError) }
        end
      end
    end
  end

  it { is_expected.to respond_to(:limit) }

  describe '#limit' do
    before :all do
      @return = @query.limit
    end

    it { expect(@return).to be_kind_of(Integer) }

    it 'returns expected value' do
      expect(@return).to eq 3
    end
  end

  it { is_expected.to respond_to(:limit_records) }

  describe '#limit_records' do
    supported_by :all do
      before :all do
        @john = { 'name' => 'John Doe',  'referrer_name' => nil         }
        @sam  = { 'name' => 'Sam Smoot', 'referrer_name' => nil         }
        @dan  = { 'name' => 'Dan Kubb',  'referrer_name' => 'Sam Smoot' }

        @records = [ @john, @sam, @dan ]

        @query.update(:limit => 1, :offset => 1)

        @return = @query.limit_records(@records)
      end

      it 'returns Enumerable' do
        expect(@return).to be_kind_of(Enumerable)
      end

      it 'are not the records provided' do
        expect(@return).not_to equal(@records)
      end

      it 'returns expected values' do
        expect(@return).to eq [ @sam ]
      end
    end
  end

  it { is_expected.to respond_to(:links) }

  describe '#links' do
    before :all do
      @return = @query.links
    end

    it { expect(@return).to be_kind_of(Array) }

    it { expect(@return).to be_empty }
  end

  it { is_expected.to respond_to(:match_records) }

  describe '#match_records' do
    supported_by :all do
      before :all do
        @john = { 'name' => 'John Doe',  'referrer_name' => nil         }
        @sam  = { 'name' => 'Sam Smoot', 'referrer_name' => nil         }
        @dan  = { 'name' => 'Dan Kubb',  'referrer_name' => 'Sam Smoot' }

        @records = [ @john, @sam, @dan ]

        @query.update(:name.not => @sam['name'])

        @return = @query.match_records(@records)
      end

      it 'returns Enumerable' do
        expect(@return).to be_kind_of(Enumerable)
      end

      it 'are not the records provided' do
        expect(@return).not_to equal(@records)
      end

      it 'returns expected values' do
        expect(@return).to eq [ @john, @dan ]
      end
    end
  end

  it { is_expected.to respond_to(:merge) }

  describe '#merge' do
    describe 'with a Hash' do
      before do
        @return = @query.merge({ :limit => 202 })
      end

      it 'does not affect the receiver' do
        expect(@query.options[:limit]).to eq 3
      end
    end

    describe 'with a Query' do
      before do
        @other  = DataMapper::Query.new(@repository, @model, @options.update(@other_options))
        @return = @query.merge(@other)
      end

      it 'does not affect the receiver' do
        expect(@query.options[:limit]).to eq 3
      end
    end
  end

  it { is_expected.to respond_to(:model) }

  describe '#model' do
    before :all do
      @return = @query.model
    end

    it { expect(@return).to be_kind_of(Class) }

    it 'returns expected value' do
      expect(@return).to eq @model
    end
  end

  it { is_expected.to respond_to(:offset) }

  describe '#offset' do
    before :all do
      @return = @query.offset
    end

    it { expect(@return).to be_kind_of(Integer) }

    it 'returns expected value' do
      expect(@return).to eq 0
    end
  end

  it { is_expected.to respond_to(:order) }

  describe '#order' do
    before :all do
      @return = @query.order
    end

    it { expect(@return).to be_kind_of(Array) }

    it 'returns expected value' do
      expect(@return).to eq [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
    end
  end

  it { is_expected.to respond_to(:raw?) }

  describe '#raw?' do
    describe 'when the query contains raw conditions' do
      before :all do
        @query.update(:conditions => [ 'name = ?', 'Dan Kubb' ])
      end

      it { is_expected.to be_raw }
    end

    describe 'when the query does not contain raw conditions' do
      it { is_expected.not_to be_raw }
    end
  end

  it { is_expected.to respond_to(:relative) }

  describe '#relative' do
    describe 'with a Hash' do
      describe 'that is empty' do
        before :all do
          @return = @query.relative({})
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'is not return self' do
          expect(@return).not_to equal(@query)
        end

        it 'returns a copy' do
          expect(@return).to be_eql(@query)
        end
      end

      describe 'using different options' do
        before :all do
          @return = @query.relative(@other_options)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the fields' do
          expect(@return.fields).to eq @other_options[:fields]
        end

        it 'updates the links' do
          expect(@return.links).to eq @other_options[:links]
        end

        it 'updates the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and, [ 'name = ?', [ 'Dan Kubb' ] ])
        end

        it 'updates the offset' do
          expect(@return.offset).to eq @other_options[:offset]
        end

        it 'updates the limit' do
          expect(@return.limit).to eq @other_options[:limit]
        end

        it 'updates the order' do
          expect(@return.order).to eq @other_options[:order]
        end

        it 'updates the unique' do
          expect(@return.unique?).to eq @other_options[:unique]
        end

        it 'updates the add_reversed' do
          expect(@return.add_reversed?).to eq @other_options[:add_reversed]
        end

        it 'updates the reload' do
          expect(@return.reload?).to eq @other_options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options = { :name => 'Dan Kubb' }

          @return = @query.relative(@options)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the conditions' do
          expect(@return.conditions).to eq
            DataMapper::Query::Conditions::Operation.new(
              :and,
              DataMapper::Query::Conditions::Comparison.new(
                :eql,
                @model.properties[:name],
                @options[:name]
              )
            )
        end
      end

      describe 'using an offset when query offset is greater than 0' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.relative(:offset => 1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          expect(@return.offset).to eq 2
        end
      end

      describe 'using an limit when query limit specified' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.relative(:limit => 1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the limit' do
          expect(@return.limit).to eq 1
        end
      end
    end
  end

  it { is_expected.to respond_to(:reload?) }

  describe '#reload?' do
    describe 'when the query reloads' do
      before :all do
        @query.update(:reload => true)
      end

      it { is_expected.to be_reload }
    end

    describe 'when the query does not reload' do
      it { is_expected.not_to be_reload }
    end
  end

  it { is_expected.to respond_to(:repository) }

  describe '#repository' do
    before :all do
      @return = @query.repository
    end

    it { expect(@return).to be_kind_of(DataMapper::Repository) }

    it 'returns expected value' do
      expect(@return).to eq @repository
    end
  end

  it { is_expected.to respond_to(:reverse) }

  describe '#reverse' do
    before :all do
      @return = @query.reverse
    end

    it { expect(@return).to be_kind_of(DataMapper::Query) }

    it 'copies the Query' do
      expect(@return).not_to equal(@original)
    end

    # TODO: push this into dup spec
    it 'does not reference original order' do
      expect(@return.order).not_to equal(@original.order)
    end

    it 'has a reversed order' do
      expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ]
    end

    [ :repository, :model, :fields, :links, :conditions, :offset, :limit, :unique?, :add_reversed?, :reload? ].each do |attribute|
      it "has an equivalent #{attribute}" do
        expect(@return.send(attribute)).to eq @original.send(attribute)
      end
    end
  end

  it { is_expected.to respond_to(:reverse!) }

  describe '#reverse!' do
    before :all do
      @return = @query.reverse!
    end

    it { expect(@return).to be_kind_of(DataMapper::Query) }

    it { expect(@return).to equal(@original) }

    it 'has a reversed order' do
      expect(@return.order).to eq [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ]
    end
  end

  [ :slice, :[] ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      describe 'with a positive offset' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.send(method, 1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          expect(@return.offset).to eq 2
        end

        it 'updates the limit to 1' do
          expect(@return.limit).to eq 1
        end
      end

      describe 'with a positive offset and length' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.send(method, 1, 1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          expect(@return.offset).to eq 2
        end

        it 'updates the limit' do
          expect(@return.limit).to eq 1
        end
      end

      describe 'with a positive range' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 3)

          @return = @query.send(method, 1..2)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          expect(@return.offset).to eq 2
        end

        it 'updates the limit' do
          expect(@return.limit).to eq 2
        end
      end

      describe 'with a negative offset' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.send(method, -1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          pending "TODO: update Query##{method} handle negative offset"
          expect(@return.offset).to eq 2
        end

        it 'updates the limit to 1' do
          expect(@return.limit).to eq 1
        end
      end

      describe 'with a negative offset and length' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.send(method, -1, 1)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          pending "TODO: update Query##{method} handle negative offset and length"
          expect(@return.offset).to eq 2
        end

        it 'updates the limit to 1' do
          expect(@return.limit).to eq 1
        end
      end

      describe 'with a negative range' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 3)

          rescue_if "TODO: update Query##{method} handle negative range" do
            @return = @query.send(method, -2..-1)
          end
        end

        before do
          pending "TODO: update Query##{method} handle negative range" unless defined?(@return)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it 'does not return self' do
          expect(@return).not_to equal(@original)
        end

        it 'updates the offset to be relative to the original offset' do
          expect(@return.offset).to eq 2
        end

        it 'updates the limit to 1' do
          expect(@return.limit).to eq 2
        end
      end

      describe 'with an offset not within range' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 3)
        end

        it 'raises an exception' do
          expect {
            @query.send(method, 12)
          }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
        end
      end

      describe 'with an offset and length not within range' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 3)
        end

        it 'raises an exception' do
          expect { @query.send(method, 12, 1) }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
        end
      end

      describe 'with a range not within range' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 3)
        end

        it 'raises an exception' do
          expect {
            @query.send(method, 12..12)
          }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
        end
      end

      describe 'with invalid arguments' do
        it 'raises an exception' do
          expect {
            @query.send(method, 'invalid')
          }.to raise_error(ArgumentError, 'arguments may be 1 or 2 Integers, or 1 Range object, was: ["invalid"]')
        end
      end
    end
  end

  it { is_expected.to respond_to(:slice!) }

  describe '#slice!' do
    describe 'with a positive offset' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 2)

        @return = @query.slice!(1)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        expect(@return.offset).to eq 2
      end

      it 'updates the limit to 1' do
        expect(@return.limit).to eq 1
      end
    end

    describe 'with a positive offset and length' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 2)

        @return = @query.slice!(1, 1)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        expect(@return.offset).to eq 2
      end

      it 'updates the limit' do
        expect(@return.limit).to eq 1
      end
    end

    describe 'with a positive range' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 3)

        @return = @query.slice!(1..2)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        expect(@return.offset).to eq 2
      end

      it 'updates the limit' do
        expect(@return.limit).to eq 2
      end
    end

    describe 'with a negative offset' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 2)

        @return = @query.slice!(-1)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        pending 'TODO: update Query#slice! handle negative offset'
        expect(@return.offset).to eq 2
      end

      it 'updates the limit to 1' do
        expect(@return.limit).to eq 1
      end
    end

    describe 'with a negative offset and length' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 2)

        @return = @query.slice!(-1, 1)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        pending 'TODO: update Query#slice! handle negative offset and length'
        expect(@return.offset).to eq 2
      end

      it 'updates the limit to 1' do
        expect(@return.limit).to eq 1
      end
    end

    describe 'with a negative range' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 3)

        rescue_if 'TODO: update Query#slice! handle negative range' do
          @return = @query.slice!(-2..-1)
        end
      end

      before do
        pending 'TODO: update Query#slice! handle negative range' unless defined?(@return)
      end

      it { expect(@return).to be_kind_of(DataMapper::Query) }

      it 'returns self' do
        expect(@return).to equal(@original)
      end

      it 'updates the offset to be relative to the original offset' do
        expect(@return.offset).to eq 2
      end

      it 'updates the limit to 1' do
        expect(@return.limit).to eq 2
      end
    end

    describe 'with an offset not within range' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 3)
      end

      it 'raises an exception' do
        expect {
          @query.slice!(12)
        }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
      end
    end

    describe 'with an offset and length not within range' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 3)
      end

      it 'raises an exception' do
        expect {
          @query.slice!(12, 1)
        }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
      end
    end

    describe 'with a range not within range' do
      before :all do
        @query = @query.update(:offset => 1, :limit => 3)
      end

      it 'raises an exception' do
        expect {
          @query.slice!(12..12)
        }.to raise_error(RangeError, 'offset 12 and limit 1 are outside allowed range')
      end
    end

    describe 'with invalid arguments' do
      it 'raises an exception' do
        expect {
          @query.slice!('invalid')
        }.to raise_error(ArgumentError, 'arguments may be 1 or 2 Integers, or 1 Range object, was: ["invalid"]')
      end
    end
  end

  it { is_expected.to respond_to(:sort_records) }

  describe '#sort_records' do
    supported_by :all do
      before :all do
        @john = { 'name' => 'John Doe',  'referrer_name' => nil         }
        @sam  = { 'name' => 'Sam Smoot', 'referrer_name' => nil         }
        @dan  = { 'name' => 'Dan Kubb',  'referrer_name' => 'Sam Smoot' }

        @records = [ @john, @sam, @dan ]

        @query.update(:order => [ :name ])

        @return = @query.sort_records(@records)
      end

      it 'returns Enumerable' do
        expect(@return).to be_kind_of(Enumerable)
      end

      it 'are not the records provided' do
        expect(@return).not_to equal(@records)
      end

      it 'returns expected values' do
        expect(@return).to eq [ @dan, @john, @sam ]
      end
    end
  end

  [ :union, :|, :+ ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      supported_by :all do
        before :all do
          @key = @model.key(@repository.name)

          @self_relationship = DataMapper::Associations::OneToMany::Relationship.new(
            :self,
            @model,
            @model,
            {
              :child_key              => @key.map { |p| p.name },
              :parent_key             => @key.map { |p| p.name },
              :child_repository_name  => @repository.name,
              :parent_repository_name => @repository.name,
            }
          )

          10.times do |n|
            @model.create(:name => "#{@model} #{n}")
          end
        end

        subject { @query.send(method, @other) }

        describe 'with equivalent query' do
          before { @other = @query.dup }

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { is_expected.to == @query }
        end

        describe 'with other matching everything' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model)
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'matches everything' do
            is_expected.to == DataMapper::Query.new(@repository, @model)
          end
        end

        describe 'with self matching everything' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'matches everything' do
            is_expected.to == DataMapper::Query.new(@repository, @model)
          end
        end

        describe 'with self having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq= @expected
          end
        end

        describe 'with other having a limit' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having an offset > 0' do
          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :offset => 5, :limit => 5)

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,        @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with self having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])
            @other = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@query.merge(:fields => @key))),
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb')
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with other having links' do
          before :all do
            @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
          end

          before do
            @query = DataMapper::Query.new(@repository, @model, :name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, :links => [ :referrer ])

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:name], 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:in,  @self_relationship,       @model.all(@other.merge(:fields => @key)))
            )
          end

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it 'puts each query into a subquery and OR them together' do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different conditions, no links/offset/limit' do
          before do
            property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model, property.name => 'Dan Kubb')
            @other = DataMapper::Query.new(@repository, @model, property.name => 'John Doe')

            expect(@query.conditions).not_to eq @other.conditions

            @expected = DataMapper::Query::Conditions::Operation.new(:or,
              DataMapper::Query::Conditions::Comparison.new(:eql, property, 'Dan Kubb'),
              DataMapper::Query::Conditions::Comparison.new(:eql, property, 'John Doe')
            )
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it "OR's the conditions together" do
            expect(subject.conditions).to eq @expected
          end
        end

        describe 'with different fields' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :fields => [ @property ])

            expect(@query.fields).not_to eq @other.fields
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other fields' do
            expect(subject.fields).to eq [ @property ]
          end
        end

        describe 'with different order' do
          before do
            @property = @model.properties[:name]

            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :order => [ DataMapper::Query::Direction.new(@property, :desc) ])

            expect(@query.order).not_to eq @other.order
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other order' do
            expect(subject.order).to eq [ DataMapper::Query::Direction.new(@property, :desc) ]
          end
        end

        describe 'with different unique' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :unique => true)

            expect(@query.unique?).not_to eq @other.unique?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other unique' do
            expect(subject.unique?).to eq true
          end
        end

        describe 'with different add_reversed' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :add_reversed => true)

            expect(@query.add_reversed?).not_to eq @other.add_reversed?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other add_reversed' do
            expect(subject.add_reversed?).to eq true
          end
        end

        describe 'with different reload' do
          before do
            @query = DataMapper::Query.new(@repository, @model)
            @other = DataMapper::Query.new(@repository, @model, :reload => true)

            expect(@query.reload?).not_to eq @other.reload?
          end

          it { is_expected.to be_kind_of(DataMapper::Query) }

          it { is_expected.not_to equal(@query) }

          it { is_expected.not_to equal(@other) }

          it { expect(subject.conditions).to be_nil }

          it 'uses the other reload' do
            expect(subject.reload?).to eq true
          end
        end

        describe 'with different models' do
          before { @other = DataMapper::Query.new(@repository, Other) }

          it { expect { method(:subject) }.to raise_error(ArgumentError) }
        end
      end
    end
  end

  it { is_expected.to respond_to(:unique?) }

  describe '#unique?' do
    describe 'when the query is unique' do
      before :all do
        @query.update(:unique => true)
      end

      it { is_expected.to be_unique }
    end

    describe 'when the query is not unique' do
      it { is_expected.not_to be_unique }
    end

    describe 'when links are provided, but unique is not specified' do
      before :all do
        expect(@query).not_to be_unique
        @query.update(:links => [ :referrer ])
      end

      it { is_expected.to be_unique }
    end

    describe 'when links are provided, but unique is false' do
      before :all do
        expect(@query).not_to be_unique
        @query.update(:links => [ :referrer ], :unique => false)
      end

      it { is_expected.not_to be_unique }
    end
  end

  it { is_expected.to respond_to(:update) }

  describe '#update' do
    describe 'with a Query' do
      describe 'that is equivalent' do
        before :all do
          @other = DataMapper::Query.new(@repository, @model, @options)

          @return = @query.update(@other)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }
      end

      describe 'that has conditions set' do
        before :all do
          @and_operation = DataMapper::Query::Conditions::Operation.new(:and)
          @or_operation  = DataMapper::Query::Conditions::Operation.new(:or)

          @and_operation << DataMapper::Query::Conditions::Comparison.new(:eql, User.properties[:name],       'Dan Kubb')
          @and_operation << DataMapper::Query::Conditions::Comparison.new(:eql, User.properties[:citizenship],'Canada')

          @or_operation << DataMapper::Query::Conditions::Comparison.new(:eql, User.properties[:name],        'Ted Han')
          @or_operation << DataMapper::Query::Conditions::Comparison.new(:eql, User.properties[:citizenship], 'USA')

          @query_one = DataMapper::Query.new(@repository, @model, :conditions => @and_operation)
          @query_two = DataMapper::Query.new(@repository, @model, :conditions => @or_operation)

          @conditions = @query_one.merge(@query_two).conditions
        end

        it { expect(@conditions).to eq DataMapper::Query::Conditions::Operation.new(:and, @and_operation, @or_operation) }
      end

      describe 'that is for an ancestor model' do
        before :all do
          class ::Contact < User; end

          @query    = DataMapper::Query.new(@repository, Contact, @options)
          @original = @query

          @other = DataMapper::Query.new(@repository, User,    @options)

          @return = @query.update(@other)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }
      end

      describe 'using a different repository' do
        it 'raises an exception' do
          expect {
            @query.update(DataMapper::Query.new(DataMapper::Repository.new(:other), User))
          }.to raise_error(ArgumentError, '+other+ DataMapper::Query must be for the default repository, not other')
        end
      end

      describe 'using a different model' do
        before :all do
          class ::Clone
            include DataMapper::Resource

            property :name, String, :key => true
          end
        end

        it 'raises an exception' do
          expect {
            @query.update(DataMapper::Query.new(@repository, Clone))
          }.to raise_error(ArgumentError, '+other+ DataMapper::Query must be for the User model, not Clone')
        end
      end

      describe 'using different options' do
        before :all do
          @other = DataMapper::Query.new(@repository, @model, @options.update(@other_options))

          @return = @query.update(@other)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'updates the fields' do
          expect(@return.fields).to eq @options[:fields]
        end

        it 'updates the links' do
          expect(@return.links).to eq @options[:links]
        end

        it 'updates the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and, [ 'name = ?', [ 'Dan Kubb' ] ])
        end

        it 'updates the offset' do
          expect(@return.offset).to eq @options[:offset]
        end

        it 'updates the limit' do
          expect(@return.limit).to eq @options[:limit]
        end

        it 'updates the order' do
          expect(@return.order).to eq @options[:order]
        end

        it 'updates the unique' do
          expect(@return.unique?).to eq @options[:unique]
        end

        it 'updates the add_reversed' do
          expect(@return.add_reversed?).to eq @options[:add_reversed]
        end

        it 'updates the reload' do
          expect(@return.reload?).to eq @options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options.update(:name => 'Dan Kubb')
          @other = DataMapper::Query.new(@repository, @model, @options)

          @return = @query.update(@other)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'updates the conditions' do
          expect(@return.conditions).to eq
            DataMapper::Query::Conditions::Operation.new(
              :and,
              DataMapper::Query::Conditions::Comparison.new(
                :eql,
                @model.properties[:name],
                @options[:name]
              )
            )
        end
      end
    end

    describe 'with a Hash' do
      describe 'that is empty' do
        before :all do
          @copy = @query.dup
          @return = @query.update({})
        end

        it { expect(@returni).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'does not change the Query' do
          expect(@return).to eq @copy
        end
      end

      describe 'using different options' do
        before :all do
          @return = @query.update(@other_options)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'updates the fields' do
          expect(@return.fields).to eq @other_options[:fields]
        end

        it 'updates the links' do
          expect(@return.links).to eq @other_options[:links]
        end

        it 'updates the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(:and, [ 'name = ?', [ 'Dan Kubb' ] ])
        end

        it 'updates the offset' do
          expect(@return.offset).to eq @other_options[:offset]
        end

        it 'updates the limit' do
          expect(@return.limit).to eq @other_options[:limit]
        end

        it 'updates the order' do
          expect(@return.order).to eq @other_options[:order]
        end

        it 'updates the unique' do
          expect(@return.unique?).to eq @other_options[:unique]
        end

        it 'updates the add_reversed' do
          expect(@return.add_reversed?).to eq @other_options[:add_reversed]
        end

        it 'updates the reload' do
          expect(@return.reload?).to eq @other_options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options = { :name => 'Dan Kubb' }

          @return = @query.update(@options)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'updates the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(
            :and,
            DataMapper::Query::Conditions::Comparison.new(
              :eql,
              @model.properties[:name],
              @options[:name]
            )
          )
        end
      end

      describe 'using raw conditions' do
        before :all do
          @query.update(:conditions => [ 'name IS NOT NULL' ])

          @return = @query.update(:conditions => [ 'name = ?', 'Dan Kubb' ])
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        it { expect(@return).to equal(@original) }

        it 'updates the conditions' do
          expect(@return.conditions).to eq DataMapper::Query::Conditions::Operation.new(
            :and,
            [ 'name IS NOT NULL' ],
            [ 'name = ?', [ 'Dan Kubb' ] ]
          )
        end
      end

      describe 'with the String key mapping to a Query::Path' do
        before :all do
          expect(@query.links).to be_empty

          @options = { 'grandparents.name' => 'Dan Kubb' }

          @return = @query.update(@options)
        end

        it { expect(@return).to be_kind_of(DataMapper::Query) }

        xit 'does not set the conditions' do
          expect(@return.conditions).to be_nil
        end

        it 'sets the links' do
          expect(@return.links).to eq [ @model.relationships[:referrals], @model.relationships[:referrer] ]
        end

        it 'is valid' do
          expect(@return).to be_valid
        end
      end
    end
  end
end
