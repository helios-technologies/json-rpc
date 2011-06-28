require 'test/unit'
require 'net/http'
require 'uri'
require 'cgi'
require 'json'
require 'pp'


class RpcTest < Test::Unit::TestCase

  def initialize *args
    @rpc_path = self.is_a?(SyncTest) ? '/rpc-sync' : '/rpc-async'
    @rpc_url = URI.parse('http://localhost:4242')
    super *args
  end

  def call method_rpc, *params, &blk
    if blk
      [:get, :post].each do |method_http|
        blk.call rpc_call(method_http, method_rpc, *params)
      end
    else
      rpc_call :get, method_rpc, *params
    end
  end

  private
  def rpc_call method_http, method_rpc, *params
    rpc_request =  {
      :jsonrpc => "2.0",
      :method => method_rpc,
      :params => params,
    }

    res = Net::HTTP.start(@rpc_url.host, @rpc_url.port) do |http|
      case method_http
      when :get
        rpc_request[:params] = CGI::escape(rpc_request[:params].to_json)
        http.get @rpc_path + "?" + rpc_request.map{|a,b| "#{a}=#{b}"}.join("&")
      when :post
        req = Net::HTTP::Post.new(@rpc_path)
        req.body = rpc_request.to_json
        http.request(req)
        else
        raise "Unknown HTTP method #{method_http}"
      end
    end

    JSON::parse(res.body)
  end
end
