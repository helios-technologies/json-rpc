require 'test/unit'
require 'rack/mock'
require 'json-rpc'
require 'uri'

class All < Test::Unit::TestCase
  include JsonRpc

  def test_get_post_parse
    req_string = '{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}'

    # POST REQUEST
    req_hash = JSON.parse req_string
    opts = {:input => req_string,
      :method => 'POST'
    }
    rs = Rpc::parse Rack::MockRequest.env_for("", opts)

    # GET REQUEST
    assert_equal req_hash, rs
    opts = {:method => 'GET'}
    rs = Rpc::parse Rack::MockRequest.env_for("/?"+URI.encode(req_string), opts)
    assert_equal req_hash, rs
  end

  def test_invalid_json_post_parse
    req_string = '{"jsonrpc": "2.0", "method": "subtract", "params": [42, 2'

    # POST REQUEST
    opts = {:input => req_string,
      :method => 'POST'
    }
    assert_raise(Rpc::Error) {
      rs = Rpc::parse Rack::MockRequest.env_for("", opts)
    }
  end

  def test_validate
    req_hash = { "jsonrpc" => "2.0", "method" => "s", "params" => 1, "id" => 22 }
    assert_nothing_raised {
      Rpc::validate req_hash
    }
    req_hash = { "method" => "s", "params" => 1, "id" => 22 }
    assert_raise(Rpc::Error) {
      Rpc::validate req_hash
    }
    req_hash = { "jsonrpc" => "2.0", "method" => "s", "params" => 1, "id" => "22" }
    assert_raise(Rpc::Error) {
      Rpc::validate req_hash
    }
  end

  
end
