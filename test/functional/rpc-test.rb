require 'test/unit'
require 'mechanize'
require 'json'
require 'pp'
require 'cgi'

class RpcTest < Test::Unit::TestCase

  attr_reader :session

  def initialize *args
    @rpc_path = self.is_a?(SyncTest) ? '/rpc-sync' : '/rpc-async'
    @rpc_url = 'http://localhost:4242'
    @get_off = @post_off = false
    new_session
    super *args
  end

  attr_accessor :post_off, :get_off

  def call method_rpc, *params, &blk
    types = []
    types.push :get unless @get_off
    types.push :post unless @post_off
    if blk
      types.each do |method_http|
        blk.call rpc_call(method_http, method_rpc, *params)
      end
    else
      rpc_call :get, method_rpc, *params
    end
  end

  def new_session session = nil
    session = Mechanize.new unless session
    priv_session = @session
    @session = session
    priv_session
  end

  private
  def rpc_call method_http, method_rpc, *params
    rpc_request =  {
      :jsonrpc => "2.0",
      :method => method_rpc,
      :params => params,
    }

    case method_http
    when :get
      #rpc_request[:params] = CGI::escape(rpc_request[:params].to_json)
      #http.get @rpc_path + "?" + rpc_request.map{|a,b| "#{a}=#{b}"}.join("&")
      rpc_request[:params] = rpc_request[:params].to_json
      res = @session.get(@rpc_url + @rpc_path, rpc_request)
    when :post
      res = @session.post(@rpc_url + @rpc_path, rpc_request.to_json)
       # req = Net::HTTP::Post.new(@rpc_path)
       # req.body = rpc_request.to_json
       # http.request(req)
    else
      raise "Unknown HTTP method #{method_http}"
    end

    JSON::parse(res.body)
  end
end
