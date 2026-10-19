#!/usr/bin/env bash
#
# knife-azure e2e runner.
#
# Runs the create / show / list / delete scenarios from scenarios.yml for the
# Linux and Windows target VMs defined in config.yml, from the *current host*
# (macOS, Linux, or Windows via Git Bash). Run it once per host platform; the
# detected platform is recorded in the results so each host's run can be
# reported to its own QMetry test cycle.
#
# Usage:
#   test/e2e/run_tests.sh [--config FILE] [--only IDS] [--os linux|windows|all]
#                         [--cleanup-rg] [--dry-run]
#
#   --config FILE   config file (default: test/e2e/config.yml)
#   --only IDS      comma-separated scenario ids, e.g. AZ-LNX-01,AZ-LNX-02
#   --os OS         limit to one target VM OS (default: all)
#   --cleanup-rg    after the run, `az group delete` any resource group whose
#                   VM was created but not deleted by a passing delete scenario
#   --dry-run       print the knife commands (password masked), run nothing
#
# Environment:
#   KNIFE_CMD       default "bundle exec knife"
#   KNIFE_CONFIG    optional knife.rb (passed as -c) holding azure_subscription_id,
#                   azure_tenant_id, azure_client_id, azure_client_secret
#                   (or rely on `az login`)
#
# Output: test/e2e/results/<RUN_ID>/{summary.csv,<scenario-id>.log}
# Exit code: 0 if no scenario FAILed, 1 otherwise, 2 on usage/config errors.
set -o pipefail

E2E_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$E2E_DIR/../.." && pwd)"
CFG_RB="$E2E_DIR/lib/cfg.rb"
CONFIG="$E2E_DIR/config.yml"
KNIFE_CMD="${KNIFE_CMD:-bundle exec knife}"
ONLY=""
OS_FILTER="all"
CLEANUP_RG=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --os) OS_FILTER="$2"; shift 2 ;;
    --cleanup-rg) CLEANUP_RG=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n 2,28p "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$OS_FILTER" in all|linux|windows) ;; *) echo "--os must be linux, windows or all" >&2; exit 2 ;; esac

[ -f "$CONFIG" ] || { echo "config not found: $CONFIG (copy config.template.yml to config.yml)" >&2; exit 2; }
if ! problems="$(ruby "$CFG_RB" "$CONFIG" check)"; then
  echo "config problems in $CONFIG:" >&2
  echo "$problems" >&2
  exit 2
fi

case "$(uname -s)" in
  Darwin) HOST_PLATFORM="mac" ;;
  Linux) HOST_PLATFORM="linux" ;;
  MINGW*|MSYS*|CYGWIN*) HOST_PLATFORM="windows" ;;
  *) HOST_PLATFORM="unknown" ;;
esac

RUN_ID="$(date +%Y%m%d-%H%M%S)-$HOST_PLATFORM"
RESULTS_DIR="$E2E_DIR/results/$RUN_ID"
SUMMARY="$RESULTS_DIR/summary.csv"
mkdir -p "$RESULTS_DIR"
echo "scenario_id,qmetry_test_case_id,title,host_platform,target_os,status,duration_seconds,log_file" > "$SUMMARY"

cd "$REPO_ROOT" || exit 2

# Unique Linux VM name per run; keep it so show/delete in this run reuse it
export VM_NAME_SUFFIX="${VM_NAME_SUFFIX:-$(date +%m%d%H%M%S)}"

cfg_get() { ruby "$CFG_RB" "$CONFIG" "$1" get "$2"; }

# Fills the global array FLAGS (bash 3.2 compatible; no mapfile).
load_flags() {
  FLAGS=()
  while IFS= read -r line; do FLAGS+=("$line"); done < <(ruby "$CFG_RB" "$CONFIG" "$1" flags "$2")
}

mask() {
  local s="$1" pw
  for pw in "$PW_LINUX" "$PW_WINDOWS"; do
    [ -n "$pw" ] && s="${s//"$pw"/********}"
  done
  printf '%s' "$s"
}

PW_LINUX="$(cfg_get linux connection-password)"
PW_WINDOWS="$(cfg_get windows connection-password)"

# Runs knife with the given args, logging the masked command, full output and
# exit code to $LOG; sets LAST_OUT / LAST_RC.
run_knife() {
  local shown="\$ $KNIFE_CMD $*"
  { mask "$shown"; echo; } >> "$LOG"
  if [ "$DRY_RUN" = 1 ]; then
    mask "$shown"; echo
    LAST_OUT=""; LAST_RC=0
    return 0
  fi
  local extra=()
  [ -n "$KNIFE_CONFIG" ] && extra=(-c "$KNIFE_CONFIG")
  LAST_OUT="$($KNIFE_CMD "$@" "${extra[@]}" 2>&1)"
  LAST_RC=$?
  { mask "$LAST_OUT"; echo; echo "(exit code: $LAST_RC)"; echo; } >> "$LOG"
}

verify_contains() { # <label> <needle> ; checks LAST_OUT
  [ "$DRY_RUN" = 1 ] && return 0
  if printf '%s' "$LAST_OUT" | grep -qF -- "$2"; then
    echo "check passed: output contains '$2' ($1)" >> "$LOG"; return 0
  fi
  echo "check FAILED: output does not contain '$2' ($1)" >> "$LOG"; return 1
}

# Echo PASS/FAIL for one scenario command.
exec_scenario() { # <command> <target_os>
  local cmd="$1" os="$2" vm rg
  vm="$(cfg_get "$os" vm-name)"
  rg="$(cfg_get "$os" resource-group-name)"
  case "$cmd" in
    create)
      load_flags "$os" create
      run_knife azurerm server create "${FLAGS[@]}"
      [ "$LAST_RC" = 0 ] || return 1
      ;;
    show)
      load_flags "$os" group
      run_knife azurerm server show "$vm" "${FLAGS[@]}"
      [ "$LAST_RC" = 0 ] && verify_contains "show $vm" "$vm" || return 1
      ;;
    list)
      load_flags "$os" group
      run_knife azurerm server list "${FLAGS[@]}"
      [ "$LAST_RC" = 0 ] && verify_contains "list contains $vm" "$vm" || return 1
      ;;
    delete)
      load_flags "$os" group
      run_knife azurerm server delete "$vm" "${FLAGS[@]}"
      [ "$LAST_RC" = 0 ] || return 1
      # the VM must be gone from the listing afterwards
      run_knife azurerm server list "${FLAGS[@]}"
      if [ "$DRY_RUN" != 1 ] && printf '%s' "$LAST_OUT" | grep -qF -- "$vm"; then
        echo "check FAILED: $vm still listed after delete" >> "$LOG"; return 1
      fi
      ;;
    *) echo "unknown command $cmd" >> "$LOG"; return 1 ;;
  esac
  return 0
}

SCEN_TSV="$(ruby -ryaml -e '
  YAML.safe_load(File.read(ARGV[0]))["scenarios"].each do |s|
    puts [s["id"], s["command"], s["target_os"], s["title"], s["qmetry_test_case_id"]].join("|")
  end' "$E2E_DIR/scenarios.yml")"

CREATE_STATE_linux=""   # "", ok, failed
CREATE_STATE_windows=""
DELETED_linux=0
DELETED_windows=0
FAILS=0

while IFS='|' read -r id cmd os title qmetry; do
  [ -z "$id" ] && continue
  [ "$OS_FILTER" != all ] && [ "$OS_FILTER" != "$os" ] && continue
  if [ -n "$ONLY" ] && ! printf ',%s,' "$ONLY" | grep -qF ",$id,"; then continue; fi

  LOG="$RESULTS_DIR/$id.log"
  : > "$LOG"
  echo "[$id] $title (host: $HOST_PLATFORM)"
  start=$(date +%s)

  state_var="CREATE_STATE_$os"
  if [ "$cmd" != create ] && [ "${!state_var}" = failed ]; then
    status="SKIP"
    echo "skipped: create for $os failed earlier in this run" >> "$LOG"
  elif exec_scenario "$cmd" "$os"; then
    status="PASS"
  else
    status="FAIL"
    FAILS=$((FAILS + 1))
  fi

  if [ "$cmd" = create ]; then
    [ "$status" = PASS ] && eval "CREATE_STATE_$os=ok" || eval "CREATE_STATE_$os=failed"
  fi
  [ "$cmd" = delete ] && [ "$status" = PASS ] && eval "DELETED_$os=1"

  dur=$(( $(date +%s) - start ))
  echo "  -> $status (${dur}s)"
  printf '"%s","%s","%s","%s","%s","%s",%s,"%s"\n' \
    "$id" "$qmetry" "$title" "$HOST_PLATFORM" "$os" "$status" "$dur" "$LOG" >> "$SUMMARY"
done <<< "$SCEN_TSV"

if [ "$DRY_RUN" != 1 ]; then
  for os in linux windows; do
    created="CREATE_STATE_$os"; deleted="DELETED_$os"
    [ -n "${!created}" ] && [ "${!deleted}" != 1 ] || continue
    rg="$(cfg_get "$os" resource-group-name)"
    if [ "$CLEANUP_RG" = 1 ]; then
      echo "cleanup: deleting resource group $rg"
      az group delete --name "$rg" --yes --no-wait
    else
      echo "WARNING: $os VM may still exist in resource group $rg (use --cleanup-rg or delete manually)"
    fi
  done
fi

echo
echo "Results: $SUMMARY"
column -s, -t "$SUMMARY" 2>/dev/null | cut -c1-200 || cat "$SUMMARY"
[ "$FAILS" = 0 ]
