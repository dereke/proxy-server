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
    # this is probably going to need some mocking out of the request in ProxyServer once it starts working..
  end

  it "should allow requests with query strings" do
    stub_request(:get, "http://www.example.com?para=value")

    response = get "http://www.example.com?para=value"
    response.status.should == 200
  end
end
