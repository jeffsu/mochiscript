require 'erb'
require 'json'
require 'pp'

SRC_DIR = %|./src|
BOOT    = %W| class jsml |
PARSER  = %W| tokens parsers cli |
VERSION = File.read("./VERSION").strip;

namespace :test do
  def get_files
    ENV['TEST'] ? [ "./tests/#{ENV['TEST']}.ms" ] : Dir['./tests/*.ms']
  end

  desc "run all tests on ruby platform"
  task :ruby => :compile  do
    require "./platforms/gem/lib/mochiscript"

    get_files.each do |f|
      puts "Testing: " + f
      ctx = Mochiscript::Context.new
      begin
        ctx.eval_ms(File.read(f))
      rescue Exception => e
        puts "Error: " + ctx.parse(File.read(f))
        puts "TREE:\n" + ctx.pp(File.read(f))
        puts e.to_s
      end
    end
  end

  desc "run all tests on node platform"
  task :node => :compile  do
    require "./platforms/gem/lib/mochiscript"

    get_files.each do |f|
      puts "Testing: " + f
      unless system("./bin/ms-run #{f}")
        system("./bin/ms-parse #{f}")
      end
    end
  end
end

desc "run all platforms' tests"
task :test => [ 'test:ruby', 'test:node' ]

desc "publich both gem and npm"
task :push => :compile do
  sh "cd ./platforms/gem; rm *.gem; gem build mochiscript.gemspec; gem push *.gem; "
  sh "cd ./platforms/npm; npm publish;"
end

desc "compile src to target"
task :compile do
  @boot   = BOOT.collect { |f| parse("#{SRC_DIR}/#{f}.ms") }.join("\n")
  @parser = PARSER.collect { |f| parse("#{SRC_DIR}/#{f}.ms") }.join("\n")

  {
    # gem
    'boot.js.erb'        => './platforms/gem/vendor/assets/javascripts/mochiscript.js',
    'core.rb.erb'        => './platforms/gem/lib/mochiscript/core.rb',
    'mochiscript.rb.erb' => './platforms/gem/lib/mochiscript.rb',

    # npm
    'node.js.erb'      => './platforms/npm/lib/mochiscript/mochiscript.js',
    'package.json.erb' => './platforms/npm/package.json'
  }.each_pair do |target, destination|
    target = "./src/platforms/#{target}"
    puts "Writing #{target} to #{destination}"
    File.open(destination, "w") { |t| t << ERB.new(File.read(target)).result(binding) }
  end
end

def parse(file)
  `./bin/ms-parse #{file}`
end
