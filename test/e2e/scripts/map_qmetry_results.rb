#!/usr/bin/env ruby
# Local helper for the qmetry-test-cycle skill. Makes NO QMetry API calls.
#
#   map_qmetry_results.rb --list-mapped
#       JSON array of scenarios in scenarios.yml that have a qmetry_test_case_id.
#   map_qmetry_results.rb --run --only AZ-LNX-01,AZ-LNX-02 [-- <extra run_tests.sh args>]
#       Runs run_tests.sh, then prints a JSON array of
#       { scenarioId, qmetryTestCaseId, title, hostPlatform, targetOs, status,
#         durationSeconds, logFile } for the run's mapped scenarios.
#   map_qmetry_results.rb --parse <results-dir>
#       Same JSON, from an existing results directory (no run).
require "yaml"
require "csv"
require "json"

E2E = File.expand_path("..", __dir__)

def mapped
  YAML.safe_load(File.read(File.join(E2E, "scenarios.yml")))["scenarios"]
    .reject { |s| s["qmetry_test_case_id"].to_s.strip.empty? }
end

def parse(dir)
  lookup = mapped.to_h { |s| [s["id"], s] }
  CSV.read(File.join(dir, "summary.csv"), headers: true).filter_map do |r|
    s = lookup[r["scenario_id"]] or next
    {
      scenarioId: s["id"], qmetryTestCaseId: s["qmetry_test_case_id"], title: s["title"],
      hostPlatform: r["host_platform"], targetOs: r["target_os"], status: r["status"],
      durationSeconds: r["duration_seconds"].to_i, logFile: r["log_file"]
    }
  end
end

case ARGV.first
when "--list-mapped"
  puts JSON.pretty_generate(mapped.map { |s| { scenarioId: s["id"], qmetryTestCaseId: s["qmetry_test_case_id"], title: s["title"], targetOs: s["target_os"], command: s["command"] } })
when "--run"
  rest = ARGV.drop(1)
  extra = rest.include?("--") ? rest.drop(rest.index("--") + 1) : []
  own = rest.take_while { |a| a != "--" }
  only = own[own.index("--only") + 1] if own.include?("--only")
  args = only ? ["--only", only] : []
  # run_tests.sh output goes to stderr so stdout stays pure JSON
  system(File.join(E2E, "run_tests.sh"), *args, *extra, out: $stderr)
  dir = Dir.glob(File.join(E2E, "results", "*")).max_by { |d| File.mtime(d) }
  abort "no results directory found" unless dir && File.exist?(File.join(dir, "summary.csv"))
  puts JSON.pretty_generate(parse(dir))
when "--parse"
  puts JSON.pretty_generate(parse(ARGV[1] || abort("usage: --parse <results-dir>")))
else
  abort "usage: map_qmetry_results.rb --list-mapped | --run --only IDS [-- args] | --parse DIR"
end
