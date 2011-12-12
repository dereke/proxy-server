require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

task :coverage do
  require 'simplecov'
  require 'rspec/core'

  SimpleCov.start do
    add_group "lib", "lib"
    add_filter 'spec'
  end
  SimpleCov.start
  RSpec::Core::Runner.run %w[spec]
end


require 'rake/clean'
CLEAN.include %w(**/*.{log,pyc,rbc,tgz} doc)
