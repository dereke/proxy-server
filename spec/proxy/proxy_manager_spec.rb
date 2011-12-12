require_relative '../spec_helper'
require_relative '../../lib/proxy/proxy_manager'
require 'rack/test'

describe ProxyManager do
  it "creates a new proxy" do
    pm = ProxyManager.new

    pm.should_receive(:find_proxy_port).and_return(4000)
    pm.should_receive(:proxy_host_address).and_return('127.0.0.1')

    pm.new_proxy.should == URI.parse("http://127.0.0.1:4000")
  end

  it "finds the address of this machine" do
    expected_address = `ifconfig`.scan(/inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})  Bcast:/)[0][0]
    pm = ProxyManager.new
    pm.proxy_host_address.should == expected_address
  end
end