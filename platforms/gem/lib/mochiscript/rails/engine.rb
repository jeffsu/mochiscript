require 'tilt'
require 'sprockets'
require 'sprockets/engines'

module Mochiscript::Rails
  class Engine < ::Rails::Engine
    config.before_configuration {}
  end

  #
  # Mochiscript template implementation. See:
  # http://github.com/jeffsu/mochiscript
  #
  class MochiscriptTemplate < Tilt::Template
    self.default_mime_type = 'application/javascript'

    def prepare
      @ctx = Mochiscript::Context.new
    end

    def evaluate(scope, locals, &block)
      return @ctx.parse(data)
    end
  end
end

module Sprockets
  register_engine '.ms', Mochiscript::Rails::MochiscriptTemplate
end
