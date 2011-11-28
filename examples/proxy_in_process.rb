require '../lib/proxy-server'
require 'rest_client' # you will need to install this via gem install rest-client / bundler etc
require 'httpclient'
require 'json'

Thread.abort_on_exception=true
Thread.new do
  ProxyManager.start :port => 4983
end

until_proxy_is_running = 3
sleep until_proxy_is_running # need to implement the ability to wait for the proxy to be running

proxy = JSON.parse(RestClient.post 'http://localhost:4983/proxies', {})

RestClient.post "http://localhost:4983/proxies/#{proxy['port']}/requests", {:track => 'google.com'}

client = HTTPClient.new :proxy => "http://localhost:#{proxy['port']}"
client.get 'http://www.google.com'
client.get 'http://github.com'

p JSON.parse(HTTPClient.get("http://localhost:4983/proxies/#{proxy['port']}/requests").body)
