require 'sprockets'

class Engine < ::Rails::Engine
end

module Sprockets
  register_engine '.ms', Mochiscript::Tilt::Template
end
