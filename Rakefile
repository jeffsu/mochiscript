require 'bundler/gem_tasks'
require 'erb'

SRC_DIR = %|./js/src|
BOOT   = %W| class |
PARSER = %W| globals parser |

task :compile do
  @boot   = BOOT.collect { |f| `js2 render #{SRC_DIR}/#{f}.ms` }.join("\n")
  @parser = PARSER.collect { |f| `js2 render #{SRC_DIR}/#{f}.ms` }.join("\n")

  File.open("./js/platforms/node.js", "w") { |f| f << ERB.new(File.read(SRC_DIR + '/platforms/node.erb')).result(binding) }
end
