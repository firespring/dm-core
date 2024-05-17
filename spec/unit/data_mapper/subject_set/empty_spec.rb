require_relative '../../../spec_helper'
require 'dm-core/support/subject_set'
require_relative 'shared/empty_spec'

describe 'DataMapper::SubjectSet#empty?' do
  before :all do

    class ::Person
      attr_reader :name
      def initialize(name)
        @name = name
      end
    end

  end

  subject { set.empty? }

  context 'with no entries in it' do
    let(:set) { DataMapper::SubjectSet.new }

    it_behaves_like 'DataMapper::SubjectSet#empty? with no entries in it'
  end

  context 'with entries in it' do
    let(:set)   { DataMapper::SubjectSet.new([ entry ]) }
    let(:entry) { Person.new('Alice')                   }

    it_behaves_like 'DataMapper::SubjectSet#empty? with entries in it'
  end
end
