task :coverage do
  require 'simplecov'
  require 'rspec/core'

  SimpleCov.start do
    add_group "lib", "lib"
  end
  SimpleCov.start
  RSpec::Core::Runner.run %w[spec]
end
