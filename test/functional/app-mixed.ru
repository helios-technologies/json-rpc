require 'pp'
$: << File::join(File::dirname(__FILE__), "../../")
require 'lib/json-rpc'

class SimpleApp
  include JsonRpc
  alias :call :rpc_call

  def rpc_sum a, b
    a + b
  end

  def rpc_true
    true
  end

  def rpc_false
    false
  end

  def rpc_array
    [1,2,3]
  end

  def rpc_empty_array
    []
  end

  def rpc_hash
    {
      "a" => "Apple",
      "b" => "Banana"
    }
  end

  def rpc_repeat *params
    params
  end

end

class AsyncApp
  include JsonRpc
  alias :call :rpc_call

  def rpc_sum a, b
    wrap_async do
      a + b
    end
  end

  def rpc_true
    wrap_async do
      true
    end
  end

  def rpc_false
    wrap_async do
      false
    end
  end

  def rpc_array
    wrap_async do
      [1,2,3]
    end
  end

  def rpc_empty_array
    wrap_async do
      []
    end
  end

  def rpc_hash
    wrap_async do
      {"a" => "Apple", "b" => "Banana"}
    end
  end

  def rpc_repeat *params
    wrap_async do
      params
    end
  end

  private

  def wrap_async &block
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      e = catch(:Error) {
        result.reply block.call result
        result.succeed
        nil
      }
      result.failed e[:code], e[:msg] if e
    end
    result
  end
end

map '/rpc-sync' do
  run SimpleApp.new
end

map '/rpc-async' do
  run AsyncApp.new
end

