require_relative '../spec_helper'
require_relative '../../lib/proxy_manager'
require 'rack/test'
require 'httpclient'
#require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

describe ProxyManager do
  include Rack::Test::Methods

  before do
    delete '/proxies'

    ProxyManager.stub!(:start_proxy).and_return{Object.new}
  end

  let(:app) { ProxyManager.new }

  it "should create a new proxy when I ask for one" do
    response = post '/proxies'
    proxy = JSON.parse(response.body)
    proxy.should == {'port' => ProxyManager::START_PORT}
  end

  it "should tell me about all the proxies that have been created" do
    post '/proxies'
    response = get '/proxies'
    JSON.parse(response.body).should == [ProxyManager::START_PORT]
  end

  it "should remove all proxies when asked" do
    post '/proxies'
    delete '/proxies'

    response = get '/proxies'
    JSON.parse(response.body).should == []
  end

  it "should assign new proxy ports when more than one is asked for" do
    first_expected_proxy = ProxyManager::START_PORT
    second_expected_proxy = ProxyManager::START_PORT + 1

    first_response = post '/proxies'
    second_response = post '/proxies'

    JSON.parse(first_response.body)['port'].should == first_expected_proxy
    JSON.parse(second_response.body)['port'].should == second_expected_proxy
  end
end


describe "a started proxy server" do
  include Rack::Test::Methods

  def app
    @app
  end

  let(:proxy_manager) {
    proxy_manager = app

    until proxy_manager.is_a? ProxyManager
      proxy_manager = proxy_manager.instance_variable_get(:@app)
    end
    proxy_manager
  }

  before do
    ENV = {}
    @app = ProxyManager.new
    response = post '/proxies'
    @proxy_port = JSON.parse(response.body)['port']
    @proxy_uri = "http://localhost:#{@proxy_port}"
    sleep 2
  end

  it "should allow requests" do
    client = HTTPClient.new(:proxy => @proxy_uri)
    response = client.get 'http://www.example.com'
    response.status.should == 200
    # this is probably going to need some mocking out of the request in ProxyServer once it starts working..
  end

  context "track requests passing through the proxy" do
    it "should track all requests that are made when configured" do

      response = post "/proxies/#{@proxy_port}/track", {:pattern => 'example.js'}
      response.status.should == 200

      client = HTTPClient.new(:proxy => @proxy_uri)
      request_uri = 'http://www.example.com'
      response = client.get request_uri
      response.status.should == 200
      proxy_manager.running_proxy_servers.length.should == 1
      proxy_manager.running_proxy_servers[@proxy_port].tracking[:requests].should include(request_uri)
    end
  end
end
