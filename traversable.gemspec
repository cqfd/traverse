# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "traversable/version"

Gem::Specification.new do |s|
  s.name        = "traversable"
  s.version     = Traversable::VERSION
  s.authors     = ["happy4crazy"]
  s.email       = ["alan.m.odonnell@gmail.com"]
  s.homepage    = "https://github.com/happy4crazy/traversable"
  s.summary     = %q{Easily traverse an XML document.}
  s.description = %q{Easily traverse an XML document.}

  s.rubyforge_project = "traversable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'nokogiri', '~> 1.5'
end
