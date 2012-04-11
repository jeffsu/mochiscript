module Sinatra
  module Templates
    def mochiscript(template, options={}, locals={})
      options.merge! :layout => false, :default_content_type => :js
      render :ms, template, options, locals
    end
  end
end
