require 'haml'

module Haml::Filters::Mochiscript
  include ::Haml::Filters::Base

  def render(text)
    ctx = Mochiscript::Context.new
    <<END
<script type="text/javascript">
  //<![CDATA[
    #{ctx.parse(text)}
  //]]>
</script>
END
  end
end
