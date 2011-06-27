Gem::Specification.new do |s|
  s.name              = 'json-rpc'
  s.version           = '0.1.4'
  s.summary           = "JSON RPC 2.0 library for rack applications"
  s.description       = "Implementation of JSON RPC 2.0 protocol. It allows you to create easily a json rpc server in pure Rack, in Rails, or asynchronous using Thin and EventMachine."
  s.authors           = ["Helios Technologies Ltd."]
  s.email             = 'contact@heliostech.hk'
  s.files             = Dir.glob("{lib,test,example}/**/**") + %w(README.md)
  s.homepage          = 'https://github.com/helios-technologies/json-rpc'
  s.rubyforge_project = "[none]"
end
