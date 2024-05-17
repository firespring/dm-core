shared_examples 'A public Property' do
  before :all do
    %w(@type @load_as @name @value @other_value).each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
    end

    module ::Blog
      class Article
        include DataMapper::Resource
        property :id, Serial
      end
    end

    @model     = Blog::Article
    @options ||= {}
  end

  describe 'with a sub-type' do
    before :all do
      class ::SubType < @type; end
      @subtype = ::SubType
      @type.accept_options :foo, :bar
    end

    before :all do
      @original = @type.accepted_options.dup
    end

    after :all do
      @type.accepted_options.replace(@original - %i(foo bar))
    end

    describe 'predefined options' do
      before :all do
        class ::ChildSubType < @subtype
          default nil
        end
        @child_subtype = ChildSubType
      end

      describe 'when parent type overrides a default' do
        before do
          @subtype.default 'foo'
        end

        after do
          DataMapper::Property.descendants.delete(ChildSubType)
          Object.send(:remove_const, :ChildSubType)
        end

        it "does not override the child's type setting" do
          expect(@child_subtype.default).to eql(nil)
        end
      end
    end

    after :all do
      DataMapper::Property.descendants.delete(SubType)
      Object.send(:remove_const, :SubType)
    end

    describe '.accept_options' do
      describe 'when provided :foo, :bar' do
        it 'adds new options' do
          [@type, @subtype].each do |type|
            expect(type.accepted_options.include?(:foo)).to be(true)
            expect(type.accepted_options.include?(:bar)).to be(true)
          end
        end

        it 'creates predefined option setters' do
          [@type, @subtype].each do |type|
            expect(type).to respond_to(:foo)
            expect(type).to respond_to(:bar)
          end
        end

        describe 'auto-generated option setters' do
          before :all do
            @type.foo true
            @type.bar 1
            @property = @type.new(@model, @name, @options)
          end

          it 'sets the pre-defined option values' do
            expect(@property.options[:foo]).to eq true
            expect(@property.options[:bar]).to eq 1
          end

          it 'asks the superclass for the value if unknown' do
            expect(@subtype.foo).to eq true
            expect(@subtype.bar).to eq 1
          end
        end
      end
    end

    describe '.descendants' do
      it 'includes the sub-type' do
        expect(@type.descendants.include?(SubType)).to be(true)
      end
    end

    describe '.load_as' do
      it 'returns the load_as' do
        [@type, @subtype].each do |type|
          expect(type.load_as).to be(@load_as)
        end
      end

      it 'changes the load_as class' do
        @subtype.load_as Object
        expect(@subtype.load_as).to be(Object)
      end
    end
  end

  %i(allow_blank allow_nil).each do |opt|
    describe "##{method = "#{opt}?"}" do
      [true, false].each do |value|
        describe "when created with :#{opt} => #{value}" do
          before :all do
            @property = @type.new(@model, @name, @options.merge(opt => value))
          end

          it "returns #{value}" do
            expect(@property.send(method)).to be(value)
          end
        end
      end

      describe "when created with :#{opt} => true and :required => true" do
        it 'fails with ArgumentError' do
          expect {
            @property = @type.new(@model, @name, @options.merge(opt => true, required: true))
          }.to raise_error(ArgumentError,
                               'options[:required] cannot be mixed with :allow_nil or :allow_blank')
        end
      end
    end
  end

  %i(key? required? index unique_index unique?).each do |method|
    describe "##{method}" do
      [true, false].each do |value|
        describe "when created with :#{method} => #{value}" do
          before :all do
            opt = method.to_s.chomp('?').to_sym
            @property = @type.new(@model, @name, @options.merge(opt => value))
          end

          it "returns #{value}" do
            expect(@property.send(method)).to be(value)
          end
        end
      end
    end
  end

  describe '#lazy?' do
    describe 'when created with :lazy => true, :key => false' do
      before :all do
        @property = @type.new(@model, @name, @options.merge(lazy: true, key: false))
      end

      it 'returns true' do
        expect(@property.lazy?).to be(true)
      end
    end

    describe 'when created with :lazy => true, :key => true' do
      before :all do
        @property = @type.new(@model, @name, @options.merge(lazy: true, key: true))
      end

      it 'returns false' do
        expect(@property.lazy?).to be(false)
      end
    end
  end

  describe '#instance_of?' do
    subject { property.instance_of?(klass) }

    let(:property) { @type.new(@model, @name, @options) }

    context 'when provided the property class' do
      let(:klass) { @type }

      it { is_expected.to be(true) }
    end

    context 'when provided the property superclass' do
      let(:klass) { @type.superclass }

      it { is_expected.to be(false) }
    end

    context 'when provided the DataMapper::Property class' do
      let(:klass) { DataMapper::Property }

      it { is_expected.to be(false) }
    end
  end

  describe '#kind_of?' do
    subject { property.is_a?(klass) }

    let(:property) { @type.new(@model, @name, @options) }

    context 'when provided the property class' do
      let(:klass) { @type }

      it { is_expected.to be(true) }
    end

    context 'when provided the property superclass' do
      let(:klass) { @type.superclass }

      it { is_expected.to be(true) }
    end

    context 'when provided the DataMapper::Property class' do
      let(:klass) { DataMapper::Property }

      it { is_expected.to be(true) }
    end
  end
end
