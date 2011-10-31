# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "./lib/mochiscript"

Gem::Specification.new do |s|
  s.name        = "mochiscript"
  s.version     = Mochiscript::VERSION
  s.authors     = ["Jeff Su"]
  s.email       = ["me@jeffsu.com"]
  s.homepage    = ""
  s.summary     = %q{Javascript Dessert}
  s.description = %q{Javascript Dessert}

  s.rubyforge_project = "mochiscript"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_dependency 'therubyracer'
  s.add_dependency 'json'
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
