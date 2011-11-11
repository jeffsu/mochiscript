module Mochiscript
  VERSION = "0.4.1".sub("-", '.')
end

require File.dirname(__FILE__) + '/mochiscript/core'
require File.dirname(__FILE__) + '/mochiscript/rails/engine' if defined?(::Rails)

