#!/usr/bin/env ruby
# Runs every step of every test case in a plan built from a QMetry test cycle
# (see the qmetry-test-cycle skill). Makes NO QMetry API calls.
#
#   run_plan.rb <plan.json> [--config FILE] [--dry-run] [--os linux|windows]
#
# plan.json: [{ "testCaseKey", "summary", "steps": [{ "seqNo", "stepDetails", "testData" }] }]
#
# For each test case the knife command is taken from each step's testData,
# {{placeholders}} are filled from test/e2e/config.yml (linux: / windows:
# section, chosen from the test case summary; default linux), and the steps
# run in order. {{vm-name}} and {{vm-name-timestamp}} resolve to one unique VM
# name per test case, so later steps (show/delete) reuse the VM that create
# made. The first failing step stops the test case; its remaining steps are
# SKIP. A step with no knife command is NOT_RUN (reported as Not Executed).
#
# stdout: JSON array of { testCaseKey, summary, hostPlatform, targetOs, status,
#   durationSeconds, logFile, vmName, stepResults: [{ seqNo, command, status }] }
# Logs: test/e2e/results/<run-id>/<testCaseKey>.log with the same
# "=== STEP n/N: cmd ===" / "=== STEP n RESULT: X ===" markers.
require "json"
require "yaml"
require "open3"
require "shellwords"
require "fileutils"

E2E = File.expand_path("..", __dir__)
MASK = "********".freeze

plan_path = ARGV.shift or abort "usage: run_plan.rb <plan.json> [--config FILE] [--dry-run] [--os linux|windows]"
config_path = File.join(E2E, "config.yml")
dry_run = false
os_filter = nil
until ARGV.empty?
  case (arg = ARGV.shift)
  when "--config" then config_path = ARGV.shift
  when "--dry-run" then dry_run = true
  when "--os" then os_filter = ARGV.shift
  else abort "unknown argument: #{arg}"
  end
end

abort "config not found: #{config_path}" unless File.exist?(config_path)
config = YAML.safe_load(File.read(config_path)) || {}
plan = JSON.parse(File.read(plan_path))

host = case RbConfig::CONFIG["host_os"]
       when /darwin/ then "mac"
       when /linux/ then "linux"
       when /mswin|mingw|cygwin/ then "windows"
       else "unknown"
       end
run_id = "#{Time.now.strftime("%Y%m%d-%H%M%S")}-#{host}"
results_dir = File.join(E2E, "results", run_id)
FileUtils.mkdir_p(results_dir)
suffix = Time.now.strftime("%m%d%H%M%S")
knife_cmd = ENV["KNIFE_CMD"] || "bundle exec knife"
knife_conf = ENV["KNIFE_CONFIG"].to_s

# Extracts the knife command from a step's testData (or a `backticked` knife
# command in stepDetails), or nil. Commands with <PLACEHOLDER> values are
# manual (nil).
def extract_command(test_data, details = nil)
  text = test_data.to_s.gsub(/\{noformat\}/, "").gsub(/\\\s*\n/, " ")
  line = text.lines.map(&:strip).find { |l| l.start_with?("knife ") }
  line ||= details.to_s[/`(knife [^`]+)`/, 1]
  return nil if line =~ /<[A-Za-z_]+>/
  line&.squeeze(" ")
end

# Drops "--flag {{key}}" when the config value for key is empty (e.g. an unset
# bootstrap-version), then fills the remaining {{placeholders}}. Tolerates stray
# nesting like "{{{{vm-name}} }}".
def render(cmd, section, vm_name)
  out = cmd.gsub(/\{\{\s*\{\{([^{}]+)\}\}\s*\}\}/) { "{{#{Regexp.last_match(1)}}}" }
  out = out.gsub(/--[\w-]+\s+'?\{\{([^{}]+)\}\}'?/) do |m|
    key = Regexp.last_match(1).strip
    special = %w{vm-name vm-name-timestamp}.include?(key)
    !special && section[key].to_s.empty? ? "" : m
  end
  10.times do
    changed = out.gsub!(/\{\{([^{}]+)\}\}/) do
      key = Regexp.last_match(1).strip
      if %w{vm-name vm-name-timestamp}.include?(key) then vm_name
      else section[key].to_s
      end
    end
    break unless changed
  end
  out.gsub(/[{}]/, "").squeeze(" ").strip
end

def secrets(section)
  [section["connection-password"]].compact.map(&:to_s).reject(&:empty?)
end

def mask(text, secs)
  secs.reduce(text.to_s) { |t, s| t.gsub(s, MASK) }
end

results = plan.filter_map do |tc|
  key = tc["testCaseKey"]
  os = tc["summary"].to_s =~ /windows/i ? "windows" : "linux"
  next if os_filter && os_filter != os

  section = (config[os] || {}).dup
  base = section["vm-name"].to_s
  vm_name = base.empty? ? "knife-azure-#{key.downcase}-#{suffix}" : "#{base}-#{suffix}"
  secs = secrets(section)
  log_file = File.join(results_dir, "#{key}.log")
  log = File.open(log_file, "w")
  warn "[#{key}] #{tc["summary"]} (host: #{host}, target: #{os}, vm: #{vm_name})"
  started = Time.now
  steps = (tc["steps"] || []).sort_by { |s| s["seqNo"].to_i }
  failed = false
  step_results = []

  steps.each_with_index do |step, i|
    n = i + 1
    raw = extract_command(step["testData"], step["stepDetails"])
    cmd_name = raw ? raw.split[2..3]&.join(" ").to_s : "(no knife command)"
    log.puts "=== STEP #{n}/#{steps.size}: #{cmd_name} ==="
    status =
      if failed
        "SKIP"
      elsif raw.nil?
        log.puts "step has no knife command in testData; not executed by the harness"
        "NOT_RUN"
      else
        argv = Shellwords.split(render(raw, section, vm_name))
        argv += ["--yes"] if argv.include?("delete") && !(argv & %w{-y --yes}).any?
        argv = Shellwords.split(knife_cmd) + argv[1..]
        argv += ["-c", knife_conf] unless knife_conf.empty?
        shown = argv.map { |a| a =~ /\s/ ? a.inspect : a }.join(" ")
        log.puts mask("$ #{shown}", secs)
        if dry_run
          warn mask("  $ #{shown}", secs)
          "PASS"
        else
          out, st = Open3.capture2e(*argv, chdir: File.expand_path("../..", E2E))
          rc = st.exitstatus
          if rc.zero? && out =~ /^ERROR:/
            out += "\n(harness: output contains an ERROR line, treating as failure)"
            rc = 1
          end
          log.puts mask(out, secs)
          log.puts "(exit code: #{rc})"
          rc.zero? ? "PASS" : "FAIL"
        end
      end
    failed = true if status == "FAIL"
    log.puts "=== STEP #{n} RESULT: #{status} ==="
    step_results << { seqNo: step["seqNo"], command: cmd_name, status: status }
  end
  log.close

  statuses = step_results.map { |s| s[:status] }
  overall = if statuses.include?("FAIL") then "FAIL"
            elsif statuses.empty? || statuses.all? { |s| s == "NOT_RUN" } then "NOT_RUN"
            elsif statuses.include?("NOT_RUN") then "PARTIAL"
            else "PASS"
            end
  warn "  -> #{overall} (#{(Time.now - started).to_i}s)"
  { testCaseKey: key, summary: tc["summary"], hostPlatform: host, targetOs: os, status: overall,
    durationSeconds: (Time.now - started).to_i, logFile: log_file, vmName: vm_name, stepResults: step_results }
end

puts JSON.pretty_generate(results)
exit(results.any? { |r| r[:status] == "FAIL" } ? 1 : 0)
