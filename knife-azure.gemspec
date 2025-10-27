$:.unshift(File.dirname(__FILE__) + "/lib")
require "knife-azure/version"

Gem::Specification.new do |s|
  s.name = "knife-azure"
  s.version = Knife::Azure::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Barry Davis", "Chirag Jog"]
  s.summary = "A plugin to the Chef Infra knife tool for creating instances on the Microsoft Azure platform"
  s.description = s.summary
  s.email = "oss@chef.io"
  s.licenses = ["Apache 2.0"]
  s.extra_rdoc_files = [
    "LICENSE",
  ]
  s.files = %w{LICENSE} + Dir.glob("lib/**/*")
  s.homepage = "https://github.com/chef/knife-azure"
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.1"

  s.add_dependency "knife", ">= 18.0"
  s.add_dependency "nokogiri", ">= 1.5.5"
  s.add_dependency "azure_mgmt_compute", "~> 0.18", ">= 0.18.3"
  s.add_dependency "azure_mgmt_storage", "~> 0.20", ">= 0.20.0"
  s.add_dependency "azure_mgmt_network2", "~> 1.0.1", ">= 1.0.1"
  s.add_dependency "azure_mgmt_resources2", "~> 1.0.1", ">= 1.0.1"
  s.add_dependency "listen", "~> 3.1"
  s.add_dependency "ipaddress"
  s.add_dependency "ffi"
  s.add_dependency "rb-readline"
  s.add_dependency "abbrev"
end
