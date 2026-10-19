---
name: qmetry-test-cycle
description: 'Run the knife-azure e2e scenarios (knife azurerm server create/show/list/delete against Linux and Windows Azure VMs) from the current host platform (mac, linux or windows), then report each scenario''s Pass/Fail/Not Executed result into a QMetry (QTM4J Cloud) test cycle. Use when asked to "run QMetry cycle CHEF-TR-XXXX", run the knife-azure e2e tests, or sync e2e results into QMetry.'
argument-hint: 'Provide the QMetry test cycle key, e.g. CHEF-TR-3720. Optionally "skip confirmation" / "--yes", "preview only", "linux only"/"windows only", or "cleanup resource groups".'
user-invocable: true
---

# knife-azure QMetry Test Cycle Runner

## What this skill does

Bridges the `test/e2e/` harness with a QMetry (QTM4J Cloud) test cycle:

1. Finds which local scenarios (`test/e2e/scenarios.yml`) are linked to the
   cycle.
2. Runs them with `test/e2e/run_tests.sh` on the **current host platform**
   (mac / linux / windows is auto-detected). Each scenario creates, shows,
   lists or deletes a **real Azure VM** — Linux and Windows targets.
3. Reports each result into QMetry as a new test execution round using the
   already-configured `qtm4j` and `jira` MCP servers.

It does not install or configure MCP servers. **If `qtm4j_*` / `jira_*`
tools are unavailable, stop and tell the user.**

## Scenarios

8 scenarios = 4 commands x 2 target VM OSes (ids in `scenarios.yml`):

| IDs | Command |
|---|---|
| AZ-LNX-01 / AZ-WIN-01 | `knife azurerm server create` |
| AZ-LNX-02 / AZ-WIN-02 | `knife azurerm server show` |
| AZ-LNX-03 / AZ-WIN-03 | `knife azurerm server list` |
| AZ-LNX-04 / AZ-WIN-04 | `knife azurerm server delete` (+ verifies the VM is gone from `list`) |

Within one target OS they run in order; if `create` fails, show/list/delete
are reported `SKIP` (→ "Not Executed"). The same scenarios are run on each
host platform; use **one QMetry cycle per host platform** (mac, linux,
windows) — run this skill once on each host.

A scenario is reported to QMetry only if its `qmetry_test_case_id` in
`scenarios.yml` is set (e.g. `CHEF-TC-23537`). Unmapped scenarios still run
but are not reported. If none are mapped, tell the user to fill them in
(ask for the TC keys) rather than guessing.

## Prerequisites (check first, stop and tell the user if missing)

- **QMetry MCP server** (one-time, per machine). Official option: SmartBear's
  `@smartbear/mcp` npm package (Node.js 22+). The server **must be named
  `qtm4j`** so tools appear as `qtm4j-qtm4j_*` as used below.
  1. Get the key: Jira → **QMetry → Configuration → Open API** → generate and
     copy the **API Key** (also create an *Automation API Key* only if you
     need automation imports; not needed here).
  2. Install the server locally (use your org npm registry config, e.g. a
     project `.npmrc` in that folder, if npmjs.org is blocked):
     `mkdir -p ~/.copilot/mcp-servers/smartbear-mcp && cd ~/.copilot/mcp-servers/smartbear-mcp && npm init -y && npm install @smartbear/mcp`
  3. Merge `mcp-config.template.json` (this folder) into
     `~/.copilot/mcp-config.json` under `mcpServers`, replacing `<HOME>` and
     the API key placeholder (US-hosted: `https://qtmcloud.qmetry.com`;
     Australia: `https://syd-qtmcloud.qmetry.com`). Keep that file
     private (`chmod 600`) and never commit a real key. Restart the CLI and
     confirm with `/mcp` or `/env` that `qtm4j` is connected.
- **Jira MCP server** named `jira` (used for `jira-get_jira_current_user`),
  configured separately, e.g. the Atlassian MCP server.
- `test/e2e/config.yml` exists, created from `test/e2e/config.template.yml`
  with **no `{{placeholders}}` left** (the runner enforces this). It has only
  `linux:` and `windows:` sections; the runner turns each key into a knife
  flag (`vm-name` → `--azure-vm-name`, `confirm: true` → `--yes`, …) via
  `test/e2e/lib/cfg.rb`. The file is git-ignored — never commit it or print
  `connection-password` values.
- Azure auth for knife: `az login` or `azure_subscription_id`,
  `azure_tenant_id`, `azure_client_id`, `azure_client_secret` in a knife.rb
  (export `KNIFE_CONFIG=/path/to/knife.rb` to pass it with `-c`).
- `bundle install` done in the repo root (or set `KNIFE_CMD`).
- On Windows hosts run from Git Bash. Ruby must be on PATH.

## Procedure

### 1. Build the local lookup table

```bash
ruby test/e2e/scripts/map_qmetry_results.rb --list-mapped
```

JSON array of scenarios with a QMetry mapping (`scenarioId`,
`qmetryTestCaseId`, `title`, `targetOs`, `command`). Re-derive every time.

### 2. Set QMetry project context

`qtm4j-qtm4j_set_project_context({ "projectKey": "CHEF" })` before any other
`qtm4j_*` call.

### 3. Resolve the test cycle (hard stop if not found)

`qtm4j-qtm4j_search_test_cycles({ filter: { searchText: "<CYCLE-KEY>" } })`,
then **exact-match** `key`. No match or ambiguous → STOP: report the
requested key, do not substitute another cycle, do not run anything.

### 4. Cross-reference

`qtm4j-qtm4j_search_linked_test_cases_in_test_cycle({ cycleKey })` → compare
with step 1 by `qmetryTestCaseId`:

- linked AND mapped → scenarios to run
- linked, not mapped locally → report only
- mapped, not linked to this cycle → report only; do not run

Empty intersection → stop and say nothing to run. If the user asked to
preview only, stop here after printing the lists.

### 5. Confirm before creating cloud resources

Running creates **billable Azure VMs** (Standard_B1s / Standard_D4s_v6). Show
the scenario list, the detected host platform, and the resource groups/VM
names from `config.yml` (not passwords), and ask for explicit confirmation
unless the user said "skip confirmation"/"--yes". Honour "linux only" /
"windows only" via `--os`.

### 6. Run and parse

```bash
ruby test/e2e/scripts/map_qmetry_results.rb --run --only AZ-LNX-01,AZ-LNX-02,... [-- --os linux --cleanup-rg]
```

Keep scenario ids in create→show→list→delete order for each OS (the runner
uses `scenarios.yml` order regardless). Progress goes to stderr; stdout is a
JSON array of `{ scenarioId, qmetryTestCaseId, title, hostPlatform,
targetOs, status, durationSeconds, logFile }`. This JSON is the only source
of truth for results. Creating a VM can take many minutes — run it in async
mode and wait.

If a run is interrupted, VMs may remain: run
`test/e2e/run_tests.sh --only <delete ids>` or pass `--cleanup-rg`, and tell
the user which resource groups to check.

### 7. Current user

`jira-get_jira_current_user` once; keep `accountId` as `assignee`.

### 8. Confirm QMetry writes

List each test case key with its mapped result; require confirmation unless
the user opted out.

### 9. Report each result

For every test case, in order:

```
qtm4j-qtm4j_start_new_execution({ testCycleKey, testCaseKey: "<qmetryTestCaseId>",
  assignee: "<accountId>", executionPlannedDate: "<today dd/MMM/yyyy, e.g. 16/Oct/2026>" })

qtm4j-qtm4j_update_test_case_execution({ testCycleKey, testCaseKey,
  executionResultId: "<result NAME: PASS->Pass, FAIL->Fail, SKIP->Not Executed; numeric IDs are skipped by the tool>",
  comment: "<title> — <Status> on <hostPlatform> host, <targetOs> VM. <on Fail: last ~20 log lines>",
  actualTime: "<HH:mm:ss, e.g. 125s -> 00:02:05>" })
```

**Step-level results** (not auto-filled by the call above): fetch
`qtm4j-qtm4j_get_test_steps({ key })`, then for each step call
`qtm4j-qtm4j_update_test_step_execution({ testCycleKey, testCaseKey,
testStepSeqNo, executionResultId, actualResult, comment })`.

- `actualResult` = full, untruncated evidence for that step from `logFile`:
  the literal `$ bundle exec knife azurerm server …` line (password is
  already masked as `********`), the entire output, and the
  `(exit code: N)` line, plus any `check passed/FAILED` lines. For a
  setup-type step, paste the relevant (password-masked) `config.yml`
  section instead. Never summarize or truncate.
- `comment` = plain-language interpretation for a third-party reviewer: what
  the step checked, what happened, and why it does/doesn't match the
  expected result (e.g. "`knife azurerm server create` exited 0 and the
  Linux VM was provisioned in resource group X on a mac host — matches the
  expected result.").

If any MCP call errors, record it prominently and continue with the rest.

### 10. Final summary

| QMetry Key | Scenario ID | Host | Target VM | Result | QMetry Update |
|---|---|---|---|---|---|
| CHEF-TC-… | AZ-LNX-01 | mac | linux | PASS | ✅ updated |

Plus both mismatch lists from step 4, any ❌ QMetry update called out in
prose, and any VMs/resource groups that may still exist in Azure.

## Rules

- Always start a new execution round per run; keep no local state/cache.
- Never write or print secrets (connection passwords, client secrets).
- No custom QMetry client code — only the `qtm4j` / `jira` MCP tools.
- Only set the cycle status to Done (`qtm4j_update_test_cycle`) if asked.

## Example prompts

- `/qmetry-test-cycle Run QMetry cycle CHEF-TR-3720.`
- `/qmetry-test-cycle Run CHEF-TR-3721 on linux VMs only, skip confirmation, cleanup resource groups.`
- `/qmetry-test-cycle Which of my scenarios are linked to CHEF-TR-3720? Don't run anything.`
