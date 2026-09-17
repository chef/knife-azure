source "https://rubygems.org"

gemspec

group :test do
  gem "chefstyle"
  gem "rake"
  gem "rspec", ">= 3.0"
  gem "rspec_junit_formatter"
  # knife >= 19 no longer depends on chef directly; require it explicitly so
  # chef/knife (and chef/workstation_config_loader) can be loaded in specs.
  gem "chef", ">= 19.1"
end
