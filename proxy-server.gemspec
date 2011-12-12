$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = 'proxy-server'
  s.version = '0.0.7'
  s.authors = ["Derek Ekins"]
  s.description = 'Proxy server'
  s.summary = "proxy-server-#{s.version}"
  s.email = 'derek@spathi.com'
  s.homepage = "http://github.com/dereke/proxy-server"

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'json', '>= 1.4.6'
  s.add_dependency 'sinatra', '>= 1.2.6'
  s.add_dependency 'httpclient'
  s.add_dependency 'thin'
  s.add_dependency 'goliath', '0.9.2'
  s.add_dependency 'em-synchrony'
  s.add_dependency 'em-http-request'

  s.add_development_dependency 'rake', '>= 0.9.2'
  s.add_development_dependency 'rspec', '>= 2.7.0'
  s.add_development_dependency 'simplecov', '>= 0.4.2'
  s.add_development_dependency 'webmock'


  s.add_development_dependency 'rack-test', '>= 0.5.7'

  s.rubygems_version = ">= 1.6.1"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = "lib"
end