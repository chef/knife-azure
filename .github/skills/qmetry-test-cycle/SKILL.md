---
name: qmetry-test-cycle
description: 'Run a QMetry (QTM4J Cloud) test cycle end to end for knife-azure: read every test case and step from QMetry, show a dry run with real values, then (after approval) run each step''s knife azurerm command against real Azure VMs and report Pass/Fail per step and per case back into the cycle. Use when asked to "run QMetry cycle CHEF-TR-XXXX", run the knife-azure e2e tests, or sync e2e results into QMetry.'
argument-hint: 'Optional QMetry test cycle key, e.g. CHEF-TR-3787 (asked if omitted). Optionally which cases to run or skip.'
user-invocable: true
---

# knife-azure QMetry Test Cycle Runner

Flow: **cycle -> cases -> read steps (ask doubts) -> dry run -> real run -> report to QMetry.**
No runner script: you (the agent) run each step's knife command yourself with the
installed `knife` (the released knife-azure gem). No Ruby/bundler setup is needed
beyond what `knife` itself needs.

The real run creates **real, billable Azure VMs**. The only questions are: which
cycle, which cases, and whether to show a dry run (plus missing config values).
**No other confirmation is asked**: once cases are chosen (and the dry run shown, if
chosen), run for real straight away and report to QMetry automatically.
Never write to QMetry before the real run finished.

## Avoiding tool-permission prompts

The only prompts besides the case/dry-run question come from the Copilot CLI's
tool-permission system, not from this skill. Start the CLI pre-approved:

```
copilot --allow-tool 'qtm4j' --allow-tool 'shell(knife)' --allow-tool 'shell(ruby)' --allow-tool 'write'
```

(or choose "always allow" on first use; `--allow-all-tools` approves everything, use
only in a trusted environment). Agent: never add your own confirmation questions.

## Prerequisites (check ALL first; if any is missing, stop and tell the user. Do not touch QMetry)

1. `knife azurerm server create --help` works (knife-azure gem installed). Missing
   `knife`, license, Azure token or MCP server are stop-and-tell items (not asked
   as values); missing config values are asked, see item 3.
2. Chef license: `CHEF_LICENSE_KEY` is set in the environment (or knife is already
   licensed). Never print it.
3. `test/e2e/config.yml` (copy of `test/e2e/config.template.yml`, git-ignored; never
   commit it or print passwords). **config.yml has priority:** every placeholder value
   is taken from it first. If the file or a value is missing, empty, `<fill-me>` or an
   unresolved `{{...}}` (other than `{{current-timestamp}}` in the vm-name keys), **ask
   the user for that value** with ask_user (secrets like passwords: never echo them
   back), use it for this run, and offer to save it into `config.yml`.
   Exception: `bootstrap-version` and other optional keys may stay empty (flag
   omitted) unless a step/case needs them (e.g. "Chef Infra Client 18"); then ask.
4. Azure auth for knife: `~/.azure/accessTokens.json` (from `az login` /
   `az account get-access-token --resource https://management.azure.com/`) with
   more than 10 minutes left, or service principal values in a knife.rb
   (`KNIFE_CONFIG=/path/to/knife.rb`).
5. QMetry MCP server `qtm4j` (tools `qtm4j-qtm4j_*`). Setup: Jira -> QMetry ->
   Configuration -> Open API -> API key; install `@smartbear/mcp` (Node 22+) under
   `~/.copilot/mcp-servers/smartbear-mcp`; merge `mcp-config.template.json` into
   `~/.copilot/mcp-config.json` (`chmod 600`, never commit the key); restart the CLI.

## Procedure

### 1. Get the cycle
If no cycle key (`CHEF-TR-...`) was given, ask with ask_user. A test case key
(`CHEF-TC-...`) is not a cycle: ask again.

### 2. Resolve the cycle (hard stop if not found)
`qtm4j-qtm4j_set_project_context({ projectKey: "CHEF" })`, then
`qtm4j-qtm4j_search_test_cycles({ filter: { searchText: "<KEY>" } })` and exact-match
`key`. No match -> STOP.

### 3. Choose the test cases (and the dry run) in ONE question
`qtm4j-qtm4j_search_linked_test_cases_in_test_cycle({ cycleKey })`. List the cases
(key + summary, in the question text) and ask once (ask_user) with these fields:
- selection: **run all**, **only selected**, or **all except selected**;
- case keys as a **free-text field, never a multi-select checklist** (the checklist can
  come back empty even when the user picked items). Accept "CHEF-TC-23766", "23766" or
  a comma list ("23765, 23766"); normalise bare numbers to `CHEF-TC-<n>` and check
  each against the cycle's linked cases (unknown keys -> ask again). If the mode needs
  keys and the answer is empty, ask once more in plain free text. Show the cases with
  their numbers in the question text so the user can type them;
- **show dry run first?** (yes/no, default yes).
If the user already named cases or the dry run in the request, don't ask for those.

### 4. Read all steps and clear doubts
For every selected case call `qtm4j-qtm4j_get_test_steps({ key })` (always fresh).
Read every step. **If anything is unclear, ask the user before going on**, e.g.
a step with no knife command, an unknown `{{placeholder}}`, a Chef version that
needs `bootstrap-version`, a Windows case with no password, or a step order that
looks wrong. Do not guess.

### 5. Build the commands (placeholders -> real values)
Take the knife command from each step's `testData` (strip `{noformat}`, join `\`
continuations, fix nesting like `{{{{vm-name-timestamp}} }}`).
Use the `windows:` section if the case summary mentions Windows, else `linux:`.

Value priority: 1) `config.yml` section value, 2) otherwise ask the user (never
invent defaults, never use values from the template).

- `{{key}}` -> value of `key` in the section.
- `{{vm-name}}`, `{{vm-name-timestamp}}`, `{{vm-name-linux}}`, `{{vm-name-window}}`
  -> the section's `vm-name-linux` / `vm-name-window` with `{{current-timestamp}}`
  replaced by `date +%m%d%H%M%S`. **One unique VM name per test case**, shared by all
  its steps. Always timestamped, so names never collide.
- Empty optional keys (e.g. `bootstrap-version`) -> drop that flag. A required
  value that is missing or empty in config -> ask the user (see Prerequisites 3),
  before the dry run so the dry run shows the final values.
- `server delete` gets `--yes`.

### 6. Dry run (only if chosen in step 3; do not ask again)
If the user chose the dry run in step 3, print, per case and step, the **exact
command with real values, including the password exactly as it will be executed**
(the dry run is only for the user; logs and QMetry evidence still mask the password),
plus the resource group, VM name and OS. Execute nothing, make no Azure or QMetry
calls. Ask again for any remaining doubt. If the user declined the dry run, skip it.

### 7. Real run (no confirmation)
Do NOT ask for any confirmation, and do not pre-check or ask about passwords/tokens
beyond Prerequisites. Start immediately. For each case, in order, for each step in order:
run the command (a single `knife ...` invocation) with a long timeout (VM creation
takes minutes), capture the full output and exit code.

- Step **Pass** = exit code 0 and no `ERROR:` line. Otherwise **Fail**.
- On a failing step, stop that case: remaining steps are **Not Executed**, the case is
  **Fail**; continue with the next case.
- All steps Pass -> case **Pass**.
- A step with no knife command -> Not Executed; the case is then not Pass.
- Keep a log per case under `test/e2e/results/` (git-ignored): the command (masked),
  full output, `(exit code: N)`.

#### Negative / license-removal cases (only when the step says so)
Applies only to a step whose `expectedResult` says the command "should fail" and to a
step that deletes the license (`licenses.yaml`). All other cases keep the rules above.
- **License deletion step** (`~/.chef/licenses.yaml`; Windows `C:\Users\<user>\.chef\licenses.yaml`):
  first back the file up (e.g. to `licenses.yaml.e2e-bak`), then delete it. Pass = file
  no longer exists. For the following steps of this case also **unset `CHEF_LICENSE_KEY`**
  in the process running knife (`Remove-Item Env:CHEF_LICENSE_KEY` / `unset`), otherwise
  knife stays licensed. If `licenses.yaml` is already absent the step still passes.
- **Expected-failure step:** the step **Passes only if knife fails** (non-zero exit code
  or an `ERROR:` line), ideally with a license error. Exit 0 and no `ERROR:` = **Fail**.
  Without a license, `server create` may sit on a license prompt for about 90 seconds
  before failing (`LicenseKeyNotFetchedError: Unable to obtain a License Key`). Do not
  answer the prompt and do not kill it early: use a timeout of at least 5 minutes and
  wait for knife to exit by itself (when run non-interactively it can fail at once).
  Do not stop the case on such a step; run the remaining steps.
- Steps that follow (e.g. `server show` of a VM that was never created) are also
  expected to fail: same rule. Never create or delete real VMs for these steps.
- When the case ends (even on error) **always restore** the backup to `licenses.yaml`
  and restore `CHEF_LICENSE_KEY`, so later cases are licensed again.
- Report actualResult/comment with the real error text and state that the failure was
  the expected outcome.

If interrupted, tell the user which resource group may still hold VMs.

### 8. Report to QMetry (automatic, only after the run finished)
Pass or Fail (or Not Executed), report straight away: **do not ask again**. If a
failure was caused by the environment (auth, license, network), still report it,
with the error as evidence.
For each case:

```
qtm4j-qtm4j_start_new_execution({ testCycleKey, testCaseKey,
  executionPlannedDate: "<today dd/MMM/yyyy>" })
qtm4j-qtm4j_update_test_case_execution({ testCycleKey, testCaseKey,
  executionResultId: "Pass|Fail|Not Executed",
  comment: "<summary> - <Result> on <host> host, <OS> VM. <on Fail: last ~20 log lines>",
  actualTime: "HH:mm:ss" })
```
Then every step: `qtm4j-qtm4j_update_test_step_execution({ testCycleKey, testCaseKey,
testStepSeqNo, executionResultId, actualResult, comment })`.

- `actualResult` = the full, untruncated step evidence: masked command line, entire
  output and the `(exit code: N)` line.
- `comment` = plain-language reviewer note: what the step checked, what happened,
  whether it matches the expected result.
- If a QMetry call errors, note it and continue.

### 9. Final summary
| QMetry Key | Steps (pass/total) | Host | Target VM | Result | QMetry Update |
|---|---|---|---|---|---|

Mention any QMetry failures, and any VMs possibly still running (failed case that
never reached delete). Offer to delete them.

## Rules
- Never print or store secrets (passwords, license key, API keys).
- Only the `qtm4j` MCP tools for QMetry; no custom client code.
- Always a new execution round per run; keep no local cache of QMetry data.
- Set the cycle to Done only if the user asks.
