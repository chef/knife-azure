$:.unshift(File.dirname(__FILE__) + "/lib")
require "knife-azure/version"

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
    "LICENSE",
  ]
  s.files = %w{LICENSE} + Dir.glob("lib/**/*")
  s.homepage = "https://github.com/chef/knife-azure"
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.5"

  s.add_dependency "chef", ">= 15.1"
  s.add_dependency "chef-bin", ">= 15.1"
  s.add_dependency "nokogiri", ">= 1.5.5"
  s.add_dependency "azure_mgmt_resources", "~> 0.17", ">= 0.17.2"
  s.add_dependency "azure_mgmt_compute", "~> 0.18", ">= 0.18.3"
  s.add_dependency "azure_mgmt_storage", "~> 0.17", ">= 0.17.3"
  s.add_dependency "azure_mgmt_network", "~> 0.18", ">= 0.18.2"
  s.add_dependency "listen", "~> 3.1"
  s.add_dependency "ipaddress"
  s.add_dependency "ffi"
end
