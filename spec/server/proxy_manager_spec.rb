require_relative '../spec_helper'
require_relative '../../lib/proxy_manager'
require 'rack/test'
require 'webmock/rspec'

describe ProxyManager do
  include Rack::Test::Methods

  before do
    ProxyManager.any_instance.stub(:start_proxy).with(anything()).and_return{Object.new}
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

  context "once a proxy has been created" do
    before do
      response = post '/proxies'
      @proxy_port = JSON.parse(response.body)['port']
      @proxy_server = ProxyServer.new(:port => @proxy_port)
      ProxyManager.any_instance.stub(:get_proxy).with(@proxy_port).and_return{@proxy_server}
    end

    it "ads a given url to a list of them to track" do
      track_url = 'public/.*.js'
      post "/proxies/#{@proxy_port}/requests", {:track => track_url}

      @proxy_server.tracking[:patterns].should include(track_url)
    end

    it "tracks a url that has been configured to be tracked" do
      track_url = 'public/.*.js'
      post "/proxies/#{@proxy_port}/requests", {:track => track_url}

      stub_request(:get, "http://www.google.com/public/something.js?query=something")
      tracked_url = 'http://www.google.com/public/something.js?query=something'

      browser = Rack::Test::Session.new(Rack::MockSession.new(@proxy_server))
      browser.get tracked_url

      @proxy_server.tracking[:requests].should include(tracked_url)
    end

    it "returns the requests that were tracked" do
      track_url = 'www.google.com/public/.*.js'
      post "/proxies/#{@proxy_port}/requests", {:track => track_url}

      stub_request(:get, "http://www.google.com/public/something.js?query=something")
      tracked_url = 'http://www.google.com/public/something.js?query=something'

      browser = Rack::Test::Session.new(Rack::MockSession.new(@proxy_server))
      browser.get tracked_url

      requests_response = get "/proxies/#{@proxy_port}/requests"

      requests = JSON.parse(requests_response.body)
      requests.should include(tracked_url)
    end
  end
end