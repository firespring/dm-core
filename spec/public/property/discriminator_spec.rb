require_relative '../../spec_helper'

describe DataMapper::Property::Discriminator do
  before :all do
    module ::Blog
      class Content
        include DataMapper::Resource

        property :id,    Serial
        property :title, String, :required => true
        property :type,  Discriminator
      end

      class Article < Content; end
      class Announcement < Article; end
      class Release < Announcement; end
    end
    DataMapper.finalize

    @content_model      = Blog::Content
    @article_model      = Blog::Article
    @announcement_model = Blog::Announcement
    @release_model      = Blog::Release
  end

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }
    it { is_expected.to include(load_as: Class, required: true) }
  end

  it 'typecasts to a Model' do
    expect(@article_model.properties[:type].typecast('Blog::Release')).to equal(@release_model)
  end

  describe 'Model#new' do
    describe 'when provided a String discriminator in the attributes' do
      before :all do
        @resource = @article_model.new(:type => 'Blog::Release')
      end

      it 'returns a Resource' do
        expect(@resource).to be_kind_of(DataMapper::Resource)
      end

      it 'is an descendant instance' do
        expect(@resource).to be_instance_of(Blog::Release)
      end
    end

    describe 'when provided a Class discriminator in the attributes' do
      before :all do
        @resource = @article_model.new(:type => Blog::Release)
      end

      it 'returns a Resource' do
        expect(@resource).to be_kind_of(DataMapper::Resource)
      end

      it 'is an descendant instance' do
        expect(@resource).to be_instance_of(Blog::Release)
      end
    end

    describe 'when not provided a discriminator in the attributes' do
      before :all do
        @resource = @article_model.new
      end

      it 'returns a Resource' do
        expect(@resource).to be_kind_of(DataMapper::Resource)
      end

      it 'is a base model instance' do
        expect(@resource).to be_instance_of(@article_model)
      end
    end
  end

  describe 'Model#descendants' do
    it 'sets the descendants for the grandparent model' do
      expect(@article_model.descendants.to_a).to match([@announcement_model, @release_model])
    end

    it 'sets the descendants for the parent model' do
      expect(@announcement_model.descendants.to_a).to eq [@release_model]
    end

    it 'sets the descendants for the child model' do
      expect(@release_model.descendants.to_a).to eq []
    end
  end

  describe 'Model#default_scope' do
    it 'has no default scope for the top level model' do
      expect(@content_model.default_scope[:type]).to be_nil
    end

    it 'sets the default scope for the grandparent model' do
      expect(@article_model.default_scope[:type].to_a).to match([@article_model, @announcement_model, @release_model])
    end

    it 'sets the default scope for the parent model' do
      expect(@announcement_model.default_scope[:type].to_a).to match([@announcement_model, @release_model])
    end

    it 'sets the default scope for the child model' do
      expect(@release_model.default_scope[:type].to_a).to eq [@release_model]
    end
  end

  supported_by :all do
    before :all do
      @announcement = @announcement_model.create(:title => 'Announcement')
    end

    it 'persists the type' do
      expect(@announcement.model.get!(*@announcement.key).type).to equal(@announcement_model)
    end

    it 'is retrieved as an instance of the correct class' do
      expect(@announcement.model.get!(*@announcement.key)).to be_instance_of(@announcement_model)
    end

    it 'includes descendants in finders' do
      expect(@article_model.first).to eql(@announcement)
    end

    it 'does not include ancestors' do
      expect(@release_model.first).to be_nil
    end
  end
end
