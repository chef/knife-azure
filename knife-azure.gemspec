# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-azure/version"

Gem::Specification.new do |s|
  s.name        = "knife-azure"
  s.version     = Knife::Azure::VERSION
  s.has_rdoc = true
  s.authors     = ["Barry Davis"]
  s.email       = ["barryd@jetstreamsoftware.com"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Azure Support for Chef's Knife Command"
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "chef", "~> 0.10"
  s.add_dependency "nokogiri"
  s.require_paths = ["lib"]

end
