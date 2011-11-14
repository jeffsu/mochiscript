module Mochiscript
  VERSION = "0.4.3.pre2".sub("-", '.')
end

require File.dirname(__FILE__) + '/mochiscript/core'
require File.dirname(__FILE__) + '/mochiscript/rails/engine' if defined?(::Rails)

