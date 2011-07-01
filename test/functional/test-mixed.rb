require 'rpc-test'

module MixedTest
  def test_true
    call("true") { |obj|
      assert_equal true, obj["result"]
    }
  end

  def test_false
    call("false") { |obj|
      assert_equal false, obj["result"]
    }
  end

  def test_empty_array
    call("empty_array") { |obj|
      assert_equal [], obj["result"]
    }
  end

  def test_array
    call("array") { |obj|
      assert_equal [1,2,3], obj["result"]
    }
  end

  def test_hash
    call("hash") { |obj|
      exp_result = {
        "a" => "Apple",
        "b" => "Banana"
      }
      assert_equal exp_result, obj["result"]
    }
  end

  def test_repeat_one
    call("repeat", 42) { |obj|
      assert_equal [42], obj["result"]
    }
  end

  def test_repeat_two
    call("repeat", 21, 21) { |obj|
      assert_equal [21, 21], obj["result"]
    }
  end

  def test_repeat_hash
    call("repeat", "a" => "Apple", "b" => "Banana") { |obj|
      assert_equal(["a" => "Apple", "b" => "Banana"], obj["result"])
    }
  end
end

class SyncTest < RpcTest
  include MixedTest
end

class AsyncTest < RpcTest
  include MixedTest

  def test_cookies
    post_off = true
    call("set_cookie")
    call("get_cookie"){ |obj|
      assert_equal "Hello", obj["result"]
    }
    post_off = false
  end

end
