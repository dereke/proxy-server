require 'rack'
require 'httpclient'

class ProxyServer

  attr_reader :upstream_proxy, :port
  attr_reader :tracking

  DEFAULT_PORT = 8080

  def initialize(options = {})
    if upstream_proxy_options = options[:proxy]
      @upstream_proxy = "#{upstream_proxy_options[:uri]}:#{upstream_proxy_options[:port]}"
    end
    @client = create_http_client

    @port = options.fetch(:port, DEFAULT_PORT)
    @tracking = {
        :patterns => [],
        :requests => []
    }
  end

  def create_http_client
    HTTPClient.new :proxy => @upstream_proxy
  end

  def run
    Thread.new do
      @handler = Rack::Handler::WEBrick

      @handler.run self, :Port => self.port
    end
  end

  def call(env)

    method  = env['REQUEST_METHOD']
    uri     = "http://#{env['HTTP_HOST']}#{env['PATH_INFO']}"
    params  = get_params(env['QUERY_STRING'])
    body    = get_request_body(env)
    headers = get_request_headers(env)

    response = @client.request(method, uri, params, body, headers)

    log_request env

    [ response.status, response.headers, [response.body] ]
  end

  def get_params(query_string)
    query_string.split('&').inject({}) do |hsh, i|
      kv = i.split('='); hsh[kv[0]] = kv[1]; hsh
    end unless query_string.nil? or query_string.length == 0
  end

  def log_request(env)

    url = env['REQUEST_URI'] || "http://#{env['SERVER_NAME']}#{env['PATH_INFO']}#{env['QUERY_STRING'] ? '?'+env['QUERY_STRING'] : ''}"
    @tracking[:patterns].each do |pattern|
      @tracking[:requests] << url if Regexp.new(pattern) =~ url
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

