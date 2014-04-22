$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-azure/version'

Gem::Specification.new do |s|
  s.name = "knife-azure"
  s.version = Knife::Azure::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Barry Davis", "Chirag Jog"]
  s.summary = "A plugin to the Chef knife tool for creating instances on the Microsoft Azure platform"
  s.description = s.summary
  s.email = "oss@getchef.com"
  s.licenses = ["Apache 2.0"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = %w(LICENSE README.md) + Dir.glob("lib/**/*")
  s.homepage = "http://github.com/opscode/knife-azure"
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri", ">= 1.5.5"
  s.add_dependency "knife-windows", ">= 0.5.14"

  s.add_development_dependency "chef", ">= 11.8.2"
  s.add_development_dependency "mixlib-config", "~> 2.0"
  s.add_development_dependency "equivalent-xml", "~> 0.2.9"
end
