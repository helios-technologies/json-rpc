require 'json'
require 'eventmachine'
require 'uri'

module JsonRpc

  # Call the correct method for each query
  # The method should be prefixed by rpc_
  # If the method doesn't exists, an error will be return in JSON
  # More details in http://groups.google.com/group/json-rpc/web/json-rpc-2-0
  def dispatch env, &ecb
    begin
      request = Rpc::parse env
      status = Rpc::validate request
      result = Rpc::route request, self

    rescue Rpc::Error => e
      status = e.status
      result = e.result
      ecb.call(e) if ecb
    end

    [status, {'Content-Type' => Rpc::ContentType}, result]
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
      attr_accessor :id
      def initialize status, code, msg
        @status, @code, @msg = status, code, msg
      end
      def result
        res = {"jsonrpc" => "2.0", "id" => id,
          "error" => {"code" => code, "message" => message}
        }
        res.delete_if { |k, v| v == nil}
        res.to_json
      end
    end

    def self.error index, id
      id = nil unless id.is_a? Fixnum
      ex = Rpc::Error.new *ErrorProtocol[index]
      ex.id = id
    end

    def self.validate request
      return 200 if request["jsonrpc"] == Version and
        request["method"].kind_of?(String) and
        request["method"] != "" and
        (request["id"] == nil or request["id"].is_a?(Fixnum))
      raise error :invalid_request, request["id"]
    end

    def self.parse env
      begin
        JSON.parse case env["REQUEST_METHOD"]
                   when "POST" then env["rack.input"].read
                   when "GET" then URI.decode(env["QUERY_STRING"])
                   end
      rescue JSON::ParserError
        raise error :parse_error
      end
    end

    def self.route request, ctrl
      method, params = Prefix + request["method"], request["params"]

      unless ctrl.respond_to? method
        raise error :method_not_found, request["id"]
      result = ctrl.send()
      if result.is_a? AsyncResult
        result.id = request["id"]
        return result
      end
      forge_response result, request["id"]

    end

    def self.forge_response result, id = nil
      return nil if id == nil
      {"jsonrpc" => "2.0", "id" => id, "result" => result}.to_json
    end

    # The class RpcDeferrable is useful helps you to build a Json Rpc server
    # into an asynchronous way
    class AsyncResult
      include EventMachine::Deferrable

      attr_reader :response
      attr_accessor :id

      def reply obj
        @callback.call(Rpc::forge_response(obj, @id))
      end

      #FIXME thin specific
      def each &blk
        @callback = blk
      end
    end

  end
end