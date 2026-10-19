#!/usr/bin/env ruby
# Reads test/e2e/config.yml (linux/windows sections) for run_tests.sh.
#
#   cfg.rb <config.yml> <linux|windows> get <key>        # print one value
#   cfg.rb <config.yml> <linux|windows> flags create     # knife flags, one per line
#   cfg.rb <config.yml> <linux|windows> flags group      # flags for show/list/delete
#   cfg.rb <config.yml> check                            # exit 1 if placeholders/sections missing
require "yaml"

AZURE_PREFIXED = %w{resource-group-name vm-name service-location vm-size}.freeze

def azure_prefixed?(key)
  AZURE_PREFIXED.include?(key) || key.start_with?("image-reference-")
end

def flag_lines(key, value)
  return [] if value.nil? || value.to_s.strip.empty?

  case key
  when "confirm"
    value == true ? ["--yes"] : []
  when "node-verify-api-cert"
    [value ? "--node-verify-api-cert" : "--no-node-verify-api-cert"]
  else
    name = azure_prefixed?(key) ? "azure-#{key}" : key
    ["--#{name}", value.to_s]
  end
end

path, os, action, arg = ARGV
abort "usage: cfg.rb <config.yml> <os|check> ..." unless path && os

cfg = YAML.safe_load(File.read(path)) || {}

if os == "check"
  bad = []
  %w{linux windows}.each do |s|
    bad << "missing section: #{s}" unless cfg[s].is_a?(Hash)
    (cfg[s] || {}).each { |k, v| bad << "#{s}.#{k} still has a placeholder" if v.to_s.include?("{{") }
  end
  puts bad
  exit(bad.empty? ? 0 : 1)
end

section = cfg[os] or abort "no '#{os}' section in #{path}"
# Per-run unique Linux VM name (the QMetry test case uses a timestamped name)
section["vm-name"] = "#{section["vm-name"]}-#{ENV["VM_NAME_SUFFIX"]}" if os == "linux" && !ENV["VM_NAME_SUFFIX"].to_s.empty?

case action
when "get"
  puts section[arg].to_s
when "flags"
  group_keys = %w{resource-group-name confirm}
  section.each do |k, v|
    next if arg == "group" && !group_keys.include?(k)
    # vm-name is positional for show/delete and a flag only for create
    next if k == "vm-name" && arg != "create"

    puts flag_lines(k, v)
  end
else
  abort "unknown action: #{action}"
end
