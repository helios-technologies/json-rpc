# -*- RUBY -*-
$: << File::join(File::dirname(__FILE__), "..", "lib")
require 'json-rpc'

class AsyncApp
  include JsonRpc

  AsyncResponse = [-1, {}, []].freeze

  def call env
    result = dispatch(env) { |e|
      puts "#{e} backtrace: #{e.backtrace.join "\n"}"
    }
    env['async.callback'].call result
    AsyncResponse
  end

  def rpc_sum a, b
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply a + b
      result.succeed
    end
    result
  end
end

run AsyncApp.new
