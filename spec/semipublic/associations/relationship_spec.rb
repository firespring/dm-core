require_relative '../../spec_helper'

describe DataMapper::Associations::Relationship do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :title, String, :key => true
      end

      class Comment
        include DataMapper::Resource

        property :id,   Serial
        property :body, Text
      end
    end

    @article_model = Blog::Article
    @comment_model = Blog::Comment
  end

  def n
    1.0/0
  end

  describe '#inverse' do
    describe 'with matching relationships' do
      before :all do
        @comments_relationship = @article_model.has(n, :comments)
        @article_relationship  = @comment_model.belongs_to(:article)

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@comments_relationship.child_repository_name).to be_nil
        expect(@comments_relationship.parent_repository_name).to eq :default

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@article_relationship.child_repository_name).to eq :default
        expect(@article_relationship.parent_repository_name).to be_nil
        DataMapper.finalize
      end

      it 'returns the inverted relationships' do
        expect(@comments_relationship.inverse).to equal(@article_relationship)
        expect(@article_relationship.inverse).to equal(@comments_relationship)
      end
    end

    describe 'with matching relationships where the child repository is not nil' do
      before :all do
        @comments_relationship = @article_model.has(n, :comments, :repository => :default)
        @article_relationship  = @comment_model.belongs_to(:article)

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@comments_relationship.child_repository_name).to eq :default
        expect(@comments_relationship.parent_repository_name).to eq :default

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@article_relationship.child_repository_name).to eq :default
        expect(@article_relationship.parent_repository_name).to be_nil
        DataMapper.finalize
      end

      it 'returns the inverted relationships' do
        expect(@comments_relationship.inverse).to equal(@article_relationship)
        expect(@article_relationship.inverse).to equal(@comments_relationship)
      end
    end

    describe 'with matching relationships where the parent repository is not nil' do
      before :all do
        @comments_relationship = @article_model.has(n, :comments)
        @article_relationship  = @comment_model.belongs_to(:article, :repository => :default)

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@comments_relationship.child_repository_name).to be_nil
        expect(@comments_relationship.parent_repository_name).to eq :default

        # TODO: move this to spec/public/model/relationship_spec.rb
        expect(@article_relationship.child_repository_name).to eq :default
        expect(@article_relationship.parent_repository_name).to eq :default
        DataMapper.finalize
      end

      it 'returns the inverted relationships' do
        expect(@comments_relationship.inverse).to equal(@article_relationship)
        expect(@article_relationship.inverse).to equal(@comments_relationship)
      end
    end

    describe 'with no matching relationship', 'from the parent side' do
      before :all do
        # added to force OneToMany::Relationship#inverse to consider the
        # child_key differences
        @comment_model.belongs_to(:other_article, @article_model, :child_key => [ :other_article_id ])

        @relationship = @article_model.has(n, :comments)

        @inverse = @relationship.inverse

        # after Relationship#inverse to ensure no match
        @expected = @comment_model.belongs_to(:article)
        DataMapper.finalize
      end

      it 'returns a Relationship' do
        expect(@inverse).to be_kind_of(DataMapper::Associations::Relationship)
      end

      it 'returns an inverted relationship' do
        expect(@inverse).to eq @expected
      end

      it 'is an anonymous relationship' do
        expect(@inverse).not_to equal(@expected)
      end

      it 'has a source repository equal to the target repository of the relationship' do
        expect(@inverse.source_repository_name).to eq @relationship.target_repository_name
      end

      it "has the relationship as it's inverse" do
        expect(@inverse.inverse).to equal(@relationship)
      end
    end

    describe 'with no matching relationship', 'from the child side' do
      before :all do
        @relationship = @comment_model.belongs_to(:article)

        @inverse = @relationship.inverse

        # after Relationship#inverse to ensure no match
        @expected = @article_model.has(n, :comments)
        DataMapper.finalize
      end

      it 'returns a Relationship' do
        expect(@inverse).to be_kind_of(DataMapper::Associations::Relationship)
      end

      it 'returns an inverted relationship' do
        expect(@inverse).to eq @expected
      end

      it 'is an anonymous relationship' do
        expect(@inverse).not_to equal(@expected)
      end

      it 'has a source repository equal to the target repository of the relationship' do
        expect(@inverse.source_repository_name).to eq @relationship.target_repository_name
      end

      it "has the relationship as it's inverse" do
        expect(@inverse.inverse).to equal(@relationship)
      end
    end
  end

  describe '#valid?' do
    before :all do
      @relationship = @article_model.has(n, :comments)
      DataMapper.finalize
    end

    supported_by :all do
      describe 'with valid resource' do
        before :all do
          @article  = @article_model.create(:title => 'Relationships in DataMapper')
          @resource = @article.comments.create
        end

        it 'returns true' do
          expect(@relationship.valid?(@resource)).to be(true)
        end
      end

      describe 'with a resource of the wrong class' do
        before :all do
          @resource  = @article_model.new
        end

        it 'returns false' do
          expect(@relationship.valid?(@resource)).to be(false)
        end
      end

      describe 'with a resource without a valid parent' do
        before :all do
          @resource = @comment_model.new
        end

        it 'returns false' do
          expect(@relationship.valid?(@resource)).to be(false)
        end
      end
    end
  end
end
