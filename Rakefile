require 'erb'
require 'json'
require 'pp'

SRC_DIR = %|./src|
BOOT    = %W| class jsml |
PARSER  = %W| tokens parsers cli decorators |
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
        if ENV['VERBOSE']
          puts ctx.parse(File.read(f))
        end
      rescue Exception => e
        puts "ERROR:\n" + ctx.parse(File.read(f))
        puts "TREE:\n" + ctx.pp(File.read(f))
        puts e.to_s
      end
    end
  end

  desc "run all tests on node platform"
  task :node => :compile  do
    get_files.each do |f|
      puts "Testing: " + f
      unless system("./bin/ms-run #{f}")
        system("ERROR!!")
        system("./bin/ms-parse #{f}")
      end
    end
  end
end

desc "run all platforms' tests"
task :test => [ 'test:ruby', 'test:node' ]

desc "publish both gem and npm"
task :push => :compile do
  sh "cd ./platforms/gem; rm *.gem; gem build mochiscript.gemspec; gem push *.gem; "
  sh "cd ./platforms/npm; npm publish;"
end

desc "install gem"
task :install_gem => :compile do
  sh "cd ./platforms/gem; rm *.gem; gem build mochiscript.gemspec; gem install *.gem; "
end

desc "compile src to target"
task :compile do
  @boot   = BOOT.collect   { |f| parse("#{SRC_DIR}/#{f}.ms") }.join("\n")
  @parser = PARSER.collect { |f| parse("#{SRC_DIR}/#{f}.ms") }.join("\n")

  traverse_dir('./src/platforms') do |target|
    destination = target.sub(/^\.\/src(.*)\.erb$/, '.\1')
    puts "Compiling #{target}\n      --> #{destination}"
    File.open(destination, "w") { |t| t << ERB.new(File.read(target)).result(binding) }
  end
end

desc "copy over bootstrap"
task :bootstrap do
  [ './platforms/npm/lib/mochiscript/mochiscript.js' ].each do |f|
    sh "cp #{f} ./bootstrap/"
  end
end

def parse(file)
  `./bootstrap/ms-parse #{file}`
end

def traverse_dir(file_path)
  if File.directory? file_path
    Dir.foreach(file_path) do |file|
      if file!="." and file!=".."
        traverse_dir("#{file_path}/#{file}"){ |x| yield x }
      end
    end
  else
    yield file_path
  end
end
