require_relative '../spec_helper'
require_relative '../../lib/proxy/proxy_server'

describe ProxyServer do
  it "can be configured with an upstream proxy" do
    proxy_uri = 'http://test-proxy:80'
    proxy = ProxyServer.new :proxy => proxy_uri
    proxy.upstream_proxy.should == URI.parse(proxy_uri)
  end

  it "should get the proxy settings" do
    proxy_uri = 'http://test-proxy:80'

    proxy = ProxyServer.new :proxy => proxy_uri
    options = {}
    proxy.get_proxy(options)
    options[:proxy].should == {:type => 'http', :host => 'test-proxy', :port => 80}
  end

  it "should ignore proxy settings if none specified" do
    proxy = ProxyServer.new
    options = {}

    proxy.get_proxy(options)

    options.should_not have_key :proxy
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

  it "should track a request" do
    uri = "http://google.com"
    proxy = ProxyServer.new

    proxy.track uri

    proxy.requests.length.should == 1
    proxy.requests.should include uri
  end

  it "should determine whether tracking is enabled for a uri" do
    uri = "http://google.com"
    proxy = ProxyServer.new

    proxy.track_request('.*com')

    proxy.tracking_enabled?('http://www.google.com').should be_true
    proxy.tracking_enabled?('http://www.google.co.uk').should be_false
  end

  it "should determine whether there is a substitute for a uri" do
    proxy = ProxyServer.new

    proxy.substitute_request('.*com', :body => 'substitute_response')

    proxy.has_substitute?('http://www.google.com').should be_true
    proxy.has_substitute?('http://www.google.co.uk').should be_false
  end

  it "should substitute a request body" do
    proxy = ProxyServer.new
    substitute_response = 'substitute this'
    proxy.substitute_request('.*com', :body => substitute_response)

    proxy.substitute('http://www.google.com').should == [200, {}, [substitute_response]]
  end

  it "should substitute a request url" do
    proxy = ProxyServer.new
    substitute_url = 'http://www.google.co.uk'
    proxy.substitute_request('.*com', :url => substitute_url)
    proxy.should_receive(:request_uri).with(substitute_url)

    proxy.substitute('http://www.google.com')
  end

  it "reset causes request tracking to be removed" do
    proxy = ProxyServer.new
    proxy.requests << 'request 1' << 'request 2'
    proxy.track_requests << 'request 1' << 'request 2'
    proxy.reset
    proxy.requests.length.should == 0
    proxy.track_requests.length.should == 0
  end

  it "reset causes request substituting to be removed" do
    proxy = ProxyServer.new
    proxy.substitute_requests['test'] = 'item'
    proxy.reset
    proxy.substitute_requests.length.should == 0
  end

  context "using response" do
    it "tracks requests" do
      proxy = ProxyServer.new
      proxy.should_receive(:request_uri).with('http://www.google.com')

      proxy.track_request '.*google\.com'
      proxy.response('REQUEST_URI' => 'http://www.google.com')
    end

    it "substitutes a request" do
      proxy = ProxyServer.new
      substitute_body = 'substitute'

      proxy.substitute_request '.*google\.com', :body => substitute_body
      proxy.response('REQUEST_URI' => 'http://www.google.com')[2].should == [substitute_body]
    end
  end
end
