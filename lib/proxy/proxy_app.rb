require 'sinatra/base'
require 'json'

class ProxyApp < Sinatra::Base
  disable :show_exceptions

  def initialize(proxy_manager = ProxyManager.new)
    @proxy_manager = proxy_manager
    super
  end

  get '/proxies' do
    @proxy_manager.proxies.to_json
  end

  post '/proxies' do
    proxy_uri = @proxy_manager.new_proxy

    options = {
        :port => proxy_uri.port
    }

    options[:proxy] = params[:proxy] if params[:proxy]
    @proxy_manager.start_proxy(options)

    {
        :url => proxy_uri.to_s,
        :port => proxy_uri.port
    }.to_json
  end

  delete '/proxies' do
    @proxy_manager.delete_proxies
  end

  delete '/proxies/:port' do |port|
    @proxy_manager.stop_proxy port.to_i
  end

  post '/proxies/:port/reset' do |port|
    proxy_server = @proxy_manager.get_proxy(port.to_i)
    proxy_server.reset
  end

  post '/proxies/:port/requests' do |port|
    proxy_server = @proxy_manager.get_proxy(port.to_i)
    proxy_server.track_request(params[:track])
  end

  get '/proxies/:port/requests' do |port|
    proxy_server = @proxy_manager.get_proxy(port.to_i)
    proxy_server.requests.to_json
  end

  post '/proxies/:port/requests/substitute' do |port|
    proxy_server = @proxy_manager.get_proxy(port.to_i)
    options = {}
    options[:body] = params[:body] if params[:body]
    options[:url] = params[:url] if params[:url]
    proxy_server.substitute_request(params[:pattern], options)
  end

  class << self
    def start(options = {})
      require 'thin'
      server = ::Thin::Server.new(
          '0.0.0.0',
          options.fetch(:port, 4985),
          ProxyApp.new
      )

      server.start
    end
  end
end