$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-azure/version'

Gem::Specification.new do |s|
  s.name = "knife-azure"
  s.version = Knife::Azure::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Barry Davis", "Chirag Jog"]
  s.date = "2012-06-06"
  s.summary = "A plugin to Opscode knife for creating instances on the Microsoft Azure platform"
  s.description = s.summary
  s.email = "oss@opscode.com"
  s.licenses = ["Apache 2.0"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
  s.homepage = "http://github.com/opscode/knife-azure"
  s.require_paths = ["lib"]
  s.add_dependency(%q<rake>, ["~> 0.9.2.2"])
  s.add_dependency(%q<chef>, [">= 0.10.0"])
  s.add_dependency(%q<rspec>, ["~> 2.8.0"])
  s.add_dependency(%q<rdoc>, ["~> 3.12"])
  s.add_dependency(%q<bundler>, [">= 0"])
  s.add_dependency(%q<guard-rspec>, [">= 0"])
  s.add_dependency(%q<rubygems-bundler>, ["~> 1.0.3"])
  s.add_dependency(%q<equivalent-xml>, ["~> 0.2.9"])
  s.add_dependency(%q<net-ssh>, [">= 2.0.3"])
  s.add_dependency(%q<net-ssh-multi>, [">= 1.0.1"])
  s.add_dependency(%q<net-scp>, ["~> 1.0.4"])
  s.add_dependency(%q<nokogiri>,["~> 1.5.5"])
  s.add_dependency(%q<knife-windows>,[">= 0"])
end
