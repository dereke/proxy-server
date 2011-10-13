require_relative '../lib/proxy_manager'
require 'rest_client'
require 'json'


Thread.new do
 ProxyManager.run! :port => 4983
end

sleep 2

proxy = JSON.parse(RestClient.post 'http://localhost:4983/proxies', {})

sleep 2
RestClient.post "http://localhost:4983/proxies/#{proxy['port']}/requests", {:track => 'google.com'}


client = HTTPClient.new :proxy => "http://localhost:#{proxy['port']}"
client.get 'http://www.google.com'
client.get 'http://github.com'


p JSON.parse(HTTPClient.get("http://localhost:4983/proxies/#{proxy['port']}/requests").body)

