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
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply a + b
      result.succeed
    end
    result
  end

  def rpc_true
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply true
      result.succeed
    end
    result
  end

  def rpc_false
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply false
      result.succeed
    end
    result
  end

  def rpc_array
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply [1,2,3]
      result.succeed
    end
    result
  end

  def rpc_empty_array
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply []
      result.succeed
    end
    result
  end

  def rpc_hash
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply("a" => "Apple", "b" => "Banana")
      result.succeed
    end
    result
  end

  def rpc_repeat *params
    result = Rpc::AsyncResult.new
    EventMachine::next_tick do
      result.reply params
      result.succeed
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

