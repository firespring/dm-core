require_relative '../spec_helper'

# TODO: move these specs into shared specs for #copy
describe DataMapper::Model do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,       Serial
        property :title,    String, :required => true
        property :content,  Text,                       :writer => :private, :default => lambda { |resource, property| resource.title }
        property :subtitle, String
        property :author,   String, :required => true

        belongs_to :original, self, :required => false
        has n, :revisions, self, :child_key => [ :original_id ]
        has 1, :previous,  self, :child_key => [ :original_id ], :order => [ :id.desc ]
      end
    end
    DataMapper.finalize

    @article_model = Blog::Article
  end

  supported_by :all do
    before :all do
      @author = 'Dan Kubb'

      @original = @article_model.create(:title => 'Original Article',                         :author => @author)
      @article  = @article_model.create(:title => 'Sample Article',   :original => @original, :author => @author)
      @other    = @article_model.create(:title => 'Other Article',                            :author => @author)
    end

    it { expect(@article_model).to respond_to(:copy) }

    describe '#copy' do
      with_alternate_adapter do
        before :all do
          if @article_model.respond_to?(:auto_migrate!)
            # force the article model to be available in the alternate repository
            @article_model.auto_migrate!(@adapter.name)
          end
        end

        describe 'between identical models' do
          before :all do
            @return = @resources = @article_model.copy(@repository.name, @adapter.name)
          end

          it 'returns a Collection' do
            expect(@return).to be_a_kind_of(DataMapper::Collection)
          end

          it 'returns Resources' do
            @return.each { |resource| expect(resource).to be_a_kind_of(DataMapper::Resource) }
          end

          it 'has each Resource set to the expected Repository' do
            @resources.each { |resource| expect(resource.repository.name).to eq @adapter.name }
          end

          it 'creates the Resources in the expected Repository' do
            expect(@article_model.all(repository: DataMapper.repository(@adapter.name))).to eq @resources
          end
        end

        describe 'between different models' do
          before :all do
            @other.destroy
            @article.destroy
            @original.destroy

            # make sure the default repository is empty
            expect(@article_model.all(repository: @repository)).to be_empty

            # add an extra property to the alternate model
            DataMapper.repository(@adapter.name) do
              @article_model.property :status, String, :default => 'new'
            end

            if @article_model.respond_to?(:auto_migrate!)
              @article_model.auto_migrate!(@adapter.name)
            end

            # add new resources to the alternate repository
            DataMapper.repository(@adapter.name) do
              # use an id value that is unique
              @heff1 = @article_model.create(:id => 99, :title => 'Alternate Repository', :author => @author)
            end

            # copy from the alternate to the default repository
            @return = @resources = @article_model.copy(@adapter.name, :default)
          end

          it 'returns a Collection' do
            expect(@return).to be_a_kind_of(DataMapper::Collection)
          end

          it 'returns Resources' do
            @return.each { |resource| expect(resource).to be_a_kind_of(DataMapper::Resource) }
          end

          it 'has each Resource set to the expected Repository' do
            @resources.each { |resource| expect(resource.repository.name).to eq :default }
          end

          it 'returns the expected resources' do
            # match on id because resources from different repositories are different
            expect(@resources.map { |resource| resource.id }).to eq [@heff1.id]
          end

          it 'adds the resources to the alternate repository' do
            expect(@article.model.get!(*@heff1.key)).not_to be_nil
          end
        end
      end
    end
  end
end

describe DataMapper::Model do
  extend DataMapper::Spec::CollectionHelpers::GroupMethods

  self.loaded = false

  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,       Serial
        property :title,    String, :required => true, :default => 'Default Title'
        property :content,  Text
        property :subtitle, String

        belongs_to :original, self, :required => false
        has n, :revisions, self, :child_key => [ :original_id ]
        has 1, :previous,  self, :child_key => [ :original_id ], :order => [ :id.desc ]
        has n, :publications, :through => Resource
      end

      class Publication
        include DataMapper::Resource

        property :id,   Serial
        property :name, String

        has n, :articles, :through => Resource
      end
    end
    DataMapper.finalize

    @article_model     = Blog::Article
    @publication_model = Blog::Publication
  end

  supported_by :all do
    # model cannot be a kicker
    def should_not_be_a_kicker; end

    def model?; true end

    before :all do
      @articles = @article_model

      @original = @articles.create(:title => 'Original Article')
      @article  = @articles.create(:title => 'Sample Article', :content => 'Sample', :original => @original)
      @other    = @articles.create(:title => 'Other Article',  :content => 'Other')
    end

    describe '#new' do
      subject { model.new(*args) }

      let(:model) { @article_model }

      context 'with no arguments' do
        let(:args) { [] }

        it { is_expected.to be_instance_of(model) }

        its(:attributes) { is_expected.to eq({title: 'Default Title'}) }
      end

      context 'with an empty Hash' do
        let(:args) { [ {} ] }

        it { is_expected.to be_instance_of(model) }
        its(:attributes) { is_expected.to eq({title: 'Default Title'}) }
      end

      context 'with a non-empty Hash' do
        let(:attributes) { { :title => 'A Title' } }
        let(:args)       { [ attributes ]          }

        it { is_expected.to be_instance_of(model) }

        its(:attributes) { is_expected.to eq attributes }
      end

      context 'with nil' do
        let(:args) { [nil] }

        it { is_expected.to be_instance_of(model) }
        its(:attributes) { is_expected.to eq({title: 'Default Title'}) }
      end
    end

    [ :create, :create! ].each do |method|
      describe "##{method}" do
        subject { model.send(method, *args) }

        let(:model) { @article_model }

        context 'with no arguments' do
          let(:args) { [] }

          it { is_expected.to be_instance_of(model) }

          it { is_expected.to be_saved }
        end

        context 'with an empty Hash' do
          let(:args) { [ {} ] }


          it { is_expected.to be_instance_of(model) }
          it { is_expected.to be_saved }
        end

        context 'with a non-empty Hash' do
          let(:attributes) { { :title => 'A Title' } }
          let(:args)       { [ attributes ]          }

          it { is_expected.to be_instance_of(model) }
          it { is_expected.to be_saved }
          its(:title) { is_expected.to eq attributes[:title] }
        end

        context 'with nil' do
          let(:args) { [ nil ] }


          it { is_expected.to be_instance_of(model) }
          it { is_expected.to be_saved }
        end
      end
    end

    [ :destroy, :destroy! ].each do |method|
      describe "##{method}" do
        subject { model.send(method) }

        let(:model) { @article_model }

        it 'removes all resources' do
          expect(method(:subject)).to change { model.any? }.from(true).to(false)
        end
      end
    end

    [ :update, :update! ].each do |method|
      describe "##{method}" do
        subject { model.send(method, *args) }

        let(:model) { @article_model }

        context 'with attributes' do
          let(:attributes) { { :title => 'Updated Title' } }
          let(:args)       { [ attributes ]                }

          it { is_expected.to be(true) }

          it 'persists the changes' do
            subject
            expect(model.all(fields: [:title]).map { |resource| resource.title }.uniq).to eq [attributes[:title]]
          end
        end

        context 'with attributes where one is a parent association' do
          let(:attributes) { { :original => @other } }
          let(:args)       { [ attributes ]          }

          it { is_expected.to be(true) }

          it 'persists the changes' do
            subject
            expect(model.all(fields: [:original_id]).map { |resource| resource.original }.uniq).to eq [attributes[:original]]
          end
        end

        context 'with attributes where a required property is nil' do
          let(:attributes) { { :title => nil } }
          let(:args)       { [ attributes ]    }

          it 'raises InvalidValueError' do
            expect { subject }.to(raise_error(DataMapper::Property::InvalidValueError) do |error|
              expect(error.property).to eq model.title
            end)
          end
        end
      end
    end

    it_behaves_like 'Finder Interface'

    it 'DataMapper::Model responds to raise_on_save_failure' do
      expect(DataMapper::Model).to respond_to(:raise_on_save_failure)
    end

    describe '.raise_on_save_failure' do
      subject { DataMapper::Model.raise_on_save_failure }

      it { is_expected.to be(false) }
    end

    it 'DataMapper::Model responds to raise_on_save_failure=' do
      expect(DataMapper::Model).to respond_to(:raise_on_save_failure=)
    end

    describe '.raise_on_save_failure=' do
      after do
        # reset to the default value
        reset_raise_on_save_failure(DataMapper::Model)
      end

      subject { DataMapper::Model.raise_on_save_failure = @value }

      describe 'with a true value' do
        before do
          @value = true
        end

        it { is_expected.to be(true) }

        it 'sets raise_on_save_failure' do
          expect(method(:subject)).to change {
            DataMapper::Model.raise_on_save_failure
          }.from(false).to(true)
        end
      end

      describe 'with a false value' do
        before do
          @value = false
        end

        it { is_expected.to be(false) }

        it 'sets raise_on_save_failure' do
          expect(method(:subject)).not_to change {
            DataMapper::Model.raise_on_save_failure
          }
        end
      end
    end

    it 'A model responds to raise_on_save_failure' do
      expect(@article_model).to respond_to(:raise_on_save_failure)
    end

    describe '#raise_on_save_failure' do
      after do
        # reset to the default value
        reset_raise_on_save_failure(DataMapper::Model)
        reset_raise_on_save_failure(@article_model)
      end

      subject { @article_model.raise_on_save_failure }

      describe 'when DataMapper::Model.raise_on_save_failure has not been set' do
        it { is_expected.to be(false) }
      end

      describe 'when DataMapper::Model.raise_on_save_failure has been set to true' do
        before do
          DataMapper::Model.raise_on_save_failure = true
        end

        it { is_expected.to be(true) }
      end

      describe 'when model.raise_on_save_failure has been set to true' do
        before do
          @article_model.raise_on_save_failure = true
        end

        it { is_expected.to be(true) }
      end
    end

    it 'A model responds to raise_on_save_failure=' do
      expect(@article_model).to respond_to(:raise_on_save_failure=)
    end

    describe '#raise_on_save_failure=' do
      after do
        # reset to the default value
        reset_raise_on_save_failure(@article_model)
      end

      subject { @article_model.raise_on_save_failure = @value }

      describe 'with a true value' do
        before do
          @value = true
        end

        it { is_expected.to be(true) }

        it 'sets raise_on_save_failure' do
          expect(method(:subject)).to change {
            @article_model.raise_on_save_failure
          }.from(false).to(true)
        end
      end

      describe 'with a false value' do
        before do
          @value = false
        end

        it { is_expected.to be(false) }

        it 'sets raise_on_save_failure' do
          expect(method(:subject)).not_to change {
            @article_model.raise_on_save_failure
          }
        end
      end
    end

    it 'A model responds to allowed_writer_methods' do
      expect(@article_model).to respond_to(:allowed_writer_methods)
    end

    describe '#allowed_writer_methods' do
      subject { @article_model.allowed_writer_methods }

      let(:expected_writer_methods) do
        %w[ original= revisions= previous= publications= article_publications=
            id= title= content= subtitle= original_id= persisted_state= ].to_set
      end

      it { is_expected.to be_kind_of(Set) }
      it { is_expected.to be_all { |method| method.is_a?(String) } }
      it { is_expected.to be_frozen }

      it 'is idempotent' do
        is_expected.to equal(instance_eval(&self.class.subject))
      end

      it { is_expected.to eql(expected_writer_methods) }
    end
  end
end
