shared_examples 'A public Collection' do
  before :all do
    %w(@article_model @article @other @original @articles @other_articles).each do |ivar|
      raise "+#{ivar}+ is defined in before block" unless instance_variable_defined?(ivar)
      raise "+#{ivar}+ does not be nil in before block" unless instance_variable_get(ivar)
    end

    expect(@articles.loaded?).to eq loaded
  end

  before :all do
    @no_join = defined?(DataMapper::Adapters::InMemoryAdapter) && @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) ||
               defined?(DataMapper::Adapters::YamlAdapter)     && @adapter.kind_of?(DataMapper::Adapters::YamlAdapter)

    @one_to_many  = @articles.kind_of?(DataMapper::Associations::OneToMany::Collection)
    @many_to_many = @articles.kind_of?(DataMapper::Associations::ManyToMany::Collection)

    @skip = @no_join && @many_to_many
  end

  before do
    pending if @skip
  end

  subject { @articles }

  it { is_expected.to respond_to(:<<) }

  describe '#<<' do
    before :all do
      @resource = @article_model.new(:title => 'Title')

      @return = @articles << @resource
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'appends one Resource to the Collection' do
      expect(@articles.last).to equal(@resource)
    end
  end

  it { is_expected.to respond_to(:blank?) }

  describe '#blank?' do
    describe 'when the collection is empty' do
      it 'is true' do
        expect(@articles.clear.blank?).to be(true)
      end
    end

    describe 'when the collection is not empty' do
      it 'is false' do
        expect(@articles.blank?).to be(false)
      end
    end
  end

  it { is_expected.to respond_to(:clean?) }

  describe '#clean?' do
    describe 'with all clean resources in the collection' do
      it 'returns true' do
        expect(@articles.clean?).to be(true)
      end
    end

    describe 'with a dirty resource in the collection' do
      before :all do
        @articles.each { |r| r.content = 'Changed' }
      end

      it 'returns true' do
        expect(@articles.clean?).to be(false)
      end
    end
  end

  it { is_expected.to respond_to(:clear) }

  describe '#clear' do
    before :all do
      @resources = @articles.entries

      @return = @articles.clear
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'makes the Collection empty' do
      expect(@articles).to be_empty
    end
  end

  %i(collect! map!).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.send(method) { |resource| @article_model.new(:title => 'Ignored Title', :content => 'New Content') }
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'updates the Collection inline' do
        @articles.each do |resource|
          expect(DataMapper::Ext::Hash.only(resource.attributes, :title, :content)).to eq({title: 'Sample Article', content: 'New Content'})
        end
      end
    end
  end

  it { is_expected.to respond_to(:concat) }

  describe '#concat' do
    before :all do
      @return = @articles.concat(@other_articles)
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'concatenates the two collections' do
      expect(@return).to eq [@article, @other]
    end
  end

  %i(create create!).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      describe 'when scoped to a property' do
        before :all do
          @return = @resource = @articles.send(method)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is a saved Resource' do
          expect(@resource).to be_saved
        end

        it 'appends the Resource to the Collection' do
          expect(@articles.last).to equal(@resource)
        end

        it 'uses the query conditions to set default values' do
          expect(@resource.title).to eq 'Sample Article'
        end

        it 'does not append a Resource if create fails' do
          pending 'TODO: not sure how to best spec this'
        end
      end

      describe 'when scoped to the key' do
        before :all do
          @articles = @articles.all(:id => 1)

          @return = @resource = @articles.send(method)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is a saved Resource' do
          expect(@resource).to be_saved
        end

        it 'appends the Resource to the Collection' do
          expect(@articles.last).to equal(@resource)
        end

        it 'does not use the query conditions to set default values' do
          expect(@resource.id).not_to eq 1
        end

        it 'does not append a Resource if create fails' do
          pending 'TODO: not sure how to best spec this'
        end
      end

      describe 'when scoped to a property with multiple values' do
        before :all do
          @articles = @articles.all(:content => %w[ Sample Other ])

          @return = @resource = @articles.send(method)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is a saved Resource' do
          expect(@resource).to be_saved
        end

        it 'appends the Resource to the Collection' do
          expect(@articles.last).to equal(@resource)
        end

        it 'does not use the query conditions to set default values' do
          expect(@resource.content).to be_nil
        end

        it 'does not append a Resource if create fails' do
          pending 'TODO: not sure how to best spec this'
        end
      end

      describe 'when scoped with a condition other than eql' do
        before :all do
          @articles = @articles.all(:content.not => 'Sample')

          @return = @resource = @articles.send(method)
        end

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'is a saved Resource' do
          expect(@resource).to be_saved
        end

        it 'appends the Resource to the Collection' do
          expect(@articles.last).to equal(@resource)
        end

        it 'does not use the query conditions to set default values' do
          expect(@resource.content).to be_nil
        end

        it 'does not append a Resource if create fails' do
          pending 'TODO: not sure how to best spec this'
        end
      end
    end
  end

  %i(difference -).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @articles.send(method, @other_articles) }

      describe 'with a Collection' do
        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article] }
        it { expect(subject.query).to eq @articles.query.difference(@other_articles.query) }
        it { is_expected.to eq @articles.to_a - @other_articles.to_a }
      end

      describe 'with an Array' do
        before { @other_articles = @other_articles.to_ary }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article] }
        it { is_expected.to eq @articles.to_a - @other_articles.to_a }
      end

      describe 'with a Set' do
        before { @other_articles = @other_articles.to_set }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article] }
        it { is_expected.to eq @articles.to_a - @other_articles.to_a }
      end
    end
  end

  it { is_expected.to respond_to(:delete) }

  describe '#delete' do
    describe 'with a Resource within the Collection' do
      before :all do
        @return = @resource = @articles.delete(@article)
      end

      it 'returns a DataMapper::Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the expected Resource' do
        # compare keys because FK attributes may have been altered
        # when removing from the Collection
        expect(@resource.key).to eq @article.key
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@resource)
      end
    end

    describe 'with a Resource not within the Collection' do
      before :all do
        @return = @articles.delete(@other)
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end
  end

  it { is_expected.to respond_to(:delete_at) }

  describe '#delete_at' do
    describe 'with an offset within the Collection' do
      before :all do
        @return = @resource = @articles.delete_at(0)
      end

      it 'returns a DataMapper::Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the expected Resource' do
        expect(@resource.key).to eq @article.key
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@resource)
      end
    end

    describe 'with an offset not within the Collection' do
      before :all do
        @return = @articles.delete_at(1)
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end
  end

  it { is_expected.to respond_to(:delete_if) }

  describe '#delete_if' do
    describe 'with a block that matches a Resource in the Collection' do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.delete_if { true }
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end
    end

    describe 'with a block that does not match a Resource in the Collection' do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.delete_if { false }
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'does not modify the Collection' do
        expect(@articles).to eq @resources
      end
    end
  end

  %i(destroy destroy!).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      describe 'on a normal collection' do
        before :all do
          @return = @articles.send(method)
        end

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'removes the Resources from the datasource' do
          expect(@article_model.all(title: 'Sample Article')).to be_empty
        end

        it 'clears the collection' do
          expect(@articles).to be_empty
        end
      end

      describe 'on a limited collection' do
        before :all do
          @other   = @articles.create
          @limited = @articles.all(:limit => 1)

          @return = @limited.send(method)
        end

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'removes the Resources from the datasource' do
          expect(@article_model.all(title: 'Sample Article')).to eq [@other]
        end

        it 'clears the collection' do
          expect(@limited).to be_empty
        end

        it 'does not destroy the other Resource' do
          expect(@article_model.get!(*@other.key)).not_to be_nil
        end
      end
    end
  end

  it { is_expected.to respond_to(:dirty?) }

  describe '#dirty?' do
    describe 'with all clean resources in the collection' do
      it 'returns false' do
        expect(@articles.dirty?).to be(false)
      end
    end

    describe 'with a dirty resource in the collection' do
      before :all do
        @articles.each { |r| r.content = 'Changed' }
      end

      it 'returns true' do
        expect(@articles.dirty?).to be(true)
      end
    end
  end

  it { is_expected.to respond_to(:insert) }

  describe '#insert' do
    before :all do
      @resources = @other_articles

      @return = @articles.insert(0, *@resources)
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'inserts one or more Resources at a given offset' do
      expect(@articles).to eq @resources << @article
    end
  end

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    before :all do
      @copy = @articles.dup
      @copy << @article_model.new(:title => 'Ignored Title', :content => 'Other Article')

      @return = @copy.inspect
    end

    it { expect(@return).to match(/\A\[.*\]\z/) }
    it { expect(@return).to match(/\bid=#{@article.id}\b/) }
    it { expect(@return).to match(/\bid=nil\b/) }
    it { expect(@return).to match(/\btitle="Sample Article"\s/) }
    it { expect(@return).not_to match(/\btitle="Ignored Title"\s/) }
    it { expect(@return).to match(/\bcontent="Other Article"\s/) }
  end

  %i(intersection &).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @articles.send(method, @other_articles) }

      describe 'with a Collection' do
        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [] }
        it { expect(subject.query).to eq @articles.query.intersection(@other_articles.query) }
        it { is_expected.to eq @articles.to_a & @other_articles.to_a }
      end

      describe 'with an Array' do
        before { @other_articles = @other_articles.to_ary }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [] }
        it { is_expected.to eq @articles.to_a & @other_articles.to_a }
      end

      describe 'with a Set' do
        before { @other_articles = @other_articles.to_set }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [] }
        it { is_expected.to eq @articles.to_a & @other_articles.to_a }
      end
    end
  end

  it { is_expected.to respond_to(:new) }

  describe '#new' do
    describe 'when scoped to a property' do
      before :all do
        @source = @articles.new(:attachment => "A File")
        @return = @resource = @articles.new(:original => @source)
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is a new Resource' do
        expect(@resource).to be_new
      end

      it 'appends the Resource to the Collection' do
        expect(@articles.last).to equal(@resource)
      end

      it 'uses the query conditions to set default values' do
        expect(@resource.title).to eq 'Sample Article'
      end

      it 'uses the query conditions to set default values when accessed through a m:1 relationship' do
        expect(@resource.original.attachment).to eq 'A File'
      end
    end

    describe 'when scoped to the key' do
      before :all do
        @articles = @articles.all(:id => 1)

        @return = @resource = @articles.new
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is a new Resource' do
        expect(@resource).to be_new
      end

      it 'appends the Resource to the Collection' do
        expect(@articles.last).to equal(@resource)
      end

      it 'does not use the query conditions to set default values' do
        expect(@resource.id).to be_nil
      end
    end

    describe 'when scoped to a property with multiple values' do
      before :all do
        @articles = @articles.all(:content => %w[ Sample Other ])

        @return = @resource = @articles.new
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is a new Resource' do
        expect(@resource).to be_new
      end

      it 'appends the Resource to the Collection' do
        expect(@articles.last).to equal(@resource)
      end

      it 'does not use the query conditions to set default values' do
        expect(@resource.content).to be_nil
      end
    end

    describe 'when scoped with a condition other than eql' do
      before :all do
        @articles = @articles.all(:content.not => 'Sample')

        @return = @resource = @articles.new
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is a new Resource' do
        expect(@resource).to be_new
      end

      it 'appends the Resource to the Collection' do
        expect(@articles.last).to equal(@resource)
      end

      it 'does not use the query conditions to set default values' do
        expect(@resource.content).to be_nil
      end
    end
  end

  it { is_expected.to respond_to(:pop) }

  describe '#pop' do
    before :all do
      @new = @articles.create(:title => 'Sample Article')  # TODO: freeze @new
    end

    describe 'with no arguments' do
      before :all do
        @return = @articles.pop
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the last Resource in the Collection' do
        expect(@return).to eq @new
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@new)
      end
    end

    if RUBY_VERSION >= '1.8.7'
      describe 'with a limit specified' do
        before :all do
          @return = @articles.pop(1)
        end

        it 'returns an Array' do
          expect(@return).to be_kind_of(Array)
        end

        it 'returns the expected Resources' do
          expect(@return).to eq [@new]
        end

        it 'removes the Resource from the Collection' do
          expect(@articles).not_to include(@new)
        end
      end
    end
  end

  it { is_expected.to respond_to(:push) }

  describe '#push' do
    before :all do
      @resources = [ @article_model.new(:title => 'Title 1'), @article_model.new(:title => 'Title 2') ]

      @return = @articles.push(*@resources)
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'appends the Resources to the Collection' do
      expect(@articles).to eq [@article] + @resources
    end
  end

  it { is_expected.to respond_to(:reject!) }

  describe '#reject!' do
    describe 'with a block that matches a Resource in the Collection' do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.reject! { true }
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end
    end

    describe 'with a block that does not match a Resource in the Collection' do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.reject! { false }
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end

      it 'does not modify the Collection' do
        expect(@articles).to eq @resources
      end
    end
  end

  it { is_expected.to respond_to(:reload) }

  describe '#reload' do
    describe 'with no arguments' do
      before :all do
        @resources = @articles.dup.entries

        @return = @collection = @articles.reload
      end

      # FIXME: this is spec order dependent, move this into a helper method
      # and execute in the before :all block
      unless loaded
        it 'does not be a kicker' do
          pending do
            expect(@articles).not_to be_loaded
          end
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      {title: true, content: false}.each do |attribute, expected|
        it "has query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
          @collection.each { |resource| expect(resource.attribute_loaded?(attribute)).to eq expected }
        end
      end
    end

    describe 'with a Hash query' do
      before :all do
        @resources = @articles.dup.entries

        @return = @collection = @articles.reload(:fields => [ :content ])  # :title is a default field
      end

      # FIXME: this is spec order dependent, move this into a helper method
      # and execute in the before :all block
      unless loaded
        it 'does not be a kicker' do
          pending do
            expect(@articles).not_to be_loaded
          end
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      %i(id content title).each do |attribute|
        it "has query field #{attribute.inspect} loaded" do
          @collection.each { |resource| expect(resource.attribute_loaded?(attribute)).to be(true) }
        end
      end
    end

    describe 'with a Query' do
      before :all do
        @query = DataMapper::Query.new(@repository, @article_model, :fields => [ :content ])  # :title is an original field

        @return = @collection = @articles.reload(@query)
      end

      # FIXME: this is spec order dependent, move this into a helper method
      # and execute in the before :all block
      unless loaded
        it 'does not be a kicker' do
          pending do
            expect(@articles).not_to be_loaded
          end
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      %i(id content title).each do |attribute|
        it "has query field #{attribute.inspect} loaded" do
          @collection.each { |resource| expect(resource.attribute_loaded?(attribute)).to be(true) }
        end
      end
    end
  end

  it { is_expected.to respond_to(:replace) }

  describe '#replace' do
    describe 'when provided an Array of Resources' do
      before :all do
        @resources = @articles.dup.entries

        @return = @articles.replace(@other_articles)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'updates the Collection with new Resources' do
        expect(@articles).to eq @other_articles
      end
    end

    describe 'when provided an Array of Hashes' do
      before :all do
        @array = [ { :content => 'From Hash' } ].freeze

        @return = @articles.replace(@array)
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'initializes a Resource' do
        expect(@return.first).to be_kind_of(DataMapper::Resource)
      end

      it 'is a new Resource' do
        expect(@return.first).to be_new
      end

      it 'is a Resource with attributes matching the Hash' do
        expect(DataMapper::Ext::Hash.only(@return.first.attributes, *@array.first.keys)).to eq @array.first
      end
    end
  end

  it { is_expected.to respond_to(:reverse!) }

  describe '#reverse!' do
    before :all do
      @query = @articles.query

      @new = @articles.create(:title => 'Sample Article')

      @return = @articles.reverse!
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'returns a Collection with reversed entries' do
      expect(@return).to eq [@new, @article]
    end

    it 'returns a Query that equal to the original' do
      expect(@return.query).to equal(@query)
    end
  end

  %i(save save!).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      describe 'when Resources are not saved' do
        before :all do
          @articles.new(:title => 'New Article', :content => 'New Article')

          @return = @articles.send(method)
        end

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'saves each Resource' do
          @articles.each { |resource| expect(resource).to be_saved }
        end
      end

      describe 'when Resources have been orphaned' do
        before :all do
          @resources = @articles.entries
          @articles.replace([])

          @return = @articles.send(method)
        end

        it 'returns true' do
          expect(@return).to be(true)
        end
      end
    end
  end

  it { is_expected.to respond_to(:shift) }

  describe '#shift' do
    describe 'with no arguments' do
      before :all do
        @return = @articles.shift
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'is the first Resource in the Collection' do
        expect(@return.key).to eq @article.key
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@return)
      end
    end

    if RUBY_VERSION >= '1.8.7'
      describe 'with a limit specified' do
        before :all do
          @return = @articles.shift(1)
        end

        it 'returns an Array' do
          expect(@return).to be_kind_of(Array)
        end

        it 'returns the expected Resources' do
          expect(@return.size).to eq 1
          expect(@return.first.key).to eq @article.key
        end

        it 'removes the Resource from the Collection' do
          expect(@articles).not_to include(@article)
        end
      end
    end
  end

  it { is_expected.to respond_to(:slice!) }

  describe '#slice!' do
    before :all do
      1.upto(10) { |number| @articles.create(:content => "Article #{number}") }

      @copy = @articles.dup
    end

    describe 'with a positive offset' do
      before :all do
        unless @skip
          @return = @resource = @articles.slice!(0)
        end
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'returns expected Resource' do
        expect(@return.key).to eq @article.key
      end

      it 'returns the same as Array#slice!' do
        expect(@return).to eq @copy.entries.slice!(0)
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@resource)
      end
    end

    describe 'with a positive offset and length' do
      before :all do
        unless @skip
          @return = @resources = @articles.slice!(5, 5)
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns the expected Resource' do
        expect(@return).to eq @copy.entries.slice!(5, 5)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end

      it 'scopes the Collection' do
        expect(@resources.reload).to eq @copy.entries.slice!(5, 5)
      end
    end

    describe 'with a positive range' do
      before :all do
        unless @skip
          @return = @resources = @articles.slice!(5..10)
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns the expected Resources' do
        expect(@return).to eq @copy.entries.slice!(5..10)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end

      it 'scopes the Collection' do
        expect(@resources.reload).to eq @copy.entries.slice!(5..10)
      end
    end

    describe 'with a negative offset' do
      before :all do
        unless @skip
          @return = @resource = @articles.slice!(-1)
        end
      end

      it 'returns a Resource' do
        expect(@return).to be_kind_of(DataMapper::Resource)
      end

      it 'returns expected Resource' do
        expect(@return).to eq @copy.entries.slice!(-1)
      end

      it 'removes the Resource from the Collection' do
        expect(@articles).not_to include(@resource)
      end
    end

    describe 'with a negative offset and length' do
      before :all do
        unless @skip
          @return = @resources = @articles.slice!(-5, 5)
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns the expected Resources' do
        expect(@return).to eq @copy.entries.slice!(-5, 5)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end

      it 'scopes the Collection' do
        expect(@resources.reload).to eq @copy.entries.slice!(-5, 5)
      end
    end

    describe 'with a negative range' do
      before :all do
        unless @skip
          @return = @resources = @articles.slice!(-3..-2)
        end
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns the expected Resources' do
        expect(@return).to eq @copy.entries.slice!(-3..-2)
      end

      it 'removes the Resources from the Collection' do
        @resources.each { |resource| expect(@articles).not_to include(resource) }
      end

      it 'scopes the Collection' do
        expect(@resources.reload).to eq @copy.entries.slice!(-3..-2)
      end
    end

    describe 'with an offset not within the Collection' do
      before :all do
        unless @skip
          @return = @articles.slice!(12)
        end
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end

    describe 'with an offset and length not within the Collection' do
      before :all do
        unless @skip
          @return = @articles.slice!(12, 1)
        end
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end

    describe 'with a range not within the Collection' do
      before :all do
        unless @skip
          @return = @articles.slice!(12..13)
        end
      end

      it 'returns nil' do
        expect(@return).to be_nil
      end
    end
  end

  it { is_expected.to respond_to(:sort!) }

  describe '#sort!' do
    describe 'without a block' do
      before :all do
        @return = @articles.unshift(@other).sort!
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'modifies and sorts the Collection using default sort order' do
        expect(@articles).to eq [@article, @other]
      end
    end

    describe 'with a block' do
      before :all do
        @return = @articles.unshift(@other).sort! { |a_resource, b_resource| b_resource.id <=> a_resource.id }
      end

      it 'returns a Collection' do
        expect(@return).to be_kind_of(DataMapper::Collection)
      end

      it 'returns self' do
        expect(@return).to equal(@articles)
      end

      it 'modifies and sorts the Collection using supplied block' do
        expect(@articles).to eq [@other, @article]
      end
    end
  end

  %i(splice []=).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      before :all do
        unless @skip
          orphans = (1..10).map do |number|
            articles = @articles.dup
            articles.create(:content => "Article #{number}")
            articles.pop  # remove the article from the tail
          end

          @articles.unshift(*orphans.first(5))
          @articles.concat(orphans.last(5))

          expect(@articles).not_to be_loaded unless loaded

          @copy = @articles.dup
          @new = @article_model.new(:content => 'New Article')
        end
      end

      describe 'with a positive offset and a Resource' do
        before :all do
          rescue_if @skip do
            @original = @copy[1]

            @return = @resource = @articles.send(method, 1, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns expected Resource' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[1] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end

      describe 'with a positive offset and length and a Resource' do
        before :all do
          rescue_if @skip do
            @original = @copy[2]

            @return = @resource = @articles.send(method, 2, 1, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resource' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[2, 1] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end

      describe 'with a positive range and a Resource' do
        before :all do
          rescue_if @skip do
            @originals = @copy.values_at(2..3)

            @return = @resource = @articles.send(method, 2..3, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resources' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[2..3] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end

      describe 'with a negative offset and a Resource' do
        before :all do
          rescue_if @skip do
            @original = @copy[-1]

            @return = @resource = @articles.send(method, -1, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns expected Resource' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[-1] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end

      describe 'with a negative offset and length and a Resource' do
        before :all do
          rescue_if @skip do
            @original = @copy[-2]
            @return = @resource = @articles.send(method, -2, 1, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resource' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[-2, 1] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end

      describe 'with a negative range and a Resource' do
        before :all do
          rescue_if @skip do
            @originals = @articles.values_at(-3..-2)
            @return = @resource = @articles.send(method, -3..-2, @new)
          end
        end

        should_not_be_a_kicker

        it 'returns a Resource' do
          expect(@return).to be_kind_of(DataMapper::Resource)
        end

        it 'returns the expected Resources' do
          expect(@return).to equal(@new)
        end

        it 'returns the same as Array#[]=' do
          expect(@return).to eq @copy.entries[-3..-2] = @new
        end

        it 'includes the Resource in the Collection' do
          expect(@articles).to include(@resource)
        end
      end
    end
  end

  describe '#[]=' do
    describe 'when swapping resources' do
      before :all do
        rescue_if @skip do
          @articles.create(:content => 'Another Article')

          @entries = @articles.entries

          @articles[0], @articles[1] = @articles[1], @articles[0]
        end
      end

      it 'includes the Resource in the Collection' do
        expect(@articles).to eq @entries.reverse
      end
    end
  end

  %i(union | +).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @articles.send(method, @other_articles) }

      describe 'with a Collection' do
        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article, @other] }
        it { expect(subject.query).to eq @articles.query.union(@other_articles.query) }
        it { is_expected.to eq @articles.to_a | @other_articles.to_a }
      end

      describe 'with an Array' do
        before { @other_articles = @other_articles.to_ary }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article, @other] }
        it { is_expected.to eq @articles.to_a | @other_articles.to_a }
      end

      describe 'with a Set' do
        before { @other_articles = @other_articles.to_set }

        it { is_expected.to be_kind_of(DataMapper::Collection) }
        it { is_expected.to eq [@article, @other] }
        it { is_expected.to eq @articles.to_a | @other_articles.to_a }
      end
    end
  end

  it { is_expected.to respond_to(:unshift) }

  describe '#unshift' do
    before :all do
      @resources = [ @article_model.new(:title => 'Title 1'), @article_model.new(:title => 'Title 2') ]

      @return = @articles.unshift(*@resources)
    end

    it 'returns a Collection' do
      expect(@return).to be_kind_of(DataMapper::Collection)
    end

    it 'returns self' do
      expect(@return).to equal(@articles)
    end

    it 'prepends the Resources to the Collection' do
      expect(@articles).to eq @resources + [@article]
    end
  end

  %i(update update!).each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      describe 'with attributes' do
        before :all do
          @attributes = { :title => 'Updated Title' }

          @return = @articles.send(method, @attributes)
        end

        should_not_be_a_kicker if method == :update!

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'updates attributes of all Resources' do
          @articles.each { |resource| @attributes.each { |key, value| expect(resource.__send__(key)).to eq value } }
        end

        it 'persists the changes' do
          resource = @article_model.get!(*@article.key)
          @attributes.each { |key, value| expect(resource.__send__(key)).to eq value }
        end
      end

      describe 'with attributes where one is a parent association' do
        before :all do
          @attributes = { :original => @other }

          @return = @articles.send(method, @attributes)
        end

        if method == :update!
          should_not_be_a_kicker
        end

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'updates attributes of all Resources' do
          @articles.each { |resource| @attributes.each { |key, value| expect(resource.__send__(key)).to eq value } }
        end

        it 'persists the changes' do
          resource = @article_model.get!(*@article.key)
          @attributes.each { |key, value| expect(resource.__send__(key)).to eq value }
        end
      end

      describe 'with attributes where a required property is nil' do
        before :all do
          expect { @articles.send(method, title: nil) }.to(raise_error(DataMapper::Property::InvalidValueError) do |error|
            expect(error.property).to eq @articles.model.title
          end)
        end

        if method == :update!
          should_not_be_a_kicker
        end
      end

      describe 'on a limited collection' do
        before :all do
          @other      = @articles.create
          @limited    = @articles.all(:limit => 1)
          @attributes = { :content => 'Updated Content' }

          @return = @limited.send(method, @attributes)
        end

        if method == :update!
          should_not_be_a_kicker(:@limited)
        end

        it 'returns true' do
          expect(@return).to be(true)
        end

        it 'bypasses validation' do
          pending 'TODO: not sure how to best spec this'
        end

        it 'updates attributes of all Resources' do
          @limited.each { |resource| @attributes.each { |key, value| expect(resource.__send__(key)).to eq value } }
        end

        it 'persists the changes' do
          resource = @article_model.get!(*@article.key)
          @attributes.each { |key, value| expect(resource.__send__(key)).to eq value }
        end

        it 'does not update the other Resource' do
          @other.reload
          @attributes.each { |key, value| expect(@other.__send__(key)).not_to eq value }
        end
      end

      describe 'on a dirty collection' do
        before :all do
          @articles.each { |r| r.content = 'Changed' }
        end

        it 'raises an exception' do
          lambda {
            @articles.send(method, :content => 'New Content')
          }.should raise_error(DataMapper::UpdateConflictError, "#{@articles.class}##{method} cannot be called on a dirty collection")
        end
      end
    end
  end

  it 'responds to a public model method with #method_missing' do
    expect(@articles).to respond_to(:base_model)
  end

  describe '#method_missing' do
    describe 'with a public model method' do
      before :all do
        @return = @articles.model.base_model
      end

      should_not_be_a_kicker

      it 'returns expected object' do
        expect(@return).to eq @article_model
      end
    end
  end
end
