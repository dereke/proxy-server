require 'httpclient'
require "thin"
require "rack/content_length"
require "rack/chunked"

class ProxyServer
  attr_reader :upstream_proxy, :port
  attr_reader :requests, :track_requests, :substitute_requests

  DEFAULT_PORT = 8080

  def initialize(options = {})
    @upstream_proxy = options[:proxy]

    @port = options.fetch(:port, DEFAULT_PORT)

    @substitute_requests = {}
    @requests = []
    @track_requests = []
  end

  def http_client
    HTTPClient.new :proxy => @upstream_proxy
  end

  def run
    @proxy_thread = Thread.new do
      server = ::Thin::Server.new('0.0.0.0',
                                  self.port,
                                  self)

      server.start
    end
  end

  def stop
    Thread.kill @proxy_thread if @proxy_thread
  end

  def reset
    @requests.clear
    @track_requests.clear
    @substitute_requests.clear
  end

  def call(env)
    log_request env

    response = get_substitution(env)
    return response unless response.nil?


    method  = env['REQUEST_METHOD']
    uri     = get_url(env)
    body    = get_request_body(env)
    headers = get_request_headers(env)

    query_string_match = uri.match(/\?(.*)$/)
    query_string = query_string_match ? query_string_match[1] : ""
    params  = get_params(query_string)

    response = http_client.request(method, uri, params, body, headers)
    [ response.status, response.headers, [response.body] ]
  end

  def get_url(env)
    env['REQUEST_URI'] || "http://#{env['SERVER_NAME']}#{env['PATH_INFO']}#{env['QUERY_STRING'].length > 0 ? '?'+env['QUERY_STRING'] : ''}"
  end

  def get_substitution(env)
    @substitute_requests.each do |pattern, options|
      if Regexp.new(pattern) =~ get_url(env)
        return get_substituted_response(options)
      end
    end
    nil
  end

  def get_substituted_response(options)
    if options[:body]
      [ 200, {}, [options[:body]] ]
    elsif options[:url]
      response = @client.get(options[:url])
      [ response.status, response.headers, [response.body] ]
    end
  end

  def substitute_request(pattern, options)
    @substitute_requests[pattern] = options
  end

  def track_request(pattern)
    @track_requests << pattern
  end

  def get_params(query_string)
    query_string.split('&').inject({}) do |hsh, i|
      kv = i.split('='); hsh[kv[0]] = kv[1]; hsh
    end unless query_string.nil? or query_string.length == 0
  end

  def log_request(env)
    url = get_url(env)
    @track_requests.each do |pattern|
      @requests << url if Regexp.new(pattern) =~ url
    end
  end

  private
  def get_request_body(env)
    body = ''
    env['rack.input'].each_line {|string| body << string }
    body
  end

  def get_request_headers(env)
    headers = {}
    env.each {|k,v| if k =~ /HTTP_(\w+)/ then headers[$1] = v end }
    headers
  end
end