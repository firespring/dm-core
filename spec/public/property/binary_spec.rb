require_relative '../../spec_helper'

describe DataMapper::Property::Binary do
  before :all do
    @name          = :title
    @type          = described_class
    @load_as       = String
    @value         = 'value'
    @other_value   = 'return value'
    @invalid_value = 1
  end

  it_behaves_like 'A public Property'

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to eql(load_as: @load_as, dump_as: @load_as, length: 50) }
  end

  if RUBY_VERSION >= "1.9"
    describe 'encoding' do
      let(:model) do
        Class.new do
          include ::DataMapper::Resource
          property :bin_data, ::DataMapper::Property::Binary
        end
      end

      it 'always dumps with BINARY' do
        expect(model.bin_data.dump('foo'.freeze).encoding.names).to include('BINARY')
      end

      it 'always loads with BINARY' do
        expect(model.bin_data.load('foo'.freeze).encoding.names).to include('BINARY')
      end

      it 'has valid options' do
        expect(model.bin_data.options).to eql(load_as: @load_as, dump_as: @load_as, length: 50)
      end
    end
  end
end
