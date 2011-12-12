require_relative './proxy_server'
require_relative './port_prober'

class ProxyManager
  START_PORT = 5000

  attr_reader :running_proxy_servers, :assigned_proxy_ports

  def initialize
    @running_proxy_servers = {}
    @assigned_proxy_ports = []
  end

  def get_proxy(port)
    running_proxy_servers[port]
  end

  def stop_proxy(port)
    proxy_server = running_proxy_servers[port]
    proxy_server.stop
    running_proxy_servers.delete proxy_server
  end

  def delete_proxies
    assigned_proxy_ports.clear
  end

  def proxies
    assigned_proxy_ports
  end

  def start_proxy(options)
    proxy_server = ProxyServer.new(options)
    proxy_server.start
    running_proxy_servers[options[:port]] = proxy_server
  end

  def new_proxy
    port = find_proxy_port
    assigned_proxy_ports << port
    URI.parse("http://#{proxy_host_address}:#{port}")
  end

  def proxy_host_address
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

  def find_proxy_port
    new_proxy_port = (assigned_proxy_ports.max || ProxyManager::START_PORT) + 1
    PortProber.above(new_proxy_port)
  end
end