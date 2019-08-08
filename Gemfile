source "https://rubygems.org"

gemspec

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group :test do
  gem "activesupport", "4.2.6"
  gem "chef", ">= 15.0.300"
  gem "chefstyle"
  gem "equivalent-xml", "~> 0.2.9"
  gem "guard-rspec"
  gem "knife-cloud", ">= 1.0.0"
  gem "mixlib-config", "~> 2.0"
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

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
