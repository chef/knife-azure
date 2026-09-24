source "https://rubygems.org"

gemspec

# Ruby 3.4 emits a deprecation warning when these default gems are loaded
# implicitly (they're slated for removal from Ruby's default gems in 4.0).
# They're pulled in transitively by chef/ohai's Windows-specific code
# (wmi-lite, win32/registry) and are Windows-only APIs, so declaring them
# explicitly here (scoped to Windows platforms) silences the warning without
# affecting non-Windows installs, where Bundler simply skips them.
gem "win32ole", platforms: %i{mingw x64_mingw mswin}
gem "fiddle", platforms: %i{mingw x64_mingw mswin}

group :test do
  gem "chefstyle"
  gem "rake"
  gem "rspec", ">= 3.0"
  gem "rspec_junit_formatter"
end
