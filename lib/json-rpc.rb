require 'json'
require 'eventmachine'
require 'uri'

module JsonRpc

  # Call the correct method for each query
  # The method should be prefixed by rpc_
  # If the method doesn't exists, an error will be return in JSON
  # More details in http://groups.google.com/group/json-rpc/web/json-rpc-2-0
  def rpc_call env, &ecb
    begin
      request = Rpc::parse env
      status = Rpc::validate request
      result = Rpc::route request, self
    rescue Exception, Rpc::Error => e
      ecb.call(e) if ecb
     unless e.is_a?(Rpc::Error)
        e = Rpc::error :internal_error
      end
      status = e.status
      result = e.result
    end

    header = {'Content-Type' => Rpc::ContentType}

    if result.is_a?(Rpc::AsyncResult)
      result.env = env
      result.status = status
      result.header = header
      return [-1, {}, result]
    end

    [status, header, result]
  end

  module Rpc
    Version = "2.0".freeze
    Prefix = "rpc_".freeze
    ContentType = "application/json".freeze

    ErrorProtocol = {
      :parse_error      => [500, -32700, "Parse error"],
      :invalid_request  => [400, -32600, "Invalid Request"],
      :method_not_found => [404, -32601, "Method not found"],
      :invalid_params   => [500, -32602, "Invalid params"],
      :internal_error   => [500, -32603, "Internal error"],
    }

    class Error < RuntimeError
      attr_reader :status, :code, :msg
      attr_accessor :id, :msg_debug
      def initialize status, code, msg, msg_debug = nil
        @status, @code, @msg, @msg_debug = status, code, msg, msg_debug
      end
      def result
        res = {
          "id" => id,
          "jsonrpc" => Version,
          "error" => {
            "code" => code,
            "message" => msg
          }
        }
        res.delete_if { |k, v| v == nil }
        res.to_json
      end
      def to_s
        msg_debug || super
      end
    end

    def self.error index, id = nil, debug_msg = nil
      id = nil unless id.is_a? Fixnum
      ex = Rpc::Error.new *ErrorProtocol[index], debug_msg
      ex.id = id
      ex
    end

    def self.validate request
      return 200 if request["jsonrpc"] == Version and
        request["method"].kind_of?(String) and
        request["method"] != ""
      raise error :invalid_request, request["id"], "invalid request: #{request.inspect}"
    end

    def self.parse env
      begin
        case env["REQUEST_METHOD"]
        when "POST"
          JSON.parse(env["rack.input"].read)
        when /^(GET|HEAD)$/
          req = Rack::Request.new(env)
          obj = req.params
          obj["id"] = obj["id"].to_i
          obj["params"] = obj["params"] ? JSON::parse(obj["params"]) : []
          obj
        else
          raise error :invalid_request, nil, "unsupported method #{env["REQUEST_METHOD"]} params: #{obj.inspect}"
        end

      rescue JSON::ParserError => e
        raise error :parse_error, nil, "JSON parsing error: #{e}"
      end
    end

    def self.route request, ctrl
      method, params = Prefix + request["method"], request["params"]

      unless ctrl.respond_to? method
        raise error :method_not_found, request["id"], "method `#{method}` not found"
      end

      result = ctrl.send(method, *params)
      if result.is_a? AsyncResult
        result.id = request["id"]
        return result
      end
      forge_response result, request["id"]
    end

    def self.forge_response result, id = nil
      {"jsonrpc" => Version, "id" => id.to_i, "result" => result}.to_json
    end

    # The class RpcDeferrable is useful helps you to build a Json Rpc server
    # into an asynchronous way
    class AsyncResult
      include EventMachine::Deferrable

      attr_reader :response
      attr_accessor :id, :status, :header, :env

      def initialize env = nil
        @env = env
        @status = 200
        @header = {}
        @header_sent = false
      end

      def send_header
        raise "You should pass env to AsyncResult.new()" unless @env
        @env['async.callback'].call([@status, @header, self]) unless @header_sent
        @header_sent = true
      end

      def reply obj
        send_header unless @callback
        @callback.call(Rpc::forge_response(obj, @id))
      end

      def failed error_code = :internal_error, msg = nil
        e = Rpc::error(error_code, id, msg)
        @status = e.status
        send_header
        @callback.call(e.result)
        succeed
      end

      #FIXME thin specific
      def each &blk
        @callback = blk
      end
    end

  end
end
