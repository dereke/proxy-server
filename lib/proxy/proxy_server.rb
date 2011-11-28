require 'goliath/api'
require 'goliath/server'
require 'em-synchrony/em-http'
class ProxyServer < Goliath::API
  attr_reader :upstream_proxy, :port
  attr_reader :requests, :track_requests, :substitute_requests
  DEFAULT_PORT = 8080

  def initialize(options = {})
    @upstream_proxy = URI.parse(options[:proxy]) if options[:proxy]

    @port = options.fetch(:port, DEFAULT_PORT)

    @substitute_requests = {}
    @requests = []
    @track_requests = []
  end

  def start
    Thread.abort_on_exception = true
    require 'log4r'
    @proxy_thread = Thread.new do
      Goliath.env = :development
      server = Goliath::Server.new('0.0.0.0', self.port)
      server.app = Goliath::Rack::Builder.build(self.class, self)
      server.logger = Log4r::Logger.new 'proxy-server'

      server.options = {
          :daemonize => false,
          :verbose => true,
          :log_stdout => true,
          :env => :development
      }
      server.start do
        p "Proxy started"
      end
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

  def response(env)
    uri = get_uri env
    track uri if tracking_enabled? uri
    return substitute uri if has_substitute? uri
    request_uri uri
  end

  def get_uri(env)
    env['REQUEST_URI'] || "http://#{env['SERVER_NAME']}#{env['PATH_INFO']}#{env['QUERY_STRING'].length > 0 ? '?'+env['QUERY_STRING'] : ''}"
  end

  def request_uri(uri)
    options = {
        :redirects => 1
    }
    get_proxy(options)
    client= EM::HttpRequest.new(uri, options)
    request = client.get
    [request.response_header.status, request.response_header, request.response]
  end

  def get_proxy(options)
    options[:proxy] = {:type => 'http', :host => @upstream_proxy.host, :port => @upstream_proxy.port} if @upstream_proxy
  end

  def get_substituted_response(options)
    if options[:body]
      [200, {}, [options[:body]]]
    elsif options[:url]
      request_uri options[:url]
    end
  end

  def substitute(uri)
    @substitute_requests.each do |pattern, options|
      if Regexp.new(pattern) =~ uri
        return get_substituted_response(options)
      end
    end
    nil
  end

  def has_substitute?(uri)
    @substitute_requests.each do |pattern, options|
      if Regexp.new(pattern) =~ uri
        return true
      end
    end
    false
  end

  def substitute_request(pattern, options)
    @substitute_requests[pattern] = options
  end

  def track_request(pattern)
    @track_requests << pattern
  end

  def track(uri)
    @requests << uri
    @track_requests.each do |pattern|
      @requests << uri if Regexp.new(pattern) =~ uri
    end
  end

  def tracking_enabled?(uri)
    @track_requests.each do |pattern|
      return true if Regexp.new(pattern) =~ uri
    end
    false
  end
end
