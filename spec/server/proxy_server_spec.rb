require_relative '../spec_helper'
require_relative '../../lib/proxy-server'
require 'rack/test'
ENV['RACK_ENV'] = 'test'

describe CapturedProxy do
  include Rack::Test::Methods

  it "can be configured with an upstream proxy" do
    proxy_uri = 'test-proxy'
    proxy_port = 90
    proxy = CapturedProxy.new :proxy => {:uri => proxy_uri, :port => proxy_port}
    proxy.upstream_proxy.should == "#{proxy_uri}:#{proxy_port}"
  end

  it "can be configured to run on a specific port" do
    proxy_port = 8080
    proxy = CapturedProxy.new :port => proxy_port
    proxy.port.should == proxy_port
  end

  it "default the port when none is specified" do
    proxy = CapturedProxy.new
    proxy.port.should == CapturedProxy::DEFAULT_PORT
  end

  context "control mechanism" do
    let(:app) {CapturedProxy.new}

    it "can tell when a control url is requested" do
      proxy = CapturedProxy.new
      proxy.is_control_request?("/proxy_control").should be_true
      proxy.is_control_request?("google.com").should be_false
    end

    it "ads a given url to a list of them to track" do
      track_url = 'public/.*.js'
      post '/proxy_control/track', {:uri_pattern => track_url}

      app.tracking[:patterns].should include(track_url)
    end

    it "tracks a url that has been configured to be tracked" do
      track_url = 'www.google.com/public/.*.js'
      post '/proxy_control/track', {:uri_pattern => track_url}

      tracked_url = 'http://www.google.com/public/something.js?query=something'
      get tracked_url

      app.tracking[:requests].should include(tracked_url)
    end

    it "returns the requests that were tracked" do
      track_url = 'www.google.com/public/.*.js'
      post '/proxy_control/track', {:uri_pattern => track_url}

      tracked_url = 'http://www.google.com/public/something.js?query=something'
      get tracked_url

      requests_response = get '/proxy_control/requests'

      requests = JSON.parse(requests_response.body)
      requests.should include(tracked_url)
    end
  end
end
