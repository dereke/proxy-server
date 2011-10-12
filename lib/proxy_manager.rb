require 'sinatra/base'
require 'proxy-server'
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
    new_proxy_port = assigned_proxy_ports.max
    new_proxy_port += 1 unless new_proxy_port.nil?
    new_proxy_port ||= START_PORT

    assigned_proxy_ports << new_proxy_port

    start_proxy(new_proxy_port)

    {:port => new_proxy_port}.to_json
  end

  delete '/proxies' do
    assigned_proxy_ports.clear
  end

  post '/proxies/:port/track' do |port|
    proxy_server = get_proxy(port.to_i)
    proxy_server.tracking[:patterns] << params[:pattern]
  end

  def get_proxy(port)
    running_proxy_servers[port]
  end

  def start_proxy(port)
    p "calling actual start!"
    proxy_server = ProxyServer.new(:port => port)
    proxy_server.run
    running_proxy_servers[port] = proxy_server
  end
end

