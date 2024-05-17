shared_examples 'Finder Interface' do
  before :all do
    %w[ @article_model @article @other @articles ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
      raise "+#{ivar}+ should not be nil in before block" unless instance_variable_get(ivar)
    end
  end

  before :all do
    @no_join = defined?(DataMapper::Adapters::InMemoryAdapter) && @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) ||
               defined?(DataMapper::Adapters::YamlAdapter)     && @adapter.kind_of?(DataMapper::Adapters::YamlAdapter)

    @do_adapter = defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)

    @many_to_many = @articles.kind_of?(DataMapper::Associations::ManyToMany::Collection)

    @skip = @no_join && @many_to_many
  end

  before do
    pending if @skip
  end

  it 'is Enumerable' do
    expect(@articles).to be_kind_of(Enumerable)
  end

  [ :[], :slice ].each do |method|
    it { expect(@articles).to respond_to(method) }

    describe "##{method}" do
      before :all do
        1.upto(10) { |number| @articles.create(:content => "Article #{number}") }
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
      end

      describe 'with a positive offset' do
        before :all do
          unless @skip
            @return = @resource = @articles.send(method, 0)
          end
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns expected Resource' do
          expect(@return).to eq @copy.entries.send(method, 0)
        end
      end

      describe 'with a positive offset and length' do
        before :all do
          @return = @resources = @articles.send(method, 5, 5)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns the expected Resource' do
          expect(@return).to eq @copy.entries.send(method, 5, 5)
        end

        it 'scopes the Collection' do
          expect(@resources.reload).to eq @copy.entries.send(method, 5, 5)
        end
      end

      describe 'with a positive range' do
        before :all do
          @return = @resources = @articles.send(method, 5..10)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns the expected Resources' do
          expect(@return).to eq @copy.entries.send(method, 5..10)
        end

        it 'scopes the Collection' do
          expect(@resources.reload).to eq @copy.entries.send(method, 5..10)
        end
      end

      describe 'with a negative offset' do
        before :all do
          unless @skip
            @return = @resource = @articles.send(method, -1)
          end
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns expected Resource' do
          expect(@return).to eq @copy.entries.send(method, -1)
        end
      end

      describe 'with a negative offset and length' do
        before :all do
          @return = @resources = @articles.send(method, -5, 5)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns the expected Resources' do
          expect(@return).to eq @copy.entries.send(method, -5, 5)
        end

        it 'scopes the Collection' do
          expect(@resources.reload).to eq @copy.entries.send(method, -5, 5)
        end
      end

      describe 'with a negative range' do
        before :all do
          @return = @resources = @articles.send(method, -5..-2)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns the expected Resources' do
          expect(@return.to_a).to eq @copy.entries.send(method, -5..-2)
        end

        it 'scopes the Collection' do
          expect(@resources.reload).to eq @copy.entries.send(method, -5..-2)
        end
      end

      describe 'with an empty exclusive range' do
        before :all do
          @return = @resources = @articles.send(method, 0...0)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns the expected value' do
          expect(@return.to_a).to eq @copy.entries.send(method, 0...0)
        end

        it 'is empty' do
          expect(@return).to be_empty
        end
      end

      describe 'with an offset not within the Collection' do
        before :all do
          unless @skip
            @return = @articles.send(method, 99)
          end
        end

        it 'returns nil' do
          expect(@return).to be_nil
        end
      end

      describe 'with an offset and length not within the Collection' do
        before :all do
          @return = @articles.send(method, 99, 1)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is empty' do
          expect(@return).to be_empty
        end
      end

      describe 'with a range not within the Collection' do
        before :all do
          @return = @articles.send(method, 99..100)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is empty' do
          expect(@return).to be_empty
        end
      end
    end
  end

  it { expect(@articles).to respond_to(:all) }

  describe '#all' do
    describe 'with no arguments' do
      before :all do
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup

        @return = @collection = @articles.all
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns a new instance' do
        expect(@return).not_to equal(@articles)
      end

      it 'is expected Resources' do
        expect(@collection).to eq @articles.entries
      end

      it 'does not have a Query the same as the original' do
        expect(@return.query).not_to equal(@articles.query)
      end

      it 'has a Query equal to the original' do
        expect(@return.query).to eql(@articles.query)
      end

      it 'scopes the Collection' do
        expect(@collection.reload).to eq @copy.entries
      end
    end

    describe 'with a query' do
      before :all do
        @new  = @articles.create(:content => 'New Article')
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup

        @return = @articles.all(:content => [ 'New Article' ])
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns a new instance' do
        expect(@return).not_to equal(@articles)
      end

      it 'is expected Resources' do
        expect(@return).to eq [ @new ]
      end

      it 'has a different query than original Collection' do
        expect(@return.query).not_to equal(@articles.query)
      end

      it 'scopes the Collection' do
        expect(@return.reload).to eq @copy.entries.select { |resource| resource.content == 'New Article' }
      end
    end

    describe 'with a query using raw conditions' do
      before do
        pending unless defined?(DataMapper::Adapters::DataObjectsAdapter) && @adapter.kind_of?(DataMapper::Adapters::DataObjectsAdapter)
      end

      before :all do
        @new  = @articles.create(:subtitle => 'New Article')
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup

        @return = @articles.all(:conditions => [ 'subtitle = ?', 'New Article' ])
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns a new instance' do
        expect(@return).not_to equal(@articles)
      end

      it 'is expected Resources' do
        expect(@return).to eq [ @new ]
      end

      it 'has a different query than original Collection' do
        expect(@return.query).not_to eq @articles.query
      end

      it 'scopes the Collection' do
        expect(@return.reload).to eq @copy.entries.select { |resource| resource.subtitle == 'New Article' }.first(1)
      end
    end

    describe 'with a query that is out of range' do
      it 'raises an exception' do
        expect {
          @articles.all(:limit => 10).all(:offset => 10)
        }.to raise_error(RangeError, 'offset 10 and limit 0 are outside allowed range')
      end
    end

    describe 'with a query using a m:1 relationship' do
      describe 'with a Hash' do
        before :all do
          @return = @articles.all(:original => @original.attributes)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a resource' do
        before :all do
          @return = @articles.all(:original => @original)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a collection' do
        before :all do
          @collection = @article_model.all(
            Hash[ @article_model.key.zip(@original.key) ]
          )

          @return = @articles.all(:original => @collection)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

      end

      describe 'with an empty Array' do
        before :all do
          @return = @articles.all(:original => [])
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is an empty Collection' do
          expect(@return).to be_empty
        end

        it 'does not have a valid query' do
          expect(@return.query).not_to be_valid
        end
      end

      describe 'with a nil value' do
        before :all do
          @return = @articles.all(:original => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        if respond_to?(:model?) && model?
          it 'is expected Resources' do
            expect(@return).to eq [ @original, @other ]
          end
        else
          it 'is an empty Collection' do
            expect(@return).to be_empty
          end
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to negated collection query' do
          pending 'Update RDBMS to match ruby behavior' if @do_adapter && @articles.kind_of?(DataMapper::Model)

          # NOTE: the second query will not match any articles where original_id
          # is nil, while the in-memory/yaml adapters will.  RDBMS will explicitly
          # filter out NULL matches because we are matching on a non-NULL value,
          # which is not consistent with how DM/Ruby matching behaves.
          expect(@return).to eq @articles.all(:original.not => @article_model.all)
        end
      end

      describe 'with a negated nil value' do
        before :all do
          @return = @articles.all(:original.not => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to collection query' do
          expect(@return).to eq @articles.all(:original => @article_model.all)
        end
      end
    end

    describe 'with a query using a 1:1 relationship' do
      before :all do
        @new = @articles.create(:content => 'New Article', :original => @article)
      end

      describe 'with a Hash' do
        before :all do
          @return = @articles.all(:previous => @new.attributes)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a resource' do
        before :all do
          @return = @articles.all(:previous => @new)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a collection' do
        before :all do
          @collection = @article_model.all(
            Hash[ @article_model.key.zip(@new.key) ]
          )

          @return = @articles.all(:previous => @collection)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with an empty Array' do
        before :all do
          @return = @articles.all(:previous => [])
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is an empty Collection' do
          expect(@return).to be_empty
        end

        it 'does not have a valid query' do
          expect(@return.query).not_to be_valid
        end
      end

      describe 'with a nil value' do
        before :all do
          @return = @articles.all(:previous => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        if respond_to?(:model?) && model?
          it 'are expected Resources' do
            expect(@return).to eq [ @other, @new ]
          end
        else
          it 'are expected Resources' do
            expect(@return).to eq [ @new ]
          end
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to negated collection query' do
          expect(@return).to eq @articles.all(:previous.not => @article_model.all(:original.not => nil))
        end
      end

      describe 'with a negated nil value' do
        before :all do
          @return = @articles.all(:previous.not => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        if respond_to?(:model?) && model?
          it 'are expected Resources' do
            expect(@return).to eq [ @original, @article ]
          end
        else
          it 'are expected Resources' do
            expect(@return).to eq [ @article ]
          end
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to collection query' do
          expect(@return).to eq @articles.all(:previous => @article_model.all)
        end
      end
    end

    describe 'with a query using a 1:m relationship' do
      before :all do
        @new = @articles.create(:content => 'New Article', :original => @article)
      end

      describe 'with a Hash' do
        before :all do
          @return = @articles.all(:revisions => @new.attributes)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a resource' do
        before :all do
          @return = @articles.all(:revisions => @new)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a collection' do
        before :all do
          @collection = @article_model.all(
            Hash[ @article_model.key.zip(@new.key) ]
          )

          @return = @articles.all(:revisions => @collection)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with an empty Array' do
        before :all do
          @return = @articles.all(:revisions => [])
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is an empty Collection' do
          expect(@return).to be_empty
        end

        it 'does not have a valid query' do
          expect(@return.query).not_to be_valid
        end
      end

      describe 'with a nil value' do
        before :all do
          @return = @articles.all(:revisions => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        if respond_to?(:model?) && model?
          it 'are expected Resources' do
            expect(@return).to eq [ @other, @new ]
          end
        else
          it 'are expected Resources' do
            expect(@return).to eq [ @new ]
          end
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to negated collection query' do
          expect(@return).to eq @articles.all(:revisions.not => @article_model.all(:original.not => nil))
        end
      end

      describe 'with a negated nil value' do
        before :all do
          @return = @articles.all(:revisions.not => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        if respond_to?(:model?) && model?
          it 'are expected Resources' do
            expect(@return).to eq [ @original, @article ]
          end
        else
          it 'are expected Resources' do
            expect(@return).to eq [ @article ]
          end
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to collection query' do
          expect(@return).to eq @articles.all(:revisions => @article_model.all)
        end
      end
    end

    describe 'with a query using a m:m relationship' do
      before :all do
        @publication = @article.publications.create(:name => 'DataMapper Now')
      end

      describe 'with a Hash' do
        before :all do
          @return = @articles.all(:publications => @publication.attributes)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          pending 'TODO'

          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a resource' do
        before :all do
          @return = @articles.all(:publications => @publication)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          pending 'TODO'

          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with a collection' do
        before :all do
          @collection = @publication_model.all(
            Hash[ @publication_model.key.zip(@publication.key) ]
          )

          @return = @articles.all(:publications => @collection)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          pending 'TODO'

          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end
      end

      describe 'with an empty Array' do
        before :all do
          @return = @articles.all(:publications => [])
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is an empty Collection' do
          expect(@return).to be_empty
        end

        it 'does not have a valid query' do
          expect(@return.query).not_to be_valid
        end
      end

      describe 'with a nil value' do
        before :all do
          @return = @articles.all(:publications => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'is empty' do
          pending 'TODO'

          expect(@return).to be_empty
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to negated collection query' do
          expect(@return).to eq @articles.all(:publications.not => @publication_model.all)
        end
      end

      describe 'with a negated nil value' do
        before :all do
          @return = @articles.all(:publications.not => nil)
        end

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'are expected Resources' do
          pending 'TODO'

          expect(@return).to eq [ @article ]
        end

        it 'has a valid query' do
          expect(@return.query).to be_valid
        end

        it 'is equivalent to collection query' do
          expect(@return).to eq @articles.all(:publications => @publication_model.all)
        end
      end
    end
  end

  it { expect(@articles).to respond_to(:at) }

  describe '#at' do
    before :all do
      @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
      @copy.to_a
    end

    describe 'with positive offset' do
      before :all do
        @return = @resource = @articles.at(0)
      end

      should_not_be_a_kicker

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'returns expected Resource' do
        expect(@resource).to eq @copy.entries.at(0)
      end
    end

    describe 'with negative offset' do
      before :all do
        @return = @resource = @articles.at(-1)
      end

      should_not_be_a_kicker

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'returns expected Resource' do
        expect(@resource).to eq @copy.entries.at(-1)
      end
    end
  end

  it { expect(@articles).to respond_to(:each) }

  describe '#each' do
    context 'with a block' do
      subject { @articles.each(&block) }

      let(:yields) { []                                       }
      let(:block)  { lambda { |resource| yields << resource } }

      before do
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
        @copy.to_a
      end

      it { is_expected.to equal(@articles) }

      it { expect { method(:subject) }.to change { yields.dup }.from([]).to(@copy.to_a) }
    end

    context 'without a block' do
      subject { @articles.each }

      let(:yields) { []                                       }
      let(:block)  { lambda { |resource| yields << resource } }

      before do
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
        @copy.to_a
      end

      it { is_expected.to be_instance_of(to_enum.class) }

      it { expect { subject.each(&block) }.to change { yields.dup }.from([]).to(@copy.to_a) }
    end
  end

  it { expect(@articles).to respond_to(:fetch) }

  describe '#fetch' do
    subject { @articles.fetch(*args, &block) }

    let(:block) { nil }

    context 'with a valid index and no default' do
      let(:args) { [ 0 ] }

      before do
        @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
        @copy.to_a
      end

      should_not_be_a_kicker

      it { is_expected.to be_kind_of(DataMapper::Resource) }

      it { is_expected.to eq @copy.entries.fetch(*args) }
    end

    context 'with an invalid index and no default' do
      let(:args) { [ 42 ] }

      it { expect { method(:subject) }.to raise_error(IndexError) }
    end

    context 'with an invalid index and a default' do
      let(:default) { mock('Default') }
      let(:args)    { [ 42, default ] }

      it { is_expected.to equal(default) }
    end

    context 'with an invalid index and a block default' do
      let(:yields)  { []                                          }
      let(:default) { mock('Default')                             }
      let(:block)   { lambda { |index| yields << index; default } }
      let(:args)    { [ 42 ]                                      }

      it { is_expected.to equal(default) }

      it { expect { method(:subject) }.to change { yields.dup }.from([]).to([ 42 ]) }
    end
  end

  it { expect(@articles).to respond_to(:first) }

  describe '#first' do
    before :all do
      1.upto(5) { |number| @articles.create(:content => "Article #{number}") }

      @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
      @copy.to_a
    end

    describe 'with no arguments' do
      before :all do
        @return = @resource = @articles.first
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is first Resource in the Collection' do
        expect(@resource).to eq @copy.entries.first
      end
    end

    describe 'with empty query' do
      before :all do
        @return = @resource = @articles.first({})
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is first Resource in the Collection' do
        expect(@resource).to eq @copy.entries.first
      end
    end

    describe 'with a query' do
      before :all do
        @return = @resource = @articles.first(:content => 'Sample')
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is first Resource in the Collection matching the query' do
        expect(@resource).to eq @article
      end
    end

    describe 'with a limit specified' do
      before :all do
        @return = @resources = @articles.first(1)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'is the first N Resources in the Collection' do
        expect(@resources).to eq @copy.entries.first(1)
      end
    end

    describe 'on an empty collection' do
      before :all do
        @articles = @articles.all(:id => nil)
        @return = @articles.first
      end

      it 'is still an empty collection' do
        expect(@articles).to be_empty
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end

    describe 'with offset specified' do
      before :all do
        @return = @resource = @articles.first(:offset => 1)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the second Resource in the Collection' do
        expect(@resource).to eq @copy.entries[1]
      end
    end

    describe 'with a limit and query specified' do
      before :all do
        @return = @resources = @articles.first(1, :content => 'Sample')
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'is the first N Resources in the Collection matching the query' do
        expect(@resources).to eq [ @article ]
      end
    end
  end

  it { expect(@articles).to respond_to(:first_or_create) }

  describe '#first_or_create' do
    describe 'with conditions that find an existing Resource' do
      before :all do
        @return = @resource = @articles.first_or_create(@article.attributes)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is expected Resource' do
        expect(@resource).to eq @article
      end

      it 'is a saved Resource' do
        expect(@resource).to be_saved
      end
    end

    describe 'with conditions that do not find an existing Resource' do
      before :all do
        @conditions = { :content => 'Unknown Content' }
        @attributes = {}

        @return = @resource = @articles.first_or_create(@conditions, @attributes)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is expected Resource' do
        expect(DataMapper::Ext::Hash.only(@resource.attributes, *@conditions.keys)).to eq @conditions
      end

      it 'is a saved Resource' do
        expect(@resource).to be_saved
      end
    end
  end

  it { expect(@articles).to respond_to(:first_or_new) }

  describe '#first_or_new' do
    describe 'with conditions that find an existing Resource' do
      before :all do
        @return = @resource = @articles.first_or_new(@article.attributes)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is expected Resource' do
        expect(@resource).to eq @article
      end

      it 'is a saved Resource' do
        expect(@resource).to be_saved
      end
    end

    describe 'with conditions that do not find an existing Resource' do
      before :all do
        @conditions = { :content => 'Unknown Content' }
        @attributes = {}

        @return = @resource = @articles.first_or_new(@conditions, @attributes)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is expected Resource' do
        expect(DataMapper::Ext::Hash.only(@resource.attributes, *@conditions.keys)).to eq @conditions
      end

      it 'is a saved Resource' do
        expect(@resource).to be_new
      end
    end
  end

  [ :get, :get! ].each do |method|
    it { expect(@articles).to respond_to(method) }

    describe "##{method}" do
      describe 'with a key to a Resource within the Collection' do
        before :all do
          unless @skip
            @return = @resource = @articles.send(method, *@article.key)
          end
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is matching Resource in the Collection' do
          expect(@resource).to eq @article
        end
      end

      describe 'with a key not typecast' do
        before :all do
          unless @skip
            @return = @resource = @articles.send(method, *@article.key.map { |value| value.to_s })
          end
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is matching Resource in the Collection' do
          expect(@resource).to eq @article
        end
      end

      describe 'with a key to a Resource not within the Collection' do
        if method == :get
          it 'returns nil' do
            expect(@articles.get(99)).to be_nil
          end
        else
          it 'raises an exception' do
            expect {
              @articles.get!(99)
            }.to raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@article_model} with key \[99\]")
          end
        end
      end

      describe 'with a key that is nil' do
        if method == :get
          it 'returns nil' do
            expect(@articles.get(nil)).to be_nil
          end
        else
          it 'raises an exception' do
            expect {
              @articles.get!(nil)
            }.to raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@article_model} with key [nil]")
          end
        end
      end

      describe 'with a key that is an empty String' do
        if method == :get
          it 'returns nil' do
            expect(@articles.get('')).to be_nil
          end
        else
          it 'raises an exception' do
            expect {
              @articles.get!('')
            }.to raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@article_model} with key [\"\"]")
          end
        end
      end

      describe 'with a key that has incorrect number of arguments' do
        subject { @articles.send(method) }

        it 'raises an exception' do
          expect { method(:subject) }.to raise_error(ArgumentError, 'The number of arguments for the key is invalid, expected 1 but was 0')
        end
      end
    end
  end

  it { expect(@articles).to respond_to(:last) }

  describe '#last' do
    before :all do
      1.upto(5) { |number| @articles.create(:content => "Article #{number}") }

      @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
      @copy.to_a
    end

    describe 'with no arguments' do
      before :all do
        @return = @resource = @articles.last
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is last Resource in the Collection' do
        expect(@resource).to eq @copy.entries.last
      end
    end

    describe 'with a query' do
      before :all do
        @return = @resource = @articles.last(:content => 'Sample')
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the last Resource in the Collection matching the query' do
        expect(@resource).to eq @article
      end

      it 'does not update the original query order' do
        collection     = @articles.all(:order => [ :title ])
        original_order = collection.query.order[0].dup
        last           = collection.last(:content => 'Sample')

        expect(last).to eq @resource

        expect(collection.query.order[0]).to eq original_order
      end
    end

    describe 'with a limit specified' do
      before :all do
        @return = @resources = @articles.last(1)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'is the last N Resources in the Collection' do
        expect(@resources).to eq @copy.entries.last(1)
      end
    end

    describe 'with offset specified' do
      before :all do
        @return = @resource = @articles.last(:offset => 1)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the second Resource in the Collection' do
        expect(@resource).to eq @copy.entries[-2]
      end
    end

    describe 'with a limit and query specified' do
      before :all do
        @return = @resources = @articles.last(1, :content => 'Sample')
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'is the last N Resources in the Collection matching the query' do
        expect(@resources).to eq [ @article ]
      end
    end
  end

  it { expect(@articles).to respond_to(:reverse) }

  describe '#reverse' do
    before :all do
      @query = @articles.query

      @new = @articles.create(:title => 'Sample Article')

      @return = @articles.reverse
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns a Collection with reversed entries' do
      expect(@return).to eq @articles.entries.reverse
    end

    it 'returns a Query that is the reverse of the original' do
      expect(@return.query).to eq @query.reverse
    end
  end

  it { expect(@articles).to respond_to(:values_at) }

  describe '#values_at' do
    subject { @articles.values_at(*args) }

    before :all do
      @copy = @articles.kind_of?(Class) ? @articles : @articles.dup
      @copy.to_a
    end

    context 'with positive offset' do
      let(:args) { [ 0 ] }

      should_not_be_a_kicker

      it { is_expected.to be_kind_of(Array) }

      it { is_expected.to eq @copy.entries.values_at(*args) }
    end

    describe 'with negative offset' do
      let(:args) { [ -1 ] }

      should_not_be_a_kicker

      it { is_expected.to be_kind_of(Array) }

      it { is_expected.to eq @copy.entries.values_at(*args) }
    end
  end

  it 'responds to a belongs_to relationship method with #method_missing' do
    pending 'Model#method_missing should delegate to relationships' if @articles.kind_of?(Class)

    expect(@articles).to respond_to(:original)
  end

  it 'responds to a has n relationship method with #method_missing' do
    pending 'Model#method_missing should delegate to relationships' if @articles.kind_of?(Class)

    expect(@articles).to respond_to(:revisions)
  end

  it 'responds to a has 1 relationship method with #method_missing' do
    pending 'Model#method_missing should delegate to relationships' if @articles.kind_of?(Class)

    expect(@articles).to respond_to(:previous)
  end

  describe '#method_missing' do
    before do
      pending 'Model#method_missing delegates to relationships' if @articles.kind_of?(Class)
    end

    describe 'with a belongs_to relationship method' do
      before :all do
        rescue_if 'Model#method_missing delegates to relationships', @articles.kind_of?(Class) do
          @articles.create(:content => 'Another Article', :original => @original)

          @return = @collection = @articles.originals
        end
      end

      should_not_be_a_kicker

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns expected Collection' do
        expect(@collection).to eq [ @original ]
      end

      it 'sets the association for each Resource' do
        expect(@articles.map { |resource| resource.original }).to eq [ @original, @original ]
      end
    end

    describe 'with a has 1 relationship method' do
      before :all do
        # FIXME: create is necessary for m:m so that the intermediary
        # is created properly.  This does not occur with @new.save
        @new = @articles.send(@many_to_many ? :create : :new)

        @article.previous = @new
        @new.previous     = @other

        expect(@article.save).to be(true)
      end

      describe 'with no arguments' do
        before :all do
          @return = @articles.previous
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          # association is sorted reverse by id
          expect(@return).to eq [ @new, @other ]
        end

        it 'sets the association for each Resource' do
          expect(@articles.map { |resource| resource.previous }).to eq [ @new, @other ]
        end
      end

      describe 'with arguments' do
        before :all do
          @return = @articles.previous(:fields => [ :id ])
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          # association is sorted reverse by id
          expect(@return).to eq [ @new, @other ]
        end

        { :id => true, :title => false, :content => false }.each do |attribute, expected|
          it "has query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
            @return.each { |resource| expect(resource.attribute_loaded?(attribute)).to eq expected }
          end
        end

        it 'sets the association for each Resource' do
          expect(@articles.map { |resource| resource.previous }).to eq [ @new, @other ]
        end
      end
    end

    describe 'with a has n relationship method' do
      before :all do
        # FIXME: create is necessary for m:m so that the intermediary
        # is created properly.  This does not occur with @new.save
        @new = @articles.send(@many_to_many ? :create : :new)

        # associate the article with children
        @article.revisions << @new
        @new.revisions     << @other

        expect(@article.save).to be(true)
      end

      describe 'with no arguments' do
        before :all do
          @return = @collection = @articles.revisions
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          expect(@collection).to eq [ @other, @new ]
        end

        it 'sets the association for each Resource' do
          expect(@articles.map { |resource| resource.revisions }).to eq [ [ @new ], [ @other ] ]
        end
      end

      describe 'with arguments' do
        before :all do
          @return = @collection = @articles.revisions(:fields => [ :id ])
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          expect(@collection).to eq [ @other, @new ]
        end

        { :id => true, :title => false, :content => false }.each do |attribute, expected|
          it "has query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
            @collection.each { |resource| expect(resource.attribute_loaded?(attribute)).to eq expected }
          end
        end

        it 'sets the association for each Resource' do
          expect(@articles.map { |resource| resource.revisions }).to eq [ [ @new ], [ @other ] ]
        end
      end
    end

    describe 'with a has n :through relationship method' do
      before :all do
        @new = @articles.create

        @publication1 = @article.publications.create(:name => 'Ruby Today')
        @publication2 = @new.publications.create(:name => 'Inside DataMapper')
      end

      describe 'with no arguments' do
        before :all do
          @return = @collection = @articles.publications
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          pending if @no_join

          expect(@collection).to eq [ @publication1, @publication2 ]
        end

        it 'sets the association for each Resource' do
          pending if @no_join

          expect(@articles.map { |resource| resource.publications }).to eq [ [ @publication1 ], [ @publication2 ] ]
        end
      end

      describe 'with arguments' do
        before :all do
          @return = @collection = @articles.publications(:fields => [ :id ])
        end

        should_not_be_a_kicker

        it 'returns a Collection' do
          expect(@return).to be_kind_of(DataMapper::Collection)
        end

        it 'returns expected Collection' do
          pending if @no_join

          expect(@collection).to eq [ @publication1, @publication2 ]
        end

        { :id => true, :name => false }.each do |attribute, expected|
          it "has query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
            @collection.each { |resource| expect(resource.attribute_loaded?(attribute)).to eq expected }
          end
        end

        it 'sets the association for each Resource' do
          pending if @no_join

          expect(@articles.map { |resource| resource.publications }).to eq [ [ @publication1 ], [ @publication2 ] ]
        end
      end
    end

    describe 'with an unknown method' do
      it 'raises an exception' do
        expect {
          @articles.unknown
        }.to raise_error(NoMethodError)
      end
    end
  end
end
