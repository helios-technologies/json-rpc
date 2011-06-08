
require 'json'

module JsonRpc

  # Call the correct method for each query
  # The method should be prefixed by rpc_
  # If the method doesn't exists, an error will be return in JSON
  # More details in http://groups.google.com/group/json-rpc/web/json-rpc-2-0
  def dispatch env, &ecb
    begin
      request = Rpc::parse(env)
      status = Rpc::validate request
      result = Rpc::route(request, self)

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
      def initialize status, code, msg
        @status, @code, @msg = status, code, msg
      end
      def result
        # TODO: return as json string the error
      end
    end

    def self.error index
      Rpc::Error.new *ErrorProtocol[index]
    end

    def self.validate request
      # TODO: validate the json request
      200
    end

    def self.parse env
      # TODO return parsed request
      # Get from POST data or GET params
    end

    def self.route request, ctrl
      #TODO call ctrl.send("rpc_" + method)
      result = ctrl.rpc_sum(2, 3)
      if result.is_a? AsyncResult
        return result
      end
      forge_response result
    end

    def self.forge_response result
      result.to_json #TODO: Wrap result to json protocol
    end

    # The class RpcDeferrable is useful helps you to build a Json Rpc server
    # into an asynchronous way
    class AsyncResult
      include EventMachine::Deferrable

      def reply obj
        @callback.call(Rpc::forge_response(obj))
      end

      #FIXME thin specific
      def each &blk
        @callback = blk
      end
    end

  end
end
