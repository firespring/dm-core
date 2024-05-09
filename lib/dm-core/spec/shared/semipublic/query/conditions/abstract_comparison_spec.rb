  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,    Serial
        property :title, String, :required => true

        belongs_to :parent, self, :required => false
        has n, :children, self, :inverse => :parent
      end
    end

    DataMapper.finalize

shared_examples 'DataMapper::Query::Conditions::AbstractComparison' do
    @model = Blog::Article
  end

  before do
    class ::OtherComparison < DataMapper::Query::Conditions::AbstractComparison
      slug :other
    end
  end

  before do
    @relationship = @model.relationships[:parent]
  end

  it { expect(subject.class).to respond_to(:new) }

  describe '.new' do
    subject { @comparison.class.new(@property, @value) }

    it { is_expected.to be_kind_of(@comparison.class) }

    it { expect(subject.subject).to equal(@property) }

    it { expect(subject.value).to eq @value }
  end

  it { expect(subject.class).to respond_to(:slug) }

  describe '.slug' do
    describe 'with no arguments' do
      subject { @comparison.class.slug }

      it { is_expected.to eq @slug }
    end

    describe 'with an argument' do
      subject { @comparison.class.slug(:other) }

      it { is_expected.to eq :other }

      # reset the slug
      after { @comparison.class.slug(@slug) }
    end
  end

  it { is_expected.to respond_to(:==) }

  describe '#==' do
    describe 'when the other AbstractComparison is equal' do
      # artificially modify the object so #== will throw an
      # exception if the equal? branch is not followed when heckling
      before { @comparison.singleton_class.send(:undef_method, :slug) }

      subject { @comparison == @comparison }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractComparison is the same class' do
      subject { @comparison == DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractComparison is a different class' do
      subject { @comparison == DataMapper::Query::Conditions::Comparison.new(:other, @property, @value) }

      it { is_expected.to be(false) }
    end

    describe 'when the other AbstractComparison is the same class, with different property' do
      subject { @comparison == DataMapper::Query::Conditions::Comparison.new(@slug, @other_property, @value) }

      it { is_expected.to be(false) }
    end

    describe 'when the other AbstractComparison is the same class, with different value' do
      subject { @comparison == DataMapper::Query::Conditions::Comparison.new(@slug, @property, @other_value) }

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:eql?) }

  describe '#eql?' do
    describe 'when the other AbstractComparison is equal' do
      # artificially modify the object so #eql? will throw an
      # exception if the equal? branch is not followed when heckling
      before { @comparison.singleton_class.send(:undef_method, :slug) }

      subject { @comparison.eql?(@comparison) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractComparison is the same class' do
      subject { @comparison.eql?(DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractComparison is a different class' do
      subject { @comparison.eql?(DataMapper::Query::Conditions::Comparison.new(:other, @property, @value)) }

      it { is_expected.to be(false) }
    end

    describe 'when the other AbstractComparison is the same class, with different property' do
      subject { @comparison.eql?(DataMapper::Query::Conditions::Comparison.new(@slug, @other_property, @value)) }

      it { is_expected.to be(false) }
    end

    describe 'when the other AbstractComparison is the same class, with different value' do
      subject { @comparison.eql?(DataMapper::Query::Conditions::Comparison.new(@slug, @property, @other_value)) }

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:hash) }

  describe '#hash' do
    subject { @comparison.hash }

    it 'matches the same AbstractComparison with the same property and value' do
      is_expected.to eq DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value).hash
    end

    it 'does not match the same AbstractComparison with different property' do
      is_expected.not_to eq DataMapper::Query::Conditions::Comparison.new(@slug, @other_property, @value).hash
    end

    it 'does not match the same AbstractComparison with different value' do
      is_expected.not_to eq DataMapper::Query::Conditions::Comparison.new(@slug, @property, @other_value).hash
    end

    it 'does not match a different AbstractComparison with the same property and value' do
      is_expected.not_to eq @other.hash
    end

    it 'does not match a different AbstractComparison with different property' do
      is_expected.not_to eq @other.class.new(@other_property, @value).hash
    end

    it 'does not match a different AbstractComparison with different value' do
      is_expected.not_to eq @other.class.new(@property, @other_value).hash
    end
  end

  it { is_expected.to respond_to(:loaded_value) }

  describe '#loaded_value' do
    subject { @comparison.loaded_value }

    it { is_expected.to eq @value }
  end

  it { is_expected.to respond_to(:parent) }

  describe '#parent' do
    subject { @comparison.parent }

    describe 'is nil by default' do
      it { is_expected.to be_nil }
    end

    describe 'relates to parent operation' do
      before do
        @operation = DataMapper::Query::Conditions::Operation.new(:and)
        @comparison.parent = @operation
      end

      it { is_expected.to be_equal(@operation) }
    end
  end

  it { is_expected.to respond_to(:parent=) }

  describe '#parent=' do
    before do
      @operation = DataMapper::Query::Conditions::Operation.new(:and)
    end

    subject { @comparison.parent = @operation }

    it { is_expected.to equal(@operation) }

    it 'changes the parent' do
      expect(method(:subject)).to change(@comparison, :parent)
        .from(nil)
        .to(@operation)
    end
  end

  it { is_expected.to respond_to(:property?) }

  describe '#property?' do
    subject { @comparison.property? }

    it { is_expected.to be(true) }
  end

  it { is_expected.to respond_to(:slug) }

  describe '#slug' do
    subject { @comparison.slug }

    it { is_expected.to eq @slug }
  end

  it { is_expected.to respond_to(:subject) }

  describe '#subject' do
    subject { @comparison.subject }

    it { is_expected.to be_equal(@property) }
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    subject { @comparison.valid? }

    describe 'when the value is valid for the subject' do
      it { is_expected.to be(true) }
    end

    describe 'when the value is not valid for the subject' do
      before do
        @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
      end

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:value) }

  describe '#value' do
    subject { @comparison.value }

    it { is_expected.to eq @value }
  end
end
