# lovingly reused from selenium-webdriver

class PortProber
  def self.above(port)
    port += 1 until free? port
    port
  end

  def self.free?(port)
    TCPServer.new('localhost', port).close
    true
  rescue SocketError, Errno::EADDRINUSE
    false
  end
end
