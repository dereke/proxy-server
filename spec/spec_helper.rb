require 'rubygems'
require 'bundler'
Bundler.setup
require 'rspec'
ENV['RACK_ENV'] = 'test'

class String
  alias each each_line
end