$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-azure/version'

Gem::Specification.new do |s|
  s.name = "knife-azure"
  s.version = Knife::Azure::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Barry Davis"]
  s.date = "2012-06-06"
  s.summary = "A plugin to Opscode knife for creating instances on the Microsoft Azure platform"
  s.description = s.summary
  s.email = "oss@opscode.com"
  s.licenses = ["Apache 2.0"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = [
    "Gemfile",
    "Guardfile",
    "LICENSE",
    "Rakefile",
    "knife-azure.gemspec",
    "lib/azure/connection.rb",
    "lib/azure/deploy.rb",
    "lib/azure/disk.rb",
    "lib/azure/host.rb",
    "lib/azure/image.rb",
    "lib/azure/rest.rb",
    "lib/azure/role.rb",
    "lib/azure/utility.rb",
    "lib/chef/knife/azure_base.rb",
    "lib/chef/knife/azure_image_list.rb",
    "lib/chef/knife/azure_server_create.rb",
    "lib/chef/knife/azure_server_delete.rb",
    "lib/chef/knife/azure_server_describe.rb",
    "lib/chef/knife/azure_server_list.rb",
    "lib/knife-azure/version.rb",
    "readme.rdoc",
    "spec/functional/deploys_test.rb",
    "spec/functional/host_test.rb",
    "spec/functional/images_list_test.rb",
    "spec/functional/role_test.rb",
    "spec/integration/role_lifecycle_test.rb",
    "spec/spec_helper.rb",
    "spec/unit/assets/create_deployment.xml",
    "spec/unit/assets/create_deployment_in_progress.xml",
    "spec/unit/assets/create_host.xml",
    "spec/unit/assets/create_role.xml",
    "spec/unit/assets/list_deployments_for_service000.xml",
    "spec/unit/assets/list_deployments_for_service001.xml",
    "spec/unit/assets/list_deployments_for_service002.xml",
    "spec/unit/assets/list_deployments_for_service003.xml",
    "spec/unit/assets/list_disks.xml",
    "spec/unit/assets/list_hosts.xml",
    "spec/unit/assets/list_images.xml",
    "spec/unit/assets/post_success.xml",
    "spec/unit/deploys_list_spec.rb",
    "spec/unit/disks_spec.rb",
    "spec/unit/hosts_spec.rb",
    "spec/unit/images_spec.rb",
    "spec/unit/query_azure_mock.rb",
    "spec/unit/roles_create_spec.rb",
    "spec/unit/roles_list_spec.rb"
  ]
  s.homepage = "http://github.com/opscode/knife-azure"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<knife-azure>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<libnotify>, [">= 0"])
      s.add_development_dependency(%q<rubygems-bundler>, ["~> 0.2.8"])
      s.add_development_dependency(%q<interactive_editor>, [">= 0"])
      s.add_development_dependency(%q<equivalent-xml>, ["~> 0.2.9"])
    else
      s.add_dependency(%q<knife-azure>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<libnotify>, [">= 0"])
      s.add_dependency(%q<rubygems-bundler>, ["~> 0.2.8"])
      s.add_dependency(%q<interactive_editor>, [">= 0"])
      s.add_dependency(%q<equivalent-xml>, ["~> 0.2.9"])
    end
  else
    s.add_dependency(%q<knife-azure>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.8.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<libnotify>, [">= 0"])
    s.add_dependency(%q<rubygems-bundler>, ["~> 0.2.8"])
    s.add_dependency(%q<interactive_editor>, [">= 0"])
    s.add_dependency(%q<equivalent-xml>, ["~> 0.2.9"])
  end
end

