require 'bundler/gem_tasks'
require 'erb'
require 'json'

SRC_DIR = %|./js/src|
BOOT   = %W| class |
PARSER = %W| globals tokens parser |

task :test => :compile do
  require "./js/platforms/ruby"

  Dir['./tests/*.ms'].each do |f|
    puts "Testing: " + f
    ctx = MochiScript::Context.new
    ctx.eval_ms(File.read(f))
  end
end

task :compile do
  @boot   = BOOT.collect { |f| `js2-node render #{SRC_DIR}/#{f}.ms` }.join("\n")
  @parser = PARSER.collect { |f| `js2-node render #{SRC_DIR}/#{f}.ms` }.join("\n")

  Dir['./js/src/platforms/*.erb'].each do |f|
    target = f.sub(%r|/src|, '').sub(/\.erb$/, '')
    puts "Writing #{f} to #{target}"
    File.open(target, "w") { |t| t << ERB.new(File.read(f)).result(binding) }
  end
end

