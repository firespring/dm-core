require_relative '../../../spec_helper'

describe DataMapper::Query::Conditions::Comparison do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,    Serial
        property :title, String, required: true
      end
    end
    DataMapper.finalize

    @model = Blog::Article
  end

  before :all do
    @property = @model.properties[:id]
  end

  it { expect(DataMapper::Query::Conditions::Comparison).to respond_to(:new) }

  describe '.new' do
    {
      eql: DataMapper::Query::Conditions::EqualToComparison,
      in: DataMapper::Query::Conditions::InclusionComparison,
      regexp: DataMapper::Query::Conditions::RegexpComparison,
      like: DataMapper::Query::Conditions::LikeComparison,
      gt: DataMapper::Query::Conditions::GreaterThanComparison,
      lt: DataMapper::Query::Conditions::LessThanComparison,
      gte: DataMapper::Query::Conditions::GreaterThanOrEqualToComparison,
      lte: DataMapper::Query::Conditions::LessThanOrEqualToComparison,
    }.each do |slug, klass|
      describe "with a slug #{slug.inspect}" do
        subject { DataMapper::Query::Conditions::Comparison.new(slug, @property, @value) }

        it { is_expected.to be_kind_of(klass) }
      end
    end

    describe 'with an invalid slug' do
      subject { DataMapper::Query::Conditions::Comparison.new(:invalid, @property, @value) }

      it { expect { method(:subject) }.to raise_error(ArgumentError, 'No Comparison class for :invalid has been defined') }
    end
  end
end

describe DataMapper::Query::Conditions::EqualToComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = 1
    @other_value    = 2
    @slug           = :eql
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:foreign_key_mapping) }

  describe '#foreign_key_mapping' do
    supported_by :all do
      before do
        @parent = @model.create(title: 'Parent')
        @child  = @parent.children.create(title: 'Child')

        @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent)
      end

      it 'returns criteria that matches the record' do
        expect(@model.all(conditions: @comparison.foreign_key_mapping)).to eq [ @child ]
      end
    end
  end

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::EqualToComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=1 @loaded_value=1>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a Property subject' do
        describe 'with an Integer value' do
          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 2) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 2)) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a nil value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => nil) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => nil)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(false) }
          end
        end
      end

      describe 'with a Relationship subject' do
        describe 'with a nil value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, nil)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => nil }) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => {} }) }

            it { pending { is_expected.to be(false) } }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a Hash value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent.attributes.except(:id))
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { pending { is_expected.to be(false) } }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { pending { is_expected.to be(false) } }
          end
        end

        describe 'with new Resource value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            new_resource = @model.new(@parent.attributes.except(:id))

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, new_resource)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { pending { is_expected.to be(false) } }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { pending { is_expected.to be(false) } }
          end
        end

        describe 'with a saved Resource value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id = 1' }
  end

  it { is_expected.to respond_to(:value) }

  describe '#value' do
    supported_by :all do
      subject { @comparison.value }

      describe 'with a Property subject' do
        describe 'with an Integer value' do
          it { is_expected.to eq @value }
        end

        describe 'with a nil value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'with a Relationship subject' do
        before :all do
          @parent = @model.create(title: 'Parent')
          @child  = @parent.children.create(title: 'Child')
        end

        describe 'with an Hash value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, id: 1)
          end

          it { is_expected.to eq @model.new(id: 1) }
        end

        describe 'with a Resource value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent)
          end

          it { is_expected.to eq @parent }
        end
      end
    end
  end
end

describe DataMapper::Query::Conditions::InclusionComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = [ 1 ]
    @other_value    = [ 2 ]
    @slug           = :in
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:foreign_key_mapping) }

  describe '#foreign_key_mapping' do
    supported_by :all do
      before do
        @parent = @model.create(title: 'Parent')
        @child  = @parent.children.create(title: 'Child')

        @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @model.all)
      end

      it 'returns criteria that matches the record' do
        expect(@model.all(conditions: @comparison.foreign_key_mapping)).to eq [ @child ]
      end
    end
  end

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::InclusionComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=[1] @loaded_value=[1]>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a Property subject' do
        describe 'with an Array value' do
          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 2) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 2)) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with an Array value that needs typecasting' do
          before do
            @value      = [ '1' ]
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 2) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 2)) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a Range value' do
          before do
            @value      = 1..2
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 0) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 0)) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a Range value that needs typecasting' do
          before do
            @value      = '1'...'2'
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?(@property.field => 1) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?(@property.field => 2) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 1)) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@model.new(@property => 2)) }

            it { is_expected.to be(false) }
          end
        end
      end

      describe 'with a Relationship subject' do
        describe 'with a Hash value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent.attributes.except(:id))
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a new Resource value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            new_resource = @model.new(@parent.attributes.except(:id))

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, new_resource)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { pending { is_expected.to be(false) } }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { pending { is_expected.to be(false) } }
          end
        end

        describe 'with a saved Resource value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent)
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with a Collection value' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @model.all(title: 'Parent'))
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with an Enumerable value containing a Hash' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, [ @parent.attributes.except(:id), { title: 'Other' } ])
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end

        describe 'with an Enumerable value containing a new Resource' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            new_resource = @model.new(@parent.attributes.except(:id))

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, [ new_resource ])
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { pending { is_expected.to be(false) } }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { pending { is_expected.to be(false) } }
          end
        end

        describe 'with an Enumerable value containing a saved Resource' do
          before do
            @parent = @model.create(title: 'Parent')
            @child  = @parent.children.create(title: 'Child')

            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, [ @parent ])
          end

          describe 'with a matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @parent.attributes(:field) }) }

            it { pending { is_expected.to be(true) } }
          end

          describe 'with a not matching Hash' do
            subject { @comparison.matches?({ @relationship.field => @child.attributes(:field) }) }

            it { is_expected.to be(false) }
          end

          describe 'with a matching Resource' do
            subject { @comparison.matches?(@child) }

            it { is_expected.to be(true) }
          end

          describe 'with a not matching Resource' do
            subject { @comparison.matches?(@parent) }

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id IN [1]' }
  end

  it { is_expected.to respond_to(:valid?) }

  describe '#valid?' do
    subject { @comparison.valid? }

    describe 'with a Property subject' do
      describe 'with a valid Array value' do
        it { is_expected.to be(true) }
      end

      describe 'with a valid Array value that needs typecasting' do
        before do
          @value      = [ '1' ]
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(true) }
      end

      describe 'with an invalid Array value' do
        before do
          @value      = [ 'invalid' ]
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(false) }
      end

      describe 'with an empty Array value' do
        before do
          @value      = []
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(false) }
      end

      describe 'with a valid Range value' do
        before do
          @value      = 1..1
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(true) }
      end

      describe 'with a valid Range value that needs typecasting' do
        before do
          @value      = '1'...'2'
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(true) }
      end

      describe 'with an invalid Range value' do
        before do
          @value      = 'a'..'z'
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(false) }
      end

      describe 'with an empty Range value' do
        before do
          @value      = 1..0
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
        end

        it { is_expected.to be(false) }
      end
    end

    describe 'with a Relationship subject' do
      supported_by :all do
        describe 'with a valid Array value' do
          before do
            @value      = [ @model.new(id: 1) ]
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it { is_expected.to be(true) }
        end

        describe 'with an invalid Array value' do
          before do
            @value      = [ @model.new ]
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it { is_expected.to be(false) }
        end

        describe 'with an empty Array value' do
          before do
            @value      = []
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it { is_expected.to be(false) }
        end

        describe 'with a valid Collection' do
          before do
            @value      = @model.all
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it { is_expected.to be(true) }
        end
      end
    end
  end

  it { is_expected.to respond_to(:value) }

  describe '#value' do
    supported_by :all do
      subject { @comparison.value }

      describe 'with a Property subject' do
        describe 'with an Array value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, [ 1, 1 ])
          end

          it { is_expected.to be_kind_of(Array) }

          it { is_expected.to eq @value }
        end

        describe 'with a Range value' do
          before do
            @value      = 1..1
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
          end

          it { is_expected.to be_kind_of(Range) }

          it { is_expected.to eq @value }
        end
      end

      describe 'with a Relationship subject' do
        before :all do
          @parent = @model.create(title: 'Parent')
          @child  = @parent.children.create(title: 'Child')
        end

        describe 'with an Hash value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, id: @parent.id)
          end

          it { is_expected.to be_kind_of(DataMapper::Collection) }

          it { is_expected.to eq [ @parent ] }
        end

        describe 'with an Array value' do
          before do
            @value      = [ @parent ]
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it { is_expected.to be_kind_of(DataMapper::Collection) }

          it { is_expected.to eq @value }
        end

        describe 'with a Resource value' do
          before do
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @parent)
          end

          it { is_expected.to be_kind_of(DataMapper::Collection) }

          it { is_expected.to eq [ @parent ] }
        end

        describe 'with a Collection value' do
          before do
            @value      = @model.all
            @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @relationship, @value)
          end

          it 'is not a kicker' do
            expect(@value).not_to be_loaded
          end

          it { is_expected.to be_kind_of(DataMapper::Collection) }

          it { is_expected.to eq @value }
        end
      end
    end
  end
end

describe DataMapper::Query::Conditions::RegexpComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:title]
    @other_property = @model.properties[:id]
    @value       = /Title/
    @other_value = /Other Title/
    @slug        = :regexp
    @comparison  = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other       = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::RegexpComparison @subject=#<DataMapper::Property::String @model=Blog::Article @name=:title> @dumped_value=/Title/ @loaded_value=/Title/>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 'Title') }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 'Other') }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 'Title')) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 'Other')) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'title =~ /Title/' }
  end
end

describe DataMapper::Query::Conditions::LikeComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:title]
    @other_property = @model.properties[:id]
    @value          = '_it%'
    @other_value    = 'Other Title'
    @slug           = :like
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::LikeComparison @subject=#<DataMapper::Property::String @model=Blog::Article @name=:title> @dumped_value="_it%" @loaded_value="_it%">' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 'Title') }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 'Other Title') }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 'Title')) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 'Other Title')) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'title LIKE "_it%"' }
  end
end

describe DataMapper::Query::Conditions::GreaterThanComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = 1
    @other_value    = 2
    @slug           = :gt
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::GreaterThanComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=1 @loaded_value=1>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 2) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 1) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 2)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end

      describe 'with an expected value of nil' do
        subject { @comparison.matches?(@model.new(@property => 2)) }

        before do
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id > 1' }
  end
end

describe DataMapper::Query::Conditions::LessThanComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = 1
    @other_value    = 2
    @slug           = :lt
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::LessThanComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=1 @loaded_value=1>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 0) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 1) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 0)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end

      describe 'with an expected value of nil' do
        subject { @comparison.matches?(@model.new(@property => 0)) }

        before do
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id < 1' }
  end
end

describe DataMapper::Query::Conditions::GreaterThanOrEqualToComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = 1
    @other_value    = 2
    @slug           = :gte
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::GreaterThanOrEqualToComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=1 @loaded_value=1>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 1) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 0) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 0)) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end

      describe 'with an expected value of nil' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        before do
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id >= 1' }
  end
end

describe DataMapper::Query::Conditions::LessThanOrEqualToComparison do
  it_behaves_like 'DataMapper::Query::Conditions::AbstractComparison'

  before do
    @property       = @model.properties[:id]
    @other_property = @model.properties[:title]
    @value          = 1
    @other_value    = 2
    @slug           = :lte
    @comparison     = DataMapper::Query::Conditions::Comparison.new(@slug, @property, @value)
    @other          = ::OtherComparison.new(@property, @value)
  end

  subject { @comparison }

  it { is_expected.to respond_to(:inspect) }

  describe '#inspect' do
    subject { @comparison.inspect }

    it { is_expected.to eq '#<DataMapper::Query::Conditions::LessThanOrEqualToComparison @subject=#<DataMapper::Property::Serial @model=Blog::Article @name=:id> @dumped_value=1 @loaded_value=1>' }
  end

  it { is_expected.to respond_to(:matches?) }

  describe '#matches?' do
    supported_by :all do
      describe 'with a matching Hash' do
        subject { @comparison.matches?(@property.field => 1) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Hash' do
        subject { @comparison.matches?(@property.field => 2) }

        it { is_expected.to be(false) }
      end

      describe 'with a matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        it { is_expected.to be(true) }
      end

      describe 'with a not matching Resource' do
        subject { @comparison.matches?(@model.new(@property => 2)) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil field' do
        subject { @comparison.matches?(@property.field => nil) }

        it { is_expected.to be(false) }
      end

      describe 'with a not matching nil attribute' do
        subject { @comparison.matches?(@model.new(@property => nil)) }

        it { is_expected.to be(false) }
      end

      describe 'with an expected value of nil' do
        subject { @comparison.matches?(@model.new(@property => 1)) }

        before do
          @comparison = DataMapper::Query::Conditions::Comparison.new(@slug, @property, nil)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  it { is_expected.to respond_to(:relationship?) }

  describe '#relationship?' do
    subject { @comparison.relationship? }

    it { is_expected.to be(false) }
  end

  it { is_expected.to respond_to(:to_s) }

  describe '#to_s' do
    subject { @comparison.to_s }

    it { is_expected.to eq 'id <= 1' }
  end
end
