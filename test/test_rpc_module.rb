require 'test/unit'
require 'rack/mock'
require 'json-rpc'
require 'uri'

class All < Test::Unit::TestCase
  include JsonRpc

  ReqSubtract = {"jsonrpc"=>"2.0", "method"=>"subtract", "params"=>[42, 23], "id"=>1}
  ReqSubtractString = JSON::dump(ReqSubtract)

  def test_post_parse
    opts = {
      :input => ReqSubtractString,
      :method => 'POST'
    }
    rs = Rpc::parse Rack::MockRequest.env_for("", opts)
    assert_equal ReqSubtract, rs
  end

  def test_get_parse
    opts = {:method => 'GET'}
    rs = Rpc::parse Rack::MockRequest.env_for("/?method=subtract&params=[42,23]&id=1&jsonrpc=2.0")
    assert_equal ReqSubtract, rs
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

  def test_response_forging
    assert_equal({"jsonrpc" => "2.0", "result" => 12, "id" => 7},
                 JSON.parse(Rpc::forge_response(12, 7)))
    assert_equal(nil, Rpc::forge_response(12))
  end
end
