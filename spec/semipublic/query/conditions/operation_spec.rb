require_relative '../../../spec_helper'

module OperationMatchers
  class HaveValidParent
    def matches?(target)
      stack = []
      stack << [ target, target.operands ] if target.respond_to?(:operands)

      while node = stack.pop
        @expected, operands = node

        operands.each do |operand|
          @target = operand
          @actual = @target.parent

          return false unless @actual.equal?(@expected)

          if @target.respond_to?(:operands)
            stack << [ @target, @target.operands ]
          end
        end
      end

      true
    end

    def failure_message
      <<-OUTPUT
        expected: #{@expected.inspect}
             got: #{@actual.inspect}
      OUTPUT
    end
  end

  def have_operands_with_valid_parent
    HaveValidParent.new
  end
end

shared_examples 'DataMapper::Query::Conditions::AbstractOperation' do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,    Serial
        property :title, String, :required => true
      end
    end
    DataMapper.finalize

    @model = Blog::Article
  end

  before do
    class ::OtherOperation < DataMapper::Query::Conditions::AbstractOperation
      slug :other
    end
  end

  before do
    @comparison     = DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:title], 'A title')
    @and_operation  = DataMapper::Query::Conditions::Operation.new(:and)
    @or_operation   = DataMapper::Query::Conditions::Operation.new(:or)
    @not_operation  = DataMapper::Query::Conditions::Operation.new(:not)
    @null_operation = DataMapper::Query::Conditions::Operation.new(:null)
    @other          = OtherOperation.new
  end

  it { expect(@operation.class).to respond_to(:new) }

  describe '.new' do
    describe 'with no arguments' do
      subject { @operation.class.new }

      it { is_expected.to be_kind_of(@operation.class) }
    end

    describe 'with arguments' do
      subject { @operation.class.new(@comparison) }

      it { is_expected.to be_kind_of(@operation.class) }
    end
  end

  it { expect(@operation.class).to respond_to(:slug) }

  describe '.slug' do
    describe 'with no arguments' do
      subject { @operation.class.slug }

      it { is_expected.to eq @slug }
    end

    describe 'with an argument' do
      subject { @operation.class.slug(:other) }

      it { is_expected.to eq :other }

      # reset the AndOperation slug
      after { @operation.class.slug(@slug) }
    end
  end

  it { is_expected.to respond_to(:==) }

  describe '#==' do
    describe 'when the other AbstractOperation is equal' do
      # artificially modify the object so #== will throw an
      # exception if the equal? branch is not followed when heckling
      before { @operation.singleton_class.send(:undef_method, :slug) }

      subject { @operation == @operation }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractOperation is the same class' do
      subject { @operation == DataMapper::Query::Conditions::Operation.new(@slug) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractOperation is a different class, with the same slug' do
      before { @other.class.slug(@slug) }

      subject { @operation == @other }

      it { is_expected.to be(false) }

      # reset the OtherOperation slug
      after { @other.class.slug(:other) }
    end

    describe 'when the other AbstractOperation is the same class, with different operands' do
      subject { @operation == DataMapper::Query::Conditions::Operation.new(@slug, @comparison) }

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:<<) }

  describe '#<<' do
    describe 'with a NullOperation' do
      subject { @operation << @null_operation }

      it { is_expected.to equal(@operation) }

      it 'merges the operand' do
        expect(subject.to_a).to eq [ @null_operation.class.new ]
      end

      it { is_expected.to have_operands_with_valid_parent }
    end

    describe 'with a duplicate operand' do
      before { @operation << @comparison.dup }

      subject { @operation << @comparison.dup }

      it { is_expected.to equal(@operation) }

      it 'has unique operands' do
        expect(subject.to_a).to eq [ @comparison ]
      end

      it { is_expected.to have_operands_with_valid_parent }
    end

    describe 'with an invalid operand' do
      subject { @operation << '' }

      it { expect { method(:subject) }.to raise_error(ArgumentError, '+operand+ should be DataMapper::Query::Conditions::AbstractOperation or DataMapper::Query::Conditions::AbstractComparison or Array, but was String')  }
    end
  end

  it { is_expected.to respond_to(:children) }

  describe '#children' do
    subject { @operation.children }

    it { is_expected.to be_kind_of(Set) }

    it { is_expected.to be_empty }

    it { is_expected.to equal(@operation.operands) }
  end

  it { is_expected.to respond_to(:clear) }

  describe '#clear' do
    before do
      @operation << @other
      expect(@operation).not_to be_empty
    end

    subject { @operation.clear }

    it { is_expected.to equal(@operation) }

    it 'clears the operands' do
      expect(subject).to be_empty
    end
  end

  [ :difference, :- ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @operation.send(method, @comparison) }

      it { is_expected.to eql(@not_operation.class.new(@comparison)) }
    end
  end

  it { is_expected.to respond_to(:dup) }

  describe '#dup' do
    subject { @operation.dup }

    it { is_expected.not_to equal(@operation) }

    it { expect(subject.to_a).to eq @operation.to_a }
  end

  it { is_expected.to respond_to(:each) }

  describe '#each' do
    before do
      @yield = []
      @operation << @other
    end

    subject { @operation.each { |operand| @yield << operand } }

    it { is_expected.to equal(@operation) }

    it 'yields to every operand' do
      subject
      expect(@yield).to eq [ @other ]
    end
  end

  it { is_expected.to respond_to(:eql?) }

  describe '#eql?' do
    describe 'when the other AbstractOperation is equal' do
      # artificially modify the object so #eql? will throw an
      # exception if the equal? branch is not followed when heckling
      before { @operation.singleton_class.send(:undef_method, :slug) }

      subject { @operation.eql?(@operation) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractOperation is the same class' do
      subject { @operation.eql?(DataMapper::Query::Conditions::Operation.new(@slug)) }

      it { is_expected.to be(true) }
    end

    describe 'when the other AbstractOperation is a different class' do
      subject { @operation.eql?(DataMapper::Query::Conditions::Operation.new(:other)) }

      it { is_expected.to be(false) }
    end

    describe 'when the other AbstractOperation is the same class, with different operands' do
      subject { @operation.eql?(DataMapper::Query::Conditions::Operation.new(@slug, @comparison)) }

      it { is_expected.to be(false) }
    end

    describe 'when operations contain more than one operand' do
      before do
        @operation << DataMapper::Query::Conditions::Operation.new(:and, @comparison, @other)
        @other = @operation.dup
      end

      subject { @operation.eql?(@other) }

      it { is_expected.to be(true) }
    end
  end

  it { is_expected.to respond_to(:hash) }

  describe '#hash' do
    describe 'with operands' do
      before do
        @operation << @comparison
      end

      subject { @operation.hash }

      it 'matches the same AbstractOperation with the same operands' do
        is_expected.to eq DataMapper::Query::Conditions::Operation.new(@slug, @comparison.dup).hash
      end

      it 'does not match the same AbstractOperation with different operands' do
        is_expected.not_to eq DataMapper::Query::Conditions::Operation.new(@slug).hash
      end

      it 'does not match a different AbstractOperation with the same operands' do
        is_expected.not_to eq @other.class.new(@comparison.dup).hash
      end

      it 'does not match a different AbstractOperation with different operands' do
        is_expected.not_to eq DataMapper::Query::Conditions::Operation.new(:or).hash
      end
    end
  end

  [ :intersection, :& ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @operation.send(method, @other) }

      it { is_expected.to eql(@and_operation) }
    end
  end

  it { is_expected.to respond_to(:merge) }

  describe '#merge' do
    describe 'with a NullOperation' do
      subject { @operation.merge([ @null_operation ]) }

      it { is_expected.to equal(@operation) }

      it 'merges the operand' do
        expect(subject.to_a).to eq [ @null_operation.class.new ]
      end

      it { is_expected.to have_operands_with_valid_parent }
    end

    describe 'with a duplicate operand' do
      before { @operation << @comparison.dup }

      subject { @operation.merge([ @comparison.dup ]) }

      it { is_expected.to equal(@operation) }

      it 'has unique operands' do
        expect(subject.to_a).to eq [ @comparison ]
      end

      it { is_expected.to have_operands_with_valid_parent }
    end

    describe 'with an invalid operand' do
      subject { @operation.merge([ '' ]) }

      it { expect { method(:subject) }.to raise_error(ArgumentError)  }
    end
  end

  it { is_expected.to respond_to(:operands) }

  describe '#operands' do
    subject { @operation.operands }

    it { is_expected.to be_kind_of(Set) }

    it { is_expected.to be_empty }

    it { is_expected.to equal(@operation.children) }
  end

  it { is_expected.to respond_to(:parent) }

  describe '#parent' do
    describe 'when there is no parent' do
      subject { @operation.parent }

      it { is_expected.to be_nil }
    end

    describe 'when there is a parent' do
      before { @other << @operation }

      subject { @operation.parent }

      it { is_expected.to equal(@other) }
    end
  end

  it { is_expected.to respond_to(:parent=) }

  describe '#parent=' do
    subject { @operation.parent = @other }

    it { is_expected.to equal(@other) }

    it 'changes the parent' do
      expect { method(:subject) }
        .to change(@operation, :parent)
        .from(nil)
        .to(@other)
    end
  end

  [ :union, :|, :+ ].each do |method|
    it { is_expected.to respond_to(method) }

    describe "##{method}" do
      subject { @operation.send(method, @null_operation) }

      it { is_expected.to eql(@null_operation) }
    end
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    subject { @operation.valid? }

    describe 'with no operands' do
      it { is_expected.to be(false) }
    end

    describe 'with an operand that responds to #valid?' do
      describe 'and is valid' do
        before do
          @operation << @comparison
        end

        it { is_expected.to be(true) }
      end

      describe 'and is not valid' do
        before do
          @operation << @or_operation.dup
        end

        it { is_expected.to be(false) }
      end
    end

    describe 'with an operand that does not respond to #valid?' do
      before do
        @operation << [ 'raw = 1' ]
      end

      it { is_expected.to be(true) }
    end
  end
end

describe DataMapper::Query::Conditions::Operation do
  it { expect(DataMapper::Query::Conditions::Operation).to respond_to(:new) }

  describe '.new' do
    {
      :and  => DataMapper::Query::Conditions::AndOperation,
      :or   => DataMapper::Query::Conditions::OrOperation,
      :not  => DataMapper::Query::Conditions::NotOperation,
      :null => DataMapper::Query::Conditions::NullOperation,
    }.each do |slug, klass|
      describe "with a slug #{slug.inspect}" do
        subject { DataMapper::Query::Conditions::Operation.new(slug) }

        it { is_expected.to be_kind_of(klass) }

        it { expect(subject).to be_empty }
      end
    end

    describe 'with an invalid slug' do
      subject { DataMapper::Query::Conditions::Operation.new(:invalid) }

      it { expect { method(:subject) }.to raise_error(ArgumentError, 'No Operation class for :invalid has been defined') }
    end

    describe 'with operands' do
      before { @or_operation = DataMapper::Query::Conditions::Operation.new(:or) }

      subject { DataMapper::Query::Conditions::Operation.new(:and, @or_operation) }

      it { is_expected.to be_kind_of(DataMapper::Query::Conditions::AndOperation) }

      it 'sets the operands' do
        expect(subject.to_a).to eq [ @or_operation ]
      end
    end
  end
end

describe DataMapper::Query::Conditions::AndOperation do
  include OperationMatchers

  it_behaves_like 'DataMapper::Query::Conditions::AbstractOperation'

  before do
    @operation = @and_operation
    @slug      = @operation.slug
  end

  it { is_expected.to respond_to(:<<) }

  describe '#<<' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation << @other }

        it { is_expected.to equal(@operation) }

        if klass == DataMapper::Query::Conditions::AndOperation
          it 'flattens and merges the operand' do
            expect(subject.to_a).to eq @other.operands.to_a
          end
        else
          it 'merges the operand' do
            expect(subject.to_a).to eq [ @other ]
          end
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end
  end

  it { is_expected.to respond_to(:negated?) }

  describe '#negated?' do
    describe 'with a negated parent' do
      before do
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(true) }
    end

    describe 'with a not negated parent' do
      before do
        @or_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(false) }
    end

    describe 'after memoizing the negation, and switching parents' do
      before do
        @or_operation.class.new(@operation)
        expect(@operation).not_to be_negated
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(true) }
    end
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    before do
      @operation << @comparison << @comparison.class.new(@model.properties[:id], 1)
    end

    supported_by :all do
      describe 'with a matching Hash' do
        subject { @operation.matches?('title' => 'A title', 'id' => 1) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @operation.matches?('title' => 'Not matching', 'id' => 1) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @operation.matches?(@model.new(:title => 'A title', :id => 1)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @operation.matches?(@model.new(:title => 'Not matching', :id => 1)) }

        it { is_expected.to be(false) }
      end

      describe 'with a raw condition' do
        before do
          @operation = @operation.class.new([ 'title = ?', 'Another title' ])
        end

        subject { @operation.matches?('title' => 'A title', 'id' => 1) }

        it { is_expected.to be(true) }
      end
    end
  end

  it { is_expected.to respond_to(:minimize) }

  describe '#minimize' do
    subject { @operation.minimize }

    describe 'with one empty operand' do
      before do
        @operation << @other
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject).to be_empty }
    end

    describe 'with more than one operation' do
      before do
        @operation.merge([ @comparison, @not_operation.class.new(@comparison) ])
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject.to_a).to match [ @comparison, @not_operation.class.new(@comparison) ] }
    end

    describe 'with one non-empty operand' do
      before do
        @operation << @comparison
      end

      it { is_expected.to eq @comparison }
    end

    describe 'with one null operation' do
      before do
        @operation << @null_operation
      end

      it { is_expected.to eql(@null_operation) }
    end

    describe 'with one null operation and one non-null operation' do
      before do
        @operation.merge([ @null_operation, @comparison ])
      end

      it { is_expected.to eql(@comparison) }
    end
  end

  it { is_expected.to respond_to(:merge) }

  describe '#merge' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation.merge([ @other ]) }

        it { is_expected.to equal(@operation) }

        if klass == DataMapper::Query::Conditions::AndOperation
          it 'flattens and merges the operand' do
            expect(subject.to_a).to eq @other.operands.to_a
          end
        else
          it 'merges the operand' do
            expect(subject.to_a).to eq [ @other ]
          end
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    describe 'with no operands' do
      subject { @operation.to_s }

      it { is_expected.to eql('') }
    end

    describe 'with operands' do
      before do
        @not_operation << @comparison.dup
        @operation << @comparison << @not_operation
      end

      subject { @operation.to_s }

      it { is_expected.to eql('(NOT(title = "A title") AND title = "A title")') }
    end
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    describe 'with one valid operand, and one invalid operand' do
      before do
        @operation << @comparison
        @operation << DataMapper::Query::Conditions::Comparison.new(:in, @model.properties[:id], [])
      end

      subject { @operation.valid? }

      it { is_expected.to be(false) }
    end

    describe 'with one invalid operand' do
      before do
        @operation << DataMapper::Query::Conditions::Comparison.new(:in, @model.properties[:id], [])
      end

      subject { @operation.valid? }

      it { is_expected.to be(false) }
    end
  end
end

describe DataMapper::Query::Conditions::OrOperation do
  include OperationMatchers

  it_behaves_like 'DataMapper::Query::Conditions::AbstractOperation'

  before do
    @operation = @or_operation
    @slug      = @operation.slug
  end

  it { is_expected.to respond_to(:<<) }

  describe '#<<' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation << @other }

        it { is_expected.to equal(@operation) }

        if klass == DataMapper::Query::Conditions::OrOperation
          it 'flattens and merges the operand' do
            expect(subject.to_a).to eq @other.operands.to_a
          end
        else
          it 'merges the operand' do
            expect(subject.to_a).to eq [ @other ]
          end
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end
  end

  it { is_expected.to respond_to(:negated?) }

  describe '#negated?' do
    describe 'with a negated parent' do
      before do
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(true) }
    end

    describe 'with a not negated parent' do
      before do
        @and_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(false) }
    end

    describe 'after memoizing the negation, and switching parents' do
      before do
        @or_operation.class.new(@operation)
        expect(@operation).not_to be_negated
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(true) }
    end
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    before do
      @operation << @comparison << @comparison.class.new(@model.properties[:id], 1)
    end

    supported_by :all do
      describe 'with a matching Hash' do
        subject { @operation.matches?('title' => 'A title', 'id' => 2) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @operation.matches?('title' => 'Not matching', 'id' => 2) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @operation.matches?(@model.new(:title => 'A title', :id => 2)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @operation.matches?(@model.new(:title => 'Not matching', :id => 2)) }

        it { is_expected.to be(false) }
      end

      describe 'with a raw condition' do
        before do
          @operation = @operation.class.new([ 'title = ?', 'Another title' ])
        end

        subject { @operation.matches?('title' => 'A title', 'id' => 2) }

        it { is_expected.to be(true) }
      end
    end
  end

  it { is_expected.to respond_to(:minimize) }

  describe '#minimize' do
    subject { @operation.minimize }

    describe 'with one empty operand' do
      before do
        @operation << @other
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject).to be_empty }
    end

    describe 'with more than one operation' do
      before do
        @operation.merge([ @comparison, @not_operation.class.new(@comparison) ])
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject.to_a).to match [ @comparison, @not_operation.class.new(@comparison) ] }
    end

    describe 'with one non-empty operand' do
      before do
        @operation << @comparison
      end

      it { is_expected.to eq @comparison }
    end

    describe 'with one null operation' do
      before do
        @operation << @null_operation
      end

      it { is_expected.to eql(@null_operation) }
    end
  end

  it { is_expected.to respond_to(:merge) }

  describe '#merge' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation.merge([ @other ]) }

        it { is_expected.to equal(@operation) }

        if klass == DataMapper::Query::Conditions::OrOperation
          it 'flattens and merges the operand' do
            expect(subject.to_a).to eq @other.operands.to_a
          end
        else
          it 'merges the operand' do
            expect(subject.to_a).to eq [ @other ]
          end
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    describe 'with one valid operand, and one invalid operand' do
      before do
        @operation << @comparison
        @operation << DataMapper::Query::Conditions::Comparison.new(:in, @model.properties[:id], [])
      end

      subject { @operation.valid? }

      it { is_expected.to be(true) }
    end

    describe 'with one invalid operand' do
      before do
        @operation << DataMapper::Query::Conditions::Comparison.new(:in, @model.properties[:id], [])
      end

      subject { @operation.valid? }

      it { is_expected.to be(false) }
    end
  end
end

describe DataMapper::Query::Conditions::NotOperation do
  include OperationMatchers

  it_behaves_like 'DataMapper::Query::Conditions::AbstractOperation'

  before do
    @operation = @not_operation
    @slug      = @operation.slug
  end

  it { is_expected.to respond_to(:<<) }

  describe '#<<' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation << @other }

        it { is_expected.to equal(@operation) }

        it 'merges the operand' do
          expect(subject.to_a).to eq [ @other ]
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end

    describe 'with more than one operand' do
      subject { @operation << @comparison << @other }

      it { expect { method(:subject) }.to raise_error(ArgumentError)  }
    end

    describe 'with self as an operand' do
      subject { @operation << @operation }

      it { expect { method(:subject) }.to raise_error(ArgumentError, 'cannot append operand to itself')  }
    end
  end

  it { is_expected.to respond_to(:negated?) }

  describe '#negated?' do
    describe 'with a negated parent' do
      before do
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(false) }
    end

    describe 'with a not negated parent' do
      before do
        @or_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(true) }
    end

    describe 'after memoizing the negation, and switching parents' do
      before do
        @or_operation.class.new(@operation)
        expect(@operation).to be_negated
        @not_operation.class.new(@operation)
      end

      subject { @operation.negated? }

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    before do
      @operation << @comparison.class.new(@model.properties[:id], 1)
    end

    supported_by :all do
      describe 'with a matching Hash' do
        subject { @operation.matches?('id' => 2) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @operation.matches?('id' => 1) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @operation.matches?(@model.new(:id => 2)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @operation.matches?(@model.new(:id => 1)) }

        it { is_expected.to be(false) }
      end

      describe 'with a raw condition' do
        before do
          @operation = @operation.class.new([ 'title = ?', 'Another title' ])
        end

        subject { @operation.matches?('id' => 2) }

        it { is_expected.to be(true) }
      end
    end
  end

  it { is_expected.to respond_to(:merge) }

  describe '#merge' do
    [
      DataMapper::Query::Conditions::AndOperation,
      DataMapper::Query::Conditions::OrOperation,
      DataMapper::Query::Conditions::NotOperation,
    ].each do |klass|
      describe "with an #{klass.name.split('::').last}" do
        before do
          @other = klass.new(@comparison)
        end

        subject { @operation.merge([ @other ]) }

        it { is_expected.to equal(@operation) }

        it 'merges the operand' do
          expect(subject.to_a).to eq [ @other ]
        end

        it { is_expected.to have_operands_with_valid_parent }
      end
    end

    describe 'with more than one operand' do
      subject { @operation.merge([ @comparison, @other ]) }

      it { expect{ method(:subject) }.to raise_error(ArgumentError)  }
    end
  end

  it { is_expected.to respond_to(:minimize) }

  describe '#minimize' do
    subject { @operation.minimize }

    describe 'when no operand' do
      it { is_expected.to equal(@operation) }
    end

    describe 'when operand is a NotOperation' do
      before do
        @operation << @not_operation.class.new(@comparison)
      end

      it 'removes the double negative' do
        is_expected.to eql(@comparison)
      end
    end

    describe 'when operand is not a NotOperation' do
      before do
        @operation << @comparison
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject.to_a).to eq [ @comparison ] }
    end

    describe 'when operand is an empty operation' do
      before do
        @operation << @and_operation
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject).to be_empty }
    end

    describe 'when operand is an operation containing a Comparison' do
      before do
        @operation << @and_operation.class.new(@comparison)
      end

      it { is_expected.to equal(@operation) }

      it { expect(subject.to_a).to eq [ @comparison ] }
    end
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    describe 'with no operands' do
      subject { @operation.to_s }

      it { is_expected.to eql('') }
    end

    describe 'with operands' do
      before do
        @operation << @comparison
      end

      subject { @operation.to_s }

      it { is_expected.to eql('NOT(title = "A title")') }
    end
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    describe 'with one invalid operand' do
      before do
        @operation << @not_operation.class.new(
          DataMapper::Query::Conditions::Comparison.new(:eql, @model.properties[:id], nil)
        )
      end

      subject { @operation.valid? }

      it { is_expected.to be(false) }
    end
  end
end

describe DataMapper::Query::Conditions::NullOperation do
  include OperationMatchers

  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,    Serial
        property :title, String, :required => true
      end
    end

    @model = Blog::Article
  end

  before do
    @null_operation = DataMapper::Query::Conditions::Operation.new(:null)
    @operation      = @null_operation
    @slug           = @operation.slug
  end

  it { is_expected.to respond_to(:slug) }

  describe '#slug' do
    subject { @operation.slug }

    it { is_expected.to eq :null }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    describe 'with a Hash' do
      subject { @operation.matches?({}) }

      it { is_expected.to be(true) }
    end

    describe 'with a Resource' do
      subject { @operation.matches?(Blog::Article.new) }

      it { is_expected.to be(true) }
    end

    describe 'with any other Object' do
      subject { @operation.matches?(Object.new) }

      it { is_expected.to be(false) }
    end
  end

  it { is_expected.to respond_to(:minimize) }

  describe '#minimize' do
    subject { @operation.minimize }

    it { is_expected.to equal(@operation) }
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    subject { @operation.valid? }

    it { is_expected.to be(true) }
  end

  it { is_expected.to respond_to(:nil?) }

  describe '#nil?' do
    subject { @operation.nil? }

    it { is_expected.to be(true) }
  end

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @operation.inspect }

    it { is_expected.to eq 'nil' }
  end
end
