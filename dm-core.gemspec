require 'English'
require File.expand_path('../lib/dm-core/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'dm-core'
  gem.version     = DataMapper::VERSION.dup
  gem.authors     = ['Dan Kubb']
  gem.email       = %w(dan.kubb@gmail.com)
  gem.description = 'DataMapper core library'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/datamapper/dm-core'

  gem.require_paths    = %w(lib)
  gem.files            = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.extra_rdoc_files = %w(LICENSE README.md)

  gem.add_runtime_dependency('addressable', '~> 2.3', '>= 2.3.5')

end
