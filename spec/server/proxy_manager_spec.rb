require_relative '../spec_helper'
require_relative '../../lib/proxy_manager'
require 'rack/test'
require 'webmock/rspec'

describe ProxyManager do
  include Rack::Test::Methods

  before do
    @proxy_server = Object.new
    ProxyManager.any_instance.stub(:start_proxy).with(anything()).and_return(@proxy_server)
    ProxyManager.any_instance.stub(:get_proxy).with(anything()).and_return(@proxy_server)
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

  it "ads a given url to a list of them to track" do
    track_url = 'public/.*.js'

    @proxy_server.should_receive(:track_request).with(track_url)
    post "/proxies/1111/requests", {:track => track_url}
  end

  it "ads a given url to a list of them to track" do
    @proxy_server.stub!(:requests).and_return(['request 1', 'request 2'])
    response = get "/proxies/1111/requests"
    requests = JSON.parse(response.body)
    requests.should include('request 1')
    requests.should include('request 2')
  end
end