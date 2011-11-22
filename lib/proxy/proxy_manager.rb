require_relative './proxy_server'
require_relative './port_prober'
require 'sinatra/base'
require 'json'

class ProxyManager < Sinatra::Base
  START_PORT = 5000

  attr_reader :running_proxy_servers, :assigned_proxy_ports
  disable :show_exceptions

  def initialize()
    @running_proxy_servers = {}
    @assigned_proxy_ports = []
    super
  end

  get '/proxies' do
    assigned_proxy_ports.to_json
  end

  post '/proxies' do
    new_proxy_port = find_proxy_port
    assigned_proxy_ports << new_proxy_port

    options = {
        :port => new_proxy_port
    }

    options[:proxy] = params[:proxy] if params[:proxy]
    start_proxy(options)

    {:port => new_proxy_port}.to_json
  end

  delete '/proxies' do
    assigned_proxy_ports.clear
  end

  delete '/proxies/:port' do |port|
    stop_proxy port.to_i
  end

  post '/proxies/:port/reset' do |port|
    proxy_server = get_proxy(port.to_i)
    proxy_server.reset
  end

  post '/proxies/:port/requests' do |port|
    proxy_server = get_proxy(port.to_i)
    proxy_server.track_request(params[:track])
  end

  get '/proxies/:port/requests' do |port|
    proxy_server = get_proxy(port.to_i)
    proxy_server.requests.to_json
  end

  post '/proxies/:port/requests/substitute' do |port|
    proxy_server = get_proxy(port.to_i)
    options = {}
    options[:body] = params[:body] if params[:body]
    options[:url] = params[:url] if params[:url]
    proxy_server.substitute_request(params[:pattern], options)
  end

  def get_proxy(port)
    running_proxy_servers[port]
  end

  def stop_proxy(port)
    proxy_server = running_proxy_servers[port]
    proxy_server.stop
    running_proxy_servers.delete proxy_server
  end

  def start_proxy(options)
    proxy_server = ProxyServer.new(options)
    proxy_server.run
    running_proxy_servers[options[:port]] = proxy_server
  end

 def find_proxy_port
    new_proxy_port = (assigned_proxy_ports.max || ProxyManager::START_PORT) + 1
    PortProber.above(new_proxy_port)
  end
end