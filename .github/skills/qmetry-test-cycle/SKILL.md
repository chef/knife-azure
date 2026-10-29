---
name: qmetry-test-cycle
description: 'Run a QMetry (QTM4J Cloud) test cycle end to end for knife-azure: read every test case and step from QMetry, show a dry run with real values, then (after approval) run each step''s knife azurerm command against real Azure VMs and report Pass/Fail per step and per case back into the cycle. Use when asked to "run QMetry cycle CHEF-TR-XXXX", run the knife-azure e2e tests, or sync e2e results into QMetry.'
argument-hint: 'Optional QMetry test cycle key, e.g. CHEF-TR-3787 (asked if omitted). Optionally which cases to run or skip.'
user-invocable: true
---

# knife-azure QMetry Test Cycle Runner

Flow: **cycle -> cases -> read steps (ask doubts) -> dry run -> approve -> real run -> report to QMetry.**
Setup guide for users (Azure auth, QMetry MCP, config.yml, how to run):
[`README.md`](README.md).
No runner script: you (the agent) run each step's knife command yourself with the
installed `knife` (the `chef/knife` Habitat package, which bundles knife-azure). No Ruby/bundler setup is needed
beyond what `knife` itself needs.

The real run creates **real, billable Azure VMs**. The only questions are: which
cycle, which cases, whether to show a dry run (plus missing config values), and the
**real-run approval**:
- No dry run chosen: choosing the cases (with the billable-VM warning) is the approval.
- Dry run chosen: after the preview, ask once **"Run for real / Stop after dry run"**.
  Only "Run for real" starts Azure and QMetry work; anything else ends the skill with
  nothing created or reported (dry-run-only outcome).
No other confirmation is asked: once approved, run and report to QMetry automatically.
Never write to QMetry before the real run finished.

## Avoiding tool-permission prompts

The only prompts besides the case/dry-run question come from the Copilot CLI's
tool-permission system, not from this skill. Start the CLI pre-approved:

```
copilot --allow-tool 'qtm4j' --allow-tool 'shell(knife)' --allow-tool 'shell(ruby)' --allow-tool 'shell(az)' --allow-tool 'write'
```

(or choose "always allow" on first use; `--allow-all-tools` approves everything, use
only in a trusted environment). Agent: never add confirmation questions beyond the
real-run approval described above.

## Prerequisites (check ALL first; if any is missing, stop and tell the user. Do not touch QMetry)

1. `knife azurerm server create --help` works (`chef/knife` hab package installed). Missing
   `knife`, license, Azure token or MCP server are stop-and-tell items (not asked
   as values); missing config values are asked, see item 3.
2. Chef license: `CHEF_LICENSE_KEY` is set in the environment (or knife is already
   licensed). Never print it.
3. `test/e2e/config.yml` (copy of `test/e2e/config.template.yml`, git-ignored; never
   commit it or print passwords). **config.yml has priority:** every placeholder value
   is taken from it first. If the file or a value is missing, empty, `<fill-me>` or an
   unresolved `{{...}}` (other than `{{current-timestamp}}` / `{{case-seq}}` in the
   vm-name keys), or a `connection-password` is a known public/sample value (e.g.
   `TestPass123!@#`, `Password123!`) or fails Azure complexity (12+ chars, 3 of
   upper/lower/digit/symbol), **ask
   the user for that value** with ask_user (secrets like passwords: never echo them
   back), use it for this run, and offer to save it into `config.yml`.
   Exception: `bootstrap-version` and other optional keys may stay empty (flag
   omitted) unless a step/case needs them (e.g. "Chef Infra Client 18"); then ask.
4. Azure auth for knife: `~/.azure/accessTokens.json` (from `az login` /
   `az account get-access-token --resource https://management.azure.com/`) with
   more than 10 minutes left, or service principal values in a knife.rb
   (`KNIFE_CONFIG=/path/to/knife.rb`). **Both routes also need
   `knife[:azure_subscription_id]`** in the loaded knife config (knife-azure's
   `validate_arm_keys!` always requires it). Check with
   `knife config show knife.azure_subscription_id` (or by reading the config file);
   if it is missing, stop and tell the user before any case runs or anything is
   reported to QMetry.
6. Azure CLI `az` logged in to that same subscription (used only for post-case
   cleanup of run-owned resources, see step 7).
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
The question text must state that the selected cases will **create and delete real,
billable Azure VMs** in the configured resource group(s); choosing cases is the
approval for that. Offer a **cancel** choice; on cancel/decline stop without touching
Azure or QMetry.
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
  replaced by `date +%m%d%H%M%S` (taken once at run start) and `{{case-seq}}` by the
  case's 2-digit position in this run (01, 02, ...). **One unique VM name per test
  case**, shared by all its steps. If the configured name has no `{{case-seq}}`,
  append `-<case-seq>` (Linux) so same-OS cases never share a name. Check that all
  resolved names in the run are distinct and that Windows names are at most 15
  characters (letters, digits, hyphens; not all digits); otherwise ask the user for a
  shorter `vm-name-window` before going on. Record the resolved name per case and
  reuse it everywhere (logs, QMetry comments, summary, cleanup).
- Empty optional keys (e.g. `bootstrap-version`) -> drop that flag. A required
  value that is missing or empty in config -> ask the user (see Prerequisites 3),
  before the dry run so the dry run shows the final values.
- `server delete` gets `--yes`.

### 6. Dry run (only if chosen in step 3), then real-run approval
If the user chose the dry run in step 3, print, per case and step, the exact
command with real values **except secrets: passwords (and any license/API key) are
always shown as `********`**, never in clear text, because the conversation/terminal
transcript is persisted. Also show the resource group, VM name and OS. Execute nothing, make no Azure or QMetry
calls. Ask again for any remaining doubt.
Then ask once (ask_user): **"Run for real"** (creates/deletes the listed billable VMs
and reports to QMetry) or **"Stop after dry run"** (default). Proceed to step 7 only on
"Run for real"; otherwise stop: no Azure commands, no QMetry writes.
If the user declined the dry run in step 3, skip this step (case selection was the
approval).

### 7. Real run (approved)
Do NOT ask for any further confirmation, and do not pre-check or ask about
passwords/tokens beyond Prerequisites. Start immediately. For each case, in order, for each step in order:
run the command (a single `knife ...` invocation) with a long timeout (VM creation
takes minutes), capture the full output and exit code.

- Step **Pass** = exit code 0, no `ERROR:` line, **and the output shows the step's
  `expectedResult` postcondition was met**. Check it explicitly, e.g.: `server create`
  -> output reports the VM created/provisioned with the resolved VM name (and bootstrap
  succeeded if expected); `server show` -> details of that VM name are printed;
  `server list` -> the VM name appears (or is absent if expected); `server delete` ->
  output confirms the VM was deleted. Anything else is **Fail**; if the expected result
  cannot be verified from the output, run a read-only check (`knife azurerm server
  show`/`list`) and fail the step if it does not confirm it. Never pass on exit code
  alone.
- On a failing step, stop that case: remaining steps are **Not Executed**, the case is
  **Fail**; continue with the next case.
- All steps Pass -> case **Pass**.
- A step with no knife command -> Not Executed; the case is then not Pass.
- Keep a log per case under `test/e2e/results/` (git-ignored): the resolved VM name,
  the command (masked), full output (secrets redacted), `(exit code: N)`.

#### Negative / license-removal cases (only when the step says so)
Applies only to a step whose `expectedResult` says the command "should fail" and to a
step that deletes the license (`licenses.yaml`). All other cases keep the rules above.
- **License deletion step** (`~/.chef/licenses.yaml`; Windows `C:\Users\<user>\.chef\licenses.yaml`):
  first back the file up (e.g. to `licenses.yaml.e2e-bak`), then delete it. Pass = file
  no longer exists. For the following steps of this case also **unset `CHEF_LICENSE_KEY`**
  in the process running knife (`Remove-Item Env:CHEF_LICENSE_KEY` / `unset`), otherwise
  knife stays licensed. If `licenses.yaml` is already absent the step still passes.
- **Expected-failure step:** the step **Passes only if knife fails** (non-zero exit code
  or an `ERROR:` line) **with the error the step expects** (for license cases: a license
  error such as `LicenseKeyNotFetchedError` / "Unable to obtain a License Key"; for a
  `server show` of a never-created VM: VM not found). Exit 0 and no `ERROR:` = **Fail**.
  A failure for any other reason (Azure auth/token, network, invalid argument, quota,
  missing gem) = **Fail**, with the real error as evidence.
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

#### Cleanup of run-owned resources (every case, Pass or Fail)
`knife azurerm server delete` removes only the VM; the OS disk, NIC, public IP, NSG
and vnet that `server create` made stay behind and are billed. After each case that
ran a `server create` (even if it failed, was an expected failure, or never reached
delete), clean up in that case's resource group **only the resources this run
created**. Unless overridden in the step, knife names them after the case's VM:
VM `<vm>`, NIC `<vm>`, public IP `<vm>`, NSG `<vm>_sec_grp_*`, vnet `<vm>`, OS disk
`<vm with - and _ removed>`. The ARM template creates the public IP, vnet and NIC
before the VM, so a failed create can leave them even when no VM exists.

- **Ownership snapshot (before the real run, for every case):** list the resources
  in its resource group matching those names (`az resource list -g <rg> --query
  "[?starts_with(name, '<vm>') || name=='<disk>'].id"`). If **any** exists, the name
  collides: do not run that case; pick a fresh name (new `{{current-timestamp}}`)
  and re-check, or ask the user. Record the (empty) snapshot per case. This also
  guarantees the case's `server delete` steps only target a VM this run created.
- **Reconcile (after the case):** list the same names again; the run-owned set is
  the current IDs **minus the snapshot**. Delete only those exact IDs, in dependency
  order: VM, NIC, public IP, NSG, vnet, disk (`az resource delete --ids ...`). Never
  delete a resource group, any ID from the snapshot, or a vnet/NSG/disk given
  explicitly in the step or config (shared: leave it).
- Record cleanup per case (deleted IDs / left behind + error) in the log, QMetry case
  comment and final summary. A cleanup failure does not change the step results.
Skip cleanup only for cases that ran no `server create` command.

If interrupted, tell the user which resource group and VM names may still hold
resources.

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

- Only update the case/steps if `start_new_execution` **succeeded** (returned a new
  execution). If it errors or returns none, do not call the update tools for that
  case (they would overwrite an older execution); mark its QMetry Update as failed
  and continue with the next case.
- `actualResult` = the full, untruncated step evidence: masked command line, entire
  output and the `(exit code: N)` line. Before sending, redact any occurrence of the
  password, license key or tokens in the output as well (`********`).
- `comment` = plain-language reviewer note: what the step checked, what happened,
  whether it matches the expected result.
- If a QMetry call errors, note it and continue.

### 9. Final summary
| QMetry Key | Steps (pass/total) | Host | Target VM | Result | Cleanup | QMetry Update |
|---|---|---|---|---|---|---|

Mention any QMetry failures and any resources cleanup could not delete (with
resource group and names). Offer to retry deleting them.

## Rules
- Never print or store secrets (passwords, license key, API keys), including in the
  dry run, logs and QMetry evidence: always `********`.
- Only the `qtm4j` MCP tools for QMetry; no custom client code.
- Always a new execution round per run; keep no local cache of QMetry data.
- Set the cycle to Done only if the user asks.
