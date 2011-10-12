require_relative '../spec_helper'
require_relative '../../lib/proxy_manager'
require 'rack/test'

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
end