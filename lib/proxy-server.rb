require 'rack'
require 'httparty'
require 'sinatra/base'
require 'json'

class CapturedProxy
  include HTTParty

  attr_reader :upstream_proxy, :port
  attr_reader :tracking

  DEFAULT_PORT = 8080

  def initialize(options = {})
    if upstream_proxy_options = options[:proxy]
      @upstream_proxy = "#{upstream_proxy_options[:uri]}:#{upstream_proxy_options[:port]}"
    end

    @port = options.fetch(:port, DEFAULT_PORT)
    @tracking = {
        :patterns => [],
        :requests => []
    }
    $tracking = @tracking # this is hacky but lets the sinatra app talk to this one

    @control_app = Sinatra.new do
      post '/proxy_control/track' do
        $tracking[:patterns] << params[:uri_pattern]
      end

      get '/proxy_control/requests' do
        content_type :json
        $tracking[:requests].to_json
      end
    end
  end

  def self.run!(proxy)
    handler = Rack::Handler::WEBrick

    begin
      require 'thin'
      handler = Rack::Handler::Thin
    rescue LoadError
    end

    handler.run proxy, :Port => proxy.port
  end

  def is_control_request?(path)
    path =~ /^\/proxy_control/
  end

  def call env
    path   = env['PATH_INFO']
    url    = env['REQUEST_URI']
    method = env['REQUEST_METHOD'].downcase
    if is_control_request? path
      @control_app.call env
    else
      log_request env

      #CapturedProxy.http_proxy('www-cache-bbcny.reith.bbc.co.uk',80)
      #response = CapturedProxy.send method, url, :body => _get_request_body(env), :headers => _get_request_headers(env), :format => 'text'
      #response_body = response.body
      #
      #[ response.code, _get_response_headers(response), [response_body] ]
      [200, {}, ['']]
    end
  end

  def log_request(env)
    url = env['REQUEST_URI'] || "http://#{env['SERVER_NAME']}#{env['PATH_INFO']}#{env['QUERY_STRING'] ? '?'+env['QUERY_STRING'] : ''}"
    @tracking[:patterns].each do |pattern|
      p pattern
      @tracking[:requests] << url if Regexp.new(pattern) =~ url
    end
   # if url =~ /#{'http://bbc.112.2o7.net'}/
   #   Analytics::AnalyticsLogger.raw_requests << url
   #end
  end

  # env['rack.input'] returns an IO object that you must #each over to get the full body
  def _get_request_body(env)
    body = ''
    env['rack.input'].each {|string| body << string }
    body
  end

  # response.headers returns an object that wraps the actual Hash of headers ... this gets the actual Hash
  def _get_response_headers(response)
    response_headers = response.headers.instance_variable_get('@header')
    response_headers.each {|k, v| response_headers[k] = response_headers[k][0] } # values are all in arrays
    response_headers
  end

  # we should pass along all HTTP_* headers and we need to CHANGE the HTTP_HOST header to reflect the new host we're making the request to
  def _get_request_headers(env)
    headers = {}
    env.each {|k,v| if k =~ /HTTP_(\w+)/ then headers[$1] = v end }
    headers.delete 'HOST' # simply delete it and let HTTP do the rest
    headers
  end
end
