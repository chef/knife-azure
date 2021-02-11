source "https://rubygems.org"

gemspec

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group :test do
  # until we remove support for Ruby 2.5
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "< 15.0"
  end
  gem "activesupport", "6.1.2.1"
  gem "chefstyle"
  gem "equivalent-xml", "~> 0.6.0"
  gem "guard-rspec"
  gem "knife-cloud", ">= 1.0.0"
  gem "mixlib-config", ">= 3.0", "< 5"
  gem "mixlib-shellout"
  gem "rake"
  gem "rb-readline"
  gem "rspec", ">= 3.0"
  gem "rspec_junit_formatter"
end

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end
