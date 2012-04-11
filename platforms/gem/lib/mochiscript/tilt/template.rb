require 'tilt'

module Mochiscript::Tilt
  class Template < Tilt::Template
    self.default_mime_type = 'application/javascript'

    def prepare
      @ctx = Mochiscript::Context.new
    end

    def evaluate(scope, locals, &block)
      return @ctx.parse(data)
    end
  end
end

module Tilt
  register Mochiscript::Tilt::Template, 'ms'
end
