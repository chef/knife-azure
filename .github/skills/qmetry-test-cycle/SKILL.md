---
name: qmetry-test-cycle
description: 'Ask which QMetry (QTM4J Cloud) test cycle to run, then execute EVERY linked test case with ALL of its steps (knife azurerm commands taken from the QMetry step test data, against real Azure Linux/Windows VMs) from the current host platform, and report each case and step result (Pass/Fail/Not Executed) back into the cycle. Use when asked to "run QMetry cycle CHEF-TR-XXXX", run the knife-azure e2e tests, or sync e2e results into QMetry.'
argument-hint: 'Optional QMetry test cycle key, e.g. CHEF-TR-3720 (the skill asks if omitted). Optionally "skip confirmation" / "--yes", "preview only", "linux only"/"windows only".'
user-invocable: true
---

# knife-azure QMetry Test Cycle Runner

## What this skill does

1. Asks which test cycle to run (if not given).
2. Reads all test cases linked to the cycle and all steps of each case from
   QMetry. No local scenario mapping file is used.
3. Runs every step's knife command with `test/e2e/scripts/run_plan.rb` on
   the **current host platform**. Creates **real, billable Azure VMs**.
4. Reports each case and each step into QMetry as a new execution round
   using the configured `qtm4j` MCP server.

It does not install or configure MCP servers. **If `qtm4j_*` tools are
unavailable, stop and tell the user.**

## Prerequisites (check first, stop and tell the user if missing)

- **QMetry MCP server** named `qtm4j` (tools appear as `qtm4j-qtm4j_*`).
  Setup: Jira → **QMetry → Configuration → Open API** → generate an API Key;
  install `@smartbear/mcp` (Node.js 22+) e.g. under
  `~/.copilot/mcp-servers/smartbear-mcp`; merge `mcp-config.template.json`
  (this folder) into `~/.copilot/mcp-config.json` (US:
  `https://qtmcloud.qmetry.com`; AU: `https://syd-qtmcloud.qmetry.com`).
  Keep it private (`chmod 600`), never commit a key. Restart the CLI.
- `test/e2e/config.yml`, created from `test/e2e/config.template.yml`, with
  `linux:` and `windows:` sections and no `{{placeholders}}` left. It
  supplies every `{{placeholder}}` used in step test data (resource group,
  location, image, size, user/password, `bootstrap-version`, …). Git-ignored;
  never commit it or print `connection-password`.
- Azure auth for knife: knife-azure reads `~/.azure/accessTokens.json`
  (legacy). After `az login`, regenerate it from
  `az account get-access-token --resource https://management.azure.com/`;
  it must have > 10 minutes left. Or use service principal values in a
  knife.rb (`KNIFE_CONFIG=/path/to/knife.rb`).
- `bundle install` done in the repo root (or set `KNIFE_CMD`).
- On Windows hosts run from Git Bash. Ruby must be on PATH.

## Procedure

### 1. Get the cycle

If the user did not give a cycle key (`CHEF-TR-…`), **ask for it with the
ask_user tool** ("Which QMetry test cycle should I run?") and wait. A test
case key (`CHEF-TC-…`) is not a cycle: ask again.

### 2. Resolve the cycle (hard stop if not found)

`qtm4j-qtm4j_set_project_context({ projectKey: "CHEF" })`, then
`qtm4j-qtm4j_search_test_cycles({ filter: { searchText: "<CYCLE-KEY>" } })`
and **exact-match** `key`. No match → STOP, do not substitute another cycle.

### 3. Load all cases and all steps

`qtm4j-qtm4j_search_linked_test_cases_in_test_cycle({ cycleKey })`, then
`qtm4j-qtm4j_get_test_steps({ key })` for **every** linked case (always
fetch fresh; steps change). Write `/tmp/e2e-plan.json` with the create tool:

```json
[{ "testCaseKey": "CHEF-TC-1", "summary": "...",
   "steps": [{ "seqNo": 1, "stepDetails": "...", "testData": "..." }] }]
```

Show the user the cases and step counts. If the user named specific test
cases (e.g. "only CHEF-TC-23765"), include only those in the plan. If they
asked to preview only,
stop here (optionally run `run_plan.rb /tmp/e2e-plan.json --dry-run`).

### 4. Confirm before creating cloud resources

Show the cases, steps, host platform and resource group / VM names from
`config.yml` (not passwords), and ask for explicit confirmation unless the
user said "skip confirmation"/"--yes". Note any `bootstrap-version` need
(e.g. a case saying Chef Client 18) and check `config.yml` has it set.

### 5. Run

```bash
ruby test/e2e/scripts/run_plan.rb /tmp/e2e-plan.json [--os linux|windows]
```

Run async and wait (VM creation takes minutes). Behaviour:

- The knife command is extracted from each step's `testData`;
  `{{placeholders}}` come from the `linux:`/`windows:` section of
  `config.yml` (Windows if the case summary mentions it, else Linux).
- `{{vm-name}}` / `{{vm-name-timestamp}}` = one unique VM per case, shared by
  all its steps. Flags whose config value is empty are dropped.
- `server delete` gets `--yes` automatically.
- A failing step (non-zero exit or an `ERROR:` line) stops that case; later
  steps are SKIP. Steps without a knife command are NOT_RUN.

stdout JSON: `[{ testCaseKey, summary, hostPlatform, targetOs, status
(PASS|FAIL|PARTIAL|NOT_RUN), durationSeconds, logFile, vmName,
stepResults: [{ seqNo, command, status }] }]`. This is the only source of
truth. Progress goes to stderr. Before trusting a PASS, optionally confirm
with `az vm list -g <rg>` that the VM state matches.

If interrupted, VMs may remain: tell the user which resource groups to check.

### 6. Confirm QMetry writes

List each case key with its result; require confirmation unless opted out.

### 7. Report each result

For every case, in order:

```
qtm4j-qtm4j_start_new_execution({ testCycleKey, testCaseKey,
  executionPlannedDate: "<today dd/MMM/yyyy, e.g. 22/Oct/2026>" })

qtm4j-qtm4j_update_test_case_execution({ testCycleKey, testCaseKey,
  executionResultId: "<result NAME: PASS->Pass, FAIL->Fail, PARTIAL/NOT_RUN->Not Executed>",
  comment: "<summary> — <Status> on <hostPlatform> host, <targetOs> VM. <on Fail: last ~20 log lines>",
  actualTime: "<HH:mm:ss, e.g. 125s -> 00:02:05>" })
```

(Assignee is optional; omit it if no Jira user tool is available.)

Then **every step** of the case:
`qtm4j-qtm4j_update_test_step_execution({ testCycleKey, testCaseKey,
testStepSeqNo, executionResultId, actualResult, comment })`.

- Result per `stepResults` entry: PASS->Pass, FAIL->Fail,
  SKIP/NOT_RUN->Not Executed.
- `actualResult` = full, untruncated evidence from `logFile` between
  `=== STEP N/… ===` and `=== STEP N RESULT: … ===`: the `$ bundle exec
  knife …` line (password already masked), entire output and the
  `(exit code: N)` line. Never summarize or truncate.
- `comment` = plain-language interpretation for a reviewer: what the step
  checked, what happened, and whether it matches the expected result.

If any MCP call errors, record it prominently and continue.

### 8. Final summary

| QMetry Key | Steps (pass/total) | Host | Target VM | Result | QMetry Update |
|---|---|---|---|---|---|

Plus any ❌ QMetry updates in prose, and **any VMs still running** in Azure
(cases with no delete step, or failed/interrupted runs) with an offer to
delete them.

## Rules

- Always start a new execution round per run; keep no local state/cache.
- Never write or print secrets (connection passwords, client secrets).
- No custom QMetry client code — only the `qtm4j` MCP tools.
- Only set the cycle status to Done (`qtm4j_update_test_cycle`) if asked.

## Example prompts

- `/qmetry-test-cycle` (the skill asks which cycle)
- `/qmetry-test-cycle Run QMetry cycle CHEF-TR-3787.`
- `/qmetry-test-cycle Run CHEF-TR-3721 on linux VMs only, skip confirmation.`
- `/qmetry-test-cycle Preview CHEF-TR-3787, don't run anything.`
