require 'bundler/gem_tasks'
require 'erb'

SRC_DIR = %|./js/src|
BOOT   = %W| class |
PARSER = %W| globals parser |

task :compile do
  @boot   = BOOT.collect { |f| `js2 render #{SRC_DIR}/#{f}.ms` }.join("\n")
  @parser = PARSER.collect { |f| `js2 render #{SRC_DIR}/#{f}.ms` }.join("\n")

  Dir['./js/src/platforms/*'].each do |f|
    target = f.sub(%r|/src|, '').sub(/\.erb$/, '')
    puts "Writing #{f} to #{target}"
    File.open(target, "w") { |t| t << ERB.new(File.read(f)).result(binding) }
  end
end

task :test => :compile do
  [ 'node' ].each do |platform|
    template = ERB.new File.read("./tests/platforms/#{platform}/test.erb")

    Dir['./tests/*.js'].each do |f|
      target = f.sub(%r|\./tests/|, "./tests/platforms/#{platform}/")
      @body = File.read(f)
      File.open(target, "w") { |f| f << template.result(binding) }
      sh "node #{target}"
    end
  end
end

task :run => [ :compile, :test ] do
end
