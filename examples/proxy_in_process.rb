require 'rubygems'
require 'proxy-server'
require 'rest_client' # you will need to install this via gem install rest-client / bundler etc
require 'json'

ENV.clear

Thread.new do
 ProxyManager.run! :port => 4983
end

until_proxy_is_running = 2
sleep until_proxy_is_running # need to implement the ability to wait for the proxy to be running

proxy = JSON.parse(RestClient.post 'http://localhost:4983/proxies', {:proxy => 'http://www-cache.reith.bbc.co.uk:80'})

sleep until_proxy_is_running

RestClient.post "http://localhost:4983/proxies/#{proxy['port']}/requests", {:track => 'google.com'}

client = HTTPClient.new :proxy => "http://localhost:#{proxy['port']}"
client.get 'http://www.google.com'
client.get 'http://github.com'

p JSON.parse(HTTPClient.get("http://localhost:4983/proxies/#{proxy['port']}/requests").body)



