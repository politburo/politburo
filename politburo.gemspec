# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "politburo/version"

Gem::Specification.new do |s|
  s.name        = "politburo"
  s.version     = Politburo::VERSION
  s.authors     = ["Robert Postill", "Tal Rotbart"]
  s.email       = ["robert.postill@googlemail.com", "redbeard@gmail.com"]
  s.homepage    = "https://github.com/redbeard/politburo#readme"
  s.summary     = "Politburo - The Babushka wielding DevOps orchestrator"
  s.description = "Politburo is a tool to orchestrate launching entire environments described in a simple DSL, using Babushka recipes."

  s.rubyforge_project = "politburo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.8"
  # s.add_runtime_dependency "rest-client"
  # s.add_runtime_dependency "json"
  s.add_runtime_dependency "trollop"
end
