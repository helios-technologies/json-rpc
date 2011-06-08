# -*- RUBY -*-
$: << File::join(File::dirname(__FILE__), "..", "lib")
require 'json-rpc'

class SyncApp
  include JsonRpc

  def call env
    result = dispatch(env) { |e|
      logger.info "#{e} backtrace: #{e.backtrace.join "\n"}"
    }
    result
  end

  def rpc_sum a, b
    a + b
  end
end

run SyncApp.new
