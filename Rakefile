# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
GEM_NAME = "knife-azure"

spec = eval(File.read("knife-azure.gemspec"))

require 'rubygems/package_task'

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/unit/**/*_spec.rb']
  touch "AzureLinuxCert.pem"
end

RSpec::Core::RakeTask.new(:functional) do |spec|
  spec.pattern = FileList['spec/functional/**/*_test.rb']
end

RSpec::Core::RakeTask.new(:integration) do |spec|
  spec.pattern = FileList['spec/integration/**/*_test.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{Knife::Azure::VERSION} --no-rdoc --no-ri}
end 

task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{Knife::Azure::VERSION} }
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "knife-azure #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
