require_relative '../spec_helper'
require_relative '../../lib/proxy-server'
require 'rack/test'
require 'webmock/rspec'

describe ProxyServer do
  include Rack::Test::Methods

  let(:app) { ProxyServer.new }

  it "can be configured with an upstream proxy" do
    proxy_uri = 'http://test-proxy'
    proxy_port = 90
    proxy = ProxyServer.new :proxy => {:uri => proxy_uri, :port => proxy_port}
    proxy.upstream_proxy.should == "#{proxy_uri}:#{proxy_port}"
  end

  it "can be configured to run on a specific port" do
    proxy_port = 8080
    proxy = ProxyServer.new :port => proxy_port
    proxy.port.should == proxy_port
  end

  it "default the port when none is specified" do
    proxy = ProxyServer.new
    proxy.port.should == ProxyServer::DEFAULT_PORT
  end

  it "should allow requests" do
    stub_request(:get, "http://www.example.com")

    response = get 'http://www.example.com'
    response.status.should == 200
  end

  it "should allow requests with query strings" do
    stub_request(:get, "http://www.example.com?para=value")

    response = get "http://www.example.com?para=value"
    response.status.should == 200
  end

  it "can substitute the response of a request with a body of text" do
    proxy = ProxyServer.new
    expected_response = "this is not what you are looking for"
    proxy.substitute_request '.*com', :body => expected_response

    browser = Rack::Test::Session.new(Rack::MockSession.new(proxy))
    response = browser.get 'http://www.google.com'
    response.body.should == expected_response
  end

  it "can substitute the response of a request with another url to call" do
    proxy = ProxyServer.new
    substitute_url = "http://example.com"
    expected_response_body = "substitute body"
    stub_request(:get, substitute_url).to_return(:body => expected_response_body)
    proxy.substitute_request '.*com', :url => substitute_url

    browser = Rack::Test::Session.new(Rack::MockSession.new(proxy))
    response = browser.get 'http://www.google.com'
    response.body.should == expected_response_body
  end
end
