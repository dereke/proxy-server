require_relative '../spec_helper'
require_relative '../../lib/proxy/proxy_app'
require_relative '../../lib/proxy/proxy_manager'
require 'rack/test'
require 'webmock/rspec'

describe ProxyApp do
  include Rack::Test::Methods

  before do
    @proxy_server = mock('ProxyServer')
    @proxy_manager = ProxyManager.new
    @proxy_manager.stub(:start_proxy).with(anything()).and_return(@proxy_server)
    @proxy_manager.stub(:get_proxy).with(anything()).and_return(@proxy_server)
  end

  let(:app) { ProxyApp.new(@proxy_manager) }

  it "should create a new proxy" do
    @proxy_manager.should_receive(:new_proxy).and_return(URI('http://localhost:4000'))
    response = post '/proxies'
    proxy = JSON.parse(response.body)
    proxy['port'].should == 4000
    proxy['url'].should == "http://localhost:4000"
  end

  it "should create a new proxy with an upstream proxy when asked to" do
    @proxy_manager.should_receive(:start_proxy).with(hash_including(:proxy => 'http://my_proxy:80'))
    response = post '/proxies', {:proxy => 'http://my_proxy:80'}
  end

  it "should tell me about all the proxies that have been created" do
    @proxy_manager.should_receive(:find_proxy_port).and_return(4000)

    post '/proxies'
    response = get '/proxies'
    JSON.parse(response.body).should == [4000]
  end

  it "should remove all proxies when asked" do
    post '/proxies'
    delete '/proxies'

    response = get '/proxies'
    JSON.parse(response.body).should == []
  end

  it "should remove a proxy when asked to" do
    running_proxy_port = JSON.parse(post('/proxies').body)['port']
    ProxyManager.any_instance.should_receive(:stop_proxy).with(running_proxy_port)

    response = delete "/proxies/#{running_proxy_port}"

    response.status.should == 200
  end

  it "should assign new proxy ports when more than one is asked for" do
    first_expected_proxy = 100
    second_expected_proxy = 101
    available_proxy_ports = [first_expected_proxy, second_expected_proxy]
    ProxyManager.any_instance.stub(:find_proxy_port).and_return { available_proxy_ports.shift }

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

  it "can substitute a request with another body" do
    @proxy_server.should_receive(:substitute_request).with('*.js', :body => 'alert(1);')
    post "/proxies/1111/requests/substitute", {:pattern => '*.js', :body => 'alert(1);'}
  end

  it "can substitute a request with another url" do
    @proxy_server.should_receive(:substitute_request).with('*.js', :url => 'http://example.com/test.js')
    post "/proxies/1111/requests/substitute", {:pattern => '*.js', :url => 'http://example.com/test.js'}
  end

  it "can reset the configuration of a proxy" do
    @proxy_server.should_receive(:reset)
    post "/proxies/1111/reset"
  end
end