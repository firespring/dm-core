shared_examples 'A semipublic Property' do
  before :all do
    %w(@type @name @value @other_value).each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
    end

    module ::Blog
      class Article
        include DataMapper::Resource
        property :id, Serial
      end
    end

    @model      = Blog::Article
    @options  ||= {}
    @property   = @type.new(@model, @name, @options)
  end

  describe '.new' do
    describe 'when provided no options' do
      it 'returns a Property' do
        expect(@property).to be_kind_of(@type)
      end

      it 'sets the load_as' do
        expect(@property.load_as).to be(@type.load_as)
      end

      it 'sets the model' do
        expect(@property.model).to equal(@model)
      end

      it 'sets the options to the default' do
        expect(@property.options).to eq @type.options.merge(@options)
      end
    end

    %i(index unique_index unique lazy).each do |attribute|
      [true, false, :title, [:title]].each do |value|
        describe "when provided #{(options = {attribute => value}).inspect}" do
          before :all do
            @property = @type.new(@model, @name, @options.merge(options))
          end

          it 'returns a Property' do
            expect(@property).to be_kind_of(@type)
          end

          it 'sets the model' do
            expect(@property.model).to equal(@model)
          end

          it 'sets the load_as' do
            expect(@property.load_as).to be(@type.load_as)
          end

          it "sets the options to #{options.inspect}" do
            expect(@property.options).to eq @type.options.merge(@options.merge(options))
          end
        end
      end

      [[], nil].each do |value|
        describe "when provided #{(invalid_options = {attribute => value}).inspect}" do
          it 'raises an exception' do
            expect {
              @type.new(@model, @name, @options.merge(invalid_options))
            }.to raise_error(ArgumentError, "options[#{attribute.inspect}] must be either true, false, a Symbol or an Array of Symbols")
          end
        end
      end
    end
  end

  describe '#load' do
    subject { @property.load(@value) }

    before do
      expect(@property).to receive(:typecast).with(@value).and_return(@value)
    end

    it { is_expected.to eql(@value) }
  end

  describe '#typecast' do
    describe "when is able to do typecasting on it's own" do
      it 'delegates all the work to the type' do
        return_value = double(@other_value)
        expect(@property).to receive(:typecast_to_primitive).with(@invalid_value).and_return(return_value)
        @property.typecast(@invalid_value)
      end
    end

    describe 'when value is nil' do
      it 'returns value unchanged' do
        expect(@property.typecast(nil)).to be(nil)
      end

      describe 'when value is a Ruby primitive' do
        it 'returns value unchanged' do
          expect(@property.typecast(@value)).to eq @value
        end
      end
    end
  end

  describe '#valid?' do
    describe 'when provided a valid value' do
      it 'returns true' do
        expect(@property.valid?(@value)).to be(true)
      end
    end

    describe 'when provide an invalid value' do
      it 'returns false' do
        expect(@property.valid?(@invalid_value)).to be(false)
      end
    end

    describe 'when provide a nil value when required' do
      it 'returns false' do
        @property = @type.new(@model, @name, @options.merge(required: true))
        expect(@property.valid?(nil)).to be(false)
      end
    end

    describe 'when provide a nil value when not required' do
      it 'returns false' do
        @property = @type.new(@model, @name, @options.merge(required: false))
        expect(@property.valid?(nil)).to be(true)
      end
    end
  end

  describe '#assert_valid_value' do
    subject do
      @property.assert_valid_value(value)
    end

    shared_examples 'assert_valid_value on invalid value' do
      it 'raises DataMapper::Property::InvalidValueError' do
        expect { subject }.to(raise_error(DataMapper::Property::InvalidValueError) do |error|
          expect(error.property).to eq @property
        end)
      end
    end

    describe 'when provided a valid value' do
      let(:value) { @value }

      it 'returns true' do
        expect(subject).to be(true)
      end
    end

    describe 'when provide an invalid value' do
      let(:value) { @invalid_value }

      it_behaves_like 'assert_valid_value on invalid value'
    end

    describe 'when provide a nil value when required' do
      before do
        @property = @type.new(@model, @name, @options.merge(required: true))
      end

      let(:value) { nil }

      it_behaves_like 'assert_valid_value on invalid value'
    end

    describe 'when provide a nil value when not required' do
      before do
        @property = @type.new(@model, @name, @options.merge(required: false))
      end

      let(:value) { nil }

      it 'returns true' do
        expect(subject).to be(true)
      end
    end
  end
end
