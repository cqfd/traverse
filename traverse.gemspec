# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "traverse/version"

Gem::Specification.new do |s|
  s.name        = "traverse"
  s.version     = Traverse::VERSION
  s.authors     = ["happy4crazy"]
  s.email       = ["alan.m.odonnell@gmail.com"]
  s.homepage    = "https://github.com/happy4crazy/traverse"
  s.summary     = %q{Easily traverse an XML document.}
  s.description = %q{Easily traverse an XML document.}

  s.rubyforge_project = "traverse"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'nokogiri', '~> 1.5'
end
