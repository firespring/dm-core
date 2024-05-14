require_relative '../../spec_helper'

# class methods
describe DataMapper::Query::Path do
  before :all do
    class ::Author
      include DataMapper::Resource

      property :id,    Serial
      property :title, String

      has n, :articles
    end

    class ::Article
      include DataMapper::Resource

      property :id,    Serial
      property :title, String

      belongs_to :author
    end

    @relationship  = Author.relationships[:articles]
    @relationships = [ @relationship ]
    @property      = Article.properties[:title]
    DataMapper.finalize
  end

  it { expect(DataMapper::Query::Path).to respond_to(:new) }

  describe '.new' do
    describe 'when supplied an Array of Relationships' do
      before do
        @path = DataMapper::Query::Path.new(@relationships)
      end

      it 'returns a Query::Path' do
        expect(@path).to be_kind_of(DataMapper::Query::Path)
      end

      it 'sets Query::Path#relationships' do
        expect(@path.relationships).to eql(@relationships)
      end

      it 'copies the relationships' do
        expect(@path.relationships).not_to equal(@relationships)
      end
    end

    describe 'when supplied an Array of Relationships and a Property Symbol name' do
      before do
        @path = DataMapper::Query::Path.new(@relationships, @property.name)
      end

      it 'returns a Query::Path' do
        expect(@path).to be_kind_of(DataMapper::Query::Path)
      end

      it 'sets Query::Path#relationships' do
        expect(@path.relationships).to eql(@relationships)
      end

      it 'copies the relationships' do
        expect(@path.relationships).not_to equal(@relationships)
      end

      it 'sets Query::Path#property' do
        expect(@path.property).to equal(@property)
      end
    end

    describe 'when supplied an unknown property' do
      it 'raises an error' do
        expect { DataMapper::Query::Path.new(@relationships, :unknown) }.to raise_error(ArgumentError, "Unknown property 'unknown' in Article")
      end
    end
  end
end

# instance methods
describe DataMapper::Query::Path do
  before :all do
    class ::Author
      include DataMapper::Resource

      property :id,    Serial
      property :title, String

      has n, :articles
    end

    class ::Article
      include DataMapper::Resource

      property :id,    Serial
      property :title, String

      belongs_to :author
    end

    @relationship  = Author.relationships[:articles]
    @relationships = [ @relationship ]
    @property      = Article.properties[:title]

    @path = DataMapper::Query::Path.new(@relationships)
    DataMapper.finalize
  end

  it { expect(@path).to respond_to(:==) }

  describe '#==' do
    describe 'when other Query::Path is the same' do
      before do
        @other = @path

        @return = @path == @other
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when other Query::Path does not respond to #relationships' do
      before do
        class << @other = @path.dup
          undef_method :relationships
        end

        @return = @path == @other
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path does not respond to #property' do
      before do
        class << @other = @path.dup
          undef_method :property
        end

        @return = @path == @other
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has different relationships' do
      before do
        @other = DataMapper::Query::Path.new([ Article.relationships[:author] ])

        @return = @path == @other
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has different properties' do
      before do
        @other = DataMapper::Query::Path.new(@path.relationships, :title)

        @return = @path == @other
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has the same relationship and property' do
      before do
        @other = DataMapper::Query::Path.new(@path.relationships, @path.property)

        @return = @path == @other
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end
  end

  it { expect(@path).to respond_to(:eql?) }

  describe '#eql?' do
    describe 'when other Query::Path is the same' do
      before do
        @other = @path

        @return = @path.eql?(@other)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when other Object is not an instance of Query::Path' do
      before do
        class MyQueryPath < DataMapper::Query::Path; end

        @other = MyQueryPath.new(@path.relationships, @path.property)

        @return = @path.eql?(@other)
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has different relationships' do
      before do
        @other = DataMapper::Query::Path.new([ Article.relationships[:author] ])

        @return = @path.eql?(@other)
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has different properties' do
      before do
        @other = DataMapper::Query::Path.new(@path.relationships, :title)

        @return = @path.eql?(@other)
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end

    describe 'when other Query::Path has the same relationship and property' do
      before do
        @other = DataMapper::Query::Path.new(@path.relationships, @path.property)

        @return = @path.eql?(@other)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end
  end

  it { expect(@path).to respond_to(:model) }

  describe '#model' do
    it 'returns a Model' do
      expect(@path.model).to be_kind_of(DataMapper::Model)
    end

    it 'returns expected value' do
      expect(@path.model).to eql(Article)
    end
  end

  it { expect(@path).to respond_to(:property) }

  describe '#property' do
    describe 'when no property is defined' do
      it 'returns nil' do
        expect(@path.property).to be_nil
      end
    end

    describe 'when a property is defined' do
      before do
        @path = @path.class.new(@path.relationships, @property.name)
      end

      it 'returns a Property' do
        expect(@path.property).to be_kind_of(DataMapper::Property::Object)
      end

      it 'returns expected value' do
        expect(@path.property).to eql(@property)
      end
    end
  end

  it { expect(@path).to respond_to(:relationships) }

  describe '#relationships' do
    it 'returns an Array' do
      expect(@path.relationships).to be_kind_of(Array)
    end

    it 'returns expected value' do
      expect(@path.relationships).to eql(@relationships)
    end
  end

  it { expect(@path).to respond_to(:respond_to?) }

  describe '#respond_to?' do
    describe 'when supplied a method name provided by the parent class' do
      before do
        @return = @path.respond_to?(:class)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when supplied a method name provided by the property' do
      before do
        @path = @path.class.new(@path.relationships, @property.name)

        @return = @path.respond_to?(:instance_variable_name)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when supplied a method name referring to a relationship' do
      before do
        @return = @path.respond_to?(:author)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when supplied a method name referring to a property' do
      before do
        @return = @path.respond_to?(:title)
      end

      it 'returns true' do
        expect(@return).to be(true)
      end
    end

    describe 'when supplied an unknown method name' do
      before do
        @return = @path.respond_to?(:unknown)
      end

      it 'returns false' do
        expect(@return).to be(false)
      end
    end
  end

  it { expect(@path).to respond_to(:repository_name) }

  describe '#repository_name' do
    it 'returns a Symbol' do
      expect(@path.repository_name).to be_kind_of(Symbol)
    end

    it 'returns expected value' do
      expect(@path.repository_name).to eql(:default)
    end
  end

  describe '#method_missing' do
    describe 'when supplied a method name provided by the parent class' do
      before do
        @return = @path.class
      end

      it 'returns the expected value' do
        expect(@return).to eql(DataMapper::Query::Path)
      end
    end

    describe 'when supplied a method name provided by the property' do
      before do
        @path = @path.class.new(@path.relationships, @property.name)

        @return = @path.instance_variable_name
      end

      it 'returns the expected value' do
        expect(@return).to eql('@title')
      end
    end

    describe 'when supplied a method name referring to a relationship' do
      before do
        @return = @path.author
      end

      it 'returns a Query::Path' do
        expect(@return).to be_kind_of(DataMapper::Query::Path)
      end

      it 'returns the expected value' do
        expect(@return).to eql(DataMapper::Query::Path.new([ @relationship, Article.relationships[:author] ]))
      end
    end

    describe 'when supplied a method name referring to a property' do
      before do
        @return = @path.title
      end

      it 'returns a Query::Path' do
        expect(@return).to be_kind_of(DataMapper::Query::Path)
      end

      it 'returns the expected value' do
        expect(@return).to eql(DataMapper::Query::Path.new(@relationships, :title))
      end
    end

    describe 'when supplied an unknown method name' do
      it 'raises an error' do
        expect { @path.unknown }.to raise_error(NoMethodError, "undefined property or relationship 'unknown' on Article")
      end
    end
  end

  describe 'ordering' do
    before do
      @path = Article.author.title
    end

    describe '#desc' do
      before do
        @return = @path.desc
      end

      it 'returns a :desc operator from the path' do
        expect(@return).to eq DataMapper::Query::Operator.new(@path.property, :desc)
      end
    end

    describe '#asc' do
      before do
        @return = @path.asc
      end

      it 'returns a :desc operator from the path' do
        expect(@return).to eq DataMapper::Query::Operator.new(@path.property, :asc)
      end
    end
  end

  ((DataMapper::Query::Conditions::Comparison.slugs | [ :not ]) - [ :eql, :in ]).each do |slug|
    describe "##{slug}" do
      before do
        @return = @path.send(slug)
      end

      it 'returns a Query::Operator' do
        expect(@return).to be_kind_of(DataMapper::Query::Operator)
      end

      it 'returns expected value' do
        expect(@return).to eql(DataMapper::Query::Operator.new(@path, slug))
      end
    end
  end
end
