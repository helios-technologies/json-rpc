Json Rpc
========

Implementation of [JSON RPC 2.0](http://groups.google.com/group/json-rpc/web/json-rpc-2-0) protocol.
It allows you to create easily json rpc server.

Usage
-----

Simple Rack example:

~~~~~~ {ruby}
require 'json-rpc'

class SyncApp
  include JsonRpc
  def call env
    result = rpc_call(env) { |e|
      logger.info "#{e}"
    }
    result
  end

  def rpc_sum a, b
    a + b
  end
end
run SyncApp.new
~~~~~~

Asynchronous Event Machine example:

~~~~~~ {ruby}
require 'json-rpc'

class AsyncApp
  include JsonRpc
  AsyncResponse = [-1, {}, []].freeze
  def call env
    result = rpc_call(env)
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
~~~~~~

Test it works:

~~~~~~ {sh}
$ thin -R example.ru -p 4242 -d start
$ curl "http://localhost:4242/rpc?jsonrpc=2.0&method=sum&params=%5B21%2C21%5D"
{"jsonrpc":"2.0","id":0,"result":42}
~~~~~~

### License
Copyright 2011 [Helios Technologies Ltd.](http://www.heliostech.hk)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
