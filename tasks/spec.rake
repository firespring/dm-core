require 'rspec/core/rake_task'

spec_defaults = lambda do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

begin
  task(:default).clear
  task(:spec).clear

  RSpec::Core::RakeTask.new(:spec, &spec_defaults)
rescue LoadError
  task :spec do
    abort 'rspec is not available. In order to run spec, you must: gem install rspec'
  end
end

task :default => :spec
