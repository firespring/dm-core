require_relative '../spec_helper'

describe DataMapper do
  describe '.setup' do
    describe 'using connection string' do
      before :all do
        @return = DataMapper.setup(:setup_test, 'inmemory://user:pass@hostname:1234/path?foo=bar&baz=foo#fragment')

        @options = @return.options
      end

      after :all do
        DataMapper::Repository.adapters.delete(@return.name)
      end

      it 'returns an Adapter' do
        expect(@return).to be_kind_of(DataMapper::Adapters::AbstractAdapter)
      end

      it 'sets up the repository' do
        expect(DataMapper.repository(:setup_test).adapter).to equal(@return)
      end

      {
        :adapter  => 'inmemory',
        :user     => 'user',
        :password => 'pass',
        :host     => 'hostname',
        :port     => 1234,
        :path     => '/path',
        :fragment => 'fragment'
      }.each do |key, val|
        it "extracts the #{key.inspect} option from the uri" do
          expect(@options[key]).to eq val
        end
      end

      it 'aliases the scheme of the uri as the adapter' do
        expect(@options[:scheme]).to eq @options[:adapter]
      end

      it 'leaves the query param intact' do
        expect(@options[:query]).to eq 'foo=bar&baz=foo'
      end

      it 'extracts the query param as top-level options' do
        expect(@options[:foo]).to eq 'bar'
        expect(@options[:baz]).to eq 'foo'
      end
    end

    describe 'using options' do
      before :all do
        @return = DataMapper.setup(:setup_test, :adapter => :in_memory, :foo => 'bar')

        @options = @return.options
      end

      after :all do
        DataMapper::Repository.adapters.delete(@return.name)
      end

      it 'returns an Adapter' do
        expect(@return).to be_kind_of(DataMapper::Adapters::AbstractAdapter)
      end

      it 'sets up the repository' do
        expect(DataMapper.repository(:setup_test).adapter).to equal(@return)
      end

      {
        :adapter => :in_memory,
        :foo     => 'bar'
      }.each do |key, val|
        it "Sets the #{key.inspect} option" do
          expect(@options[key]).to eq val
        end
      end
    end

    describe 'using invalid options' do
      it 'Raises an exception' do
        expect {
          DataMapper.setup(:setup_test, :invalid)
        }.to raise_error(ArgumentError, '+options+ should be Hash or Addressable::URI or String, but was Symbol')
      end
    end

    describe 'using an instance of an adapter' do
      before :all do
        @adapter = DataMapper::Adapters::InMemoryAdapter.new(:setup_test)

        @return = DataMapper.setup(@adapter)
      end

      after :all do
        DataMapper::Repository.adapters.delete(@return.name)
      end

      it 'Returns an Adapter' do
        expect(@return).to be_kind_of(DataMapper::Adapters::AbstractAdapter)
      end

      it 'Sets up the repository' do
        expect(DataMapper.repository(:setup_test).adapter).to equal(@return)
      end

      it 'Uses the adapter given' do
        expect(@return).to eq @adapter
      end

      it 'Uses the name given to the adapter' do
        expect(@return.name).to eq @adapter.name
      end
    end

    supported_by :postgres, :mysql, :sqlite3, :sqlserver do
      { :path => :database, :user => :username }.each do |original_key, new_key|
        describe "using #{new_key.inspect} option" do
          before :all do
            @return = DataMapper.setup(:setup_test, :adapter => @adapter.options[:adapter], new_key => @adapter.options[original_key])

            @options = @return.options
          end

          after :all do
            DataMapper::Repository.adapters.delete(@return.name)
          end

          it 'Returns an Adapter' do
            expect(@return).to be_kind_of(DataMapper::Adapters::AbstractAdapter)
          end

          it 'Sets up the repository' do
            expect(DataMapper.repository(:setup_test).adapter).to equal(@return)
          end

          it "Sets the #{new_key.inspect} option" do
            expect(@options[new_key]).to eq @adapter.options[original_key]
          end
        end
      end
    end
  end
end
