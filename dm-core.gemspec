require 'English'
require File.expand_path('lib/dm-core/version', __dir__)

Gem::Specification.new do |gem|
  gem.name        = 'dm-core'
  gem.version     = DataMapper::VERSION.dup
  gem.required_ruby_version = '>= 2.7.8'
  gem.authors     = ['Dan Kubb']
  gem.email       = %w(dan.kubb@gmail.com)
  gem.summary = 'DataMapper core library'
  gem.description = 'DataMapper core library where one row in the data-store should equal one object reference. ' \
                    'Pretty simple idea. Pretty profound impact.'
  gem.license = 'Nonstandard'
  gem.homepage = 'https://github.com/firespring/dm-core'

  gem.require_paths    = %w(lib)
  gem.files            = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.extra_rdoc_files = %w(LICENSE README.md)

  gem.add_runtime_dependency('addressable', '~> 2.3', '>= 2.3.5')
end
