require File.dirname(__FILE__) + '/mochiscript/version'
require File.dirname(__FILE__) + '/mochiscript/core'

if defined?(::Sinatra)
  require File.dirname(__FILE__) + '/mochiscript/tilt/template'
  require File.dirname(__FILE__) + '/mochiscript/sinatra/templates'
elsif defined?(::Rails)
  require File.dirname(__FILE__) + '/mochiscript/tilt/template'
  require File.dirname(__FILE__) + '/mochiscript/rails/engine'
end
