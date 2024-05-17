require_relative '../spec_helper'
require 'dm-core/support/ext/module'

describe DataMapper::Ext::Module do

  before :all do
    Object.send(:remove_const, :Foo) if defined?(Foo)
    Object.send(:remove_const, :Baz) if defined?(Baz)
    Object.send(:remove_const, :Bar) if defined?(Bar)

    module ::Foo
      module ModBar
        module Noo
          module Too
            module Boo; end
          end
        end
      end

      class Zed; end
    end

    class ::Baz; end

    class ::Bar; end
  end

  it 'raises NameError for a missing constant' do
    expect { DataMapper::Ext::Module.find_const(Foo, 'Moo') }.to raise_error(NameError)
    expect { DataMapper::Ext::Module.find_const(Object, 'MissingConstant') }.to raise_error(NameError)
  end

  it 'is able to get a recursive constant' do
    expect(DataMapper::Ext::Module.find_const(Object, 'Foo::ModBar')).to eq Foo::ModBar
  end

  it 'ignores get Constants from the Kernel namespace correctly' do
    expect(DataMapper::Ext::Module.find_const(Object, '::Foo::ModBar')).to eq ::Foo::ModBar
  end

  it 'finds relative constants' do
    expect(DataMapper::Ext::Module.find_const(Foo, 'ModBar')).to eq Foo::ModBar
    expect(DataMapper::Ext::Module.find_const(Foo, 'Baz')).to eq Baz
  end

  it 'finds sibling constants' do
    expect(DataMapper::Ext::Module.find_const(Foo::ModBar, 'Zed')).to eq Foo::Zed
  end

  it 'finds nested constants on nested constants' do
    expect(DataMapper::Ext::Module.find_const(Foo::ModBar, 'Noo::Too')).to eq Foo::ModBar::Noo::Too
  end

  it 'finds constants outside of nested constants' do
    expect(DataMapper::Ext::Module.find_const(Foo::ModBar::Noo::Too, 'Zed')).to eq Foo::Zed
  end

  it 'is able to find past the second nested level' do
    expect(DataMapper::Ext::Module.find_const(Foo::ModBar::Noo, 'Too')).to eq Foo::ModBar::Noo::Too
    expect(DataMapper::Ext::Module.find_const(Foo::ModBar::Noo::Too, 'Boo')).to eq Foo::ModBar::Noo::Too::Boo
  end

  it 'is able to deal with constants being added and removed' do
    DataMapper::Ext::Module.find_const(Object, 'Bar') # First we load Bar with find_const
    Object.module_eval { remove_const('Bar') } # Now we delete it
    module ::Bar; end; # Now we redefine it
    expect(DataMapper::Ext::Module.find_const(Object, 'Bar')).to eq Bar
  end

end
