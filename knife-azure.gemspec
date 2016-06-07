$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-azure/version'

Gem::Specification.new do |s|
  s.name = "knife-azure"
  s.version = Knife::Azure::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Barry Davis", "Chirag Jog"]
  s.summary = "A plugin to the Chef knife tool for creating instances on the Microsoft Azure platform"
  s.description = s.summary
  s.email = "oss@chef.io"
  s.licenses = ["Apache 2.0"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = %w(LICENSE README.md) + Dir.glob("lib/**/*")
  s.homepage = "https://github.com/chef/knife-azure"
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri", ">= 1.5.5"
  s.add_dependency "knife-windows", "~> 1.0"
  s.add_dependency "azure_mgmt_resources", "0.2.1"
  s.add_dependency "azure_mgmt_compute", "0.2.1"
  s.add_dependency "azure_mgmt_storage", "0.2.1"
  s.add_dependency "azure_mgmt_network", "0.2.1"
  s.add_dependency "listen", "3.0.6"
  s.add_dependency "ffi"
  s.add_development_dependency 'chef',  '~> 12.0', '>= 12.2.1'
  s.add_development_dependency "mixlib-config", "~> 2.0"
  s.add_development_dependency "equivalent-xml", "~> 0.2.9"
  s.add_development_dependency "knife-cloud", ">= 1.0.0"
end
