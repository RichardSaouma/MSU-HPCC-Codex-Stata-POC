#!/usr/bin/env bash
set -Eeuo pipefail

PYTHON_MODULE="${HPCC_PYTHON_MODULE:-Python/3.11.3-GCCcore-12.3.0}"
STATA_MODULE="${HPCC_STATA_MODULE:-Stata/18-MP}"
MCP_PORT="${STATA_MCP_PORT:-4000}"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }
OS_NAME="$(uname -s 2>/dev/null || printf '%s' unknown)"
[[ "$OS_NAME" == "Linux" ]] || fail "Run this on the remote HPCC Linux host."

if ! type module >/dev/null 2>&1; then
  for init in /etc/profile.d/modules.sh /usr/share/Modules/init/bash /usr/share/lmod/lmod/init/bash; do
    if [[ -r "$init" ]]; then
      set +e +u
      source "$init"
      set -e -u
      if type module >/dev/null 2>&1; then break; fi
    fi
  done
fi
type module >/dev/null 2>&1 || fail "The module command is unavailable."
module purge
module load "$STATA_MODULE"
STATA_BIN="$(command -v stata-mp || true)"
[[ -n "$STATA_BIN" ]] || fail "stata-mp not found after loading ${STATA_MODULE}."
STATA_BIN="$(readlink -f "$STATA_BIN" 2>/dev/null || printf '%s' "$STATA_BIN")"
STATA_ROOT="$(dirname "$STATA_BIN")"
STATA_UTILITIES="${STATA_ROOT}/utilities"
[[ -d "$STATA_UTILITIES/pystata" ]] || fail "Missing ${STATA_UTILITIES}/pystata."
pass "Stata module and executable found: ${STATA_BIN}"

module purge
module load "$PYTHON_MODULE"
export PATH="${STATA_ROOT}:$PATH"
pass "Python module loaded: ${PYTHON_MODULE}"

echo "INFO: Stata root: ${STATA_ROOT}"

mapfile -t MCP_EXTENSIONS < <(find "${HOME}/.vscode-server/extensions" -maxdepth 1 -mindepth 1 -type d -name 'deepecon.stata-mcp-*' -print 2>/dev/null | sort -V || true)
(( ${#MCP_EXTENSIONS[@]} > 0 )) || fail "Stata MCP extension not found."
MCP_EXTENSION="${MCP_EXTENSIONS[${#MCP_EXTENSIONS[@]}-1]}"
echo "INFO: using newest discovered Stata MCP extension: ${MCP_EXTENSION}"
MCP_PYTHON="${MCP_EXTENSION}/.venv/bin/python"
[[ -x "$MCP_PYTHON" ]] || fail "MCP Python missing: ${MCP_PYTHON}"
pass "Stata MCP extension and private Python found"

"$MCP_PYTHON" -c 'import pystata, stata_setup; print("pystata and stata_setup imports: OK")' || fail "MCP Python cannot import pystata and stata_setup."
"$MCP_PYTHON" -c 'from pystata import config; config.init("mp", splash=False); print("PyStata initialization: OK")' || fail "PyStata initialization failed."
pass "PyStata is visible to the MCP environment"

SITE_PACKAGES="$("$MCP_PYTHON" -c 'import site; print(site.getsitepackages()[0])')"
PTH_FILE="${SITE_PACKAGES}/msu-stata.pth"
[[ -f "$PTH_FILE" ]] || fail "Missing PyStata path file: ${PTH_FILE}"
grep -Fxq "$STATA_UTILITIES" "$PTH_FILE" || fail "PyStata path file does not point to ${STATA_UTILITIES}: ${PTH_FILE}"
pass "MCP venv .pth points to the Stata utilities directory"

mapfile -t CODEX_BINARIES < <(find "${HOME}/.vscode-server/extensions" -type f -path '*/openai.chatgpt-*/bin/linux-x86_64/codex' -print 2>/dev/null | sort -V || true)
if (( ${#CODEX_BINARIES[@]} > 0 )); then
  CODEX="${CODEX_BINARIES[${#CODEX_BINARIES[@]}-1]}"
  pass "remote Codex binary found: ${CODEX}"
  CODEX_MCP_LIST="$("$CODEX" mcp list 2>/dev/null || true)"
  if printf '%s\n' "$CODEX_MCP_LIST" | grep -q '^stata-hpcc[[:space:]]'; then
    pass "remote Codex has stata-hpcc registered"
  else
    echo "WARN: remote Codex does not currently show stata-hpcc; rerun setup-hpcc.sh to register it." >&2
  fi
else
  echo "WARN: remote Codex binary not found; install/open the remote Codex extension before the end-to-end test." >&2
fi

MCP_HEALTH_OK=0
if command -v curl >/dev/null 2>&1; then
  HEALTH="$(curl -fsS --max-time 5 "http://localhost:${MCP_PORT}/health" 2>/dev/null || true)"
  if [[ "$HEALTH" == *'"stata_available":true'* ]]; then
    MCP_HEALTH_OK=1
    pass "Stata MCP health: ${HEALTH}"
  elif [[ -n "$HEALTH" ]]; then
    echo "WARN: MCP health responded but Stata is unavailable: ${HEALTH}" >&2
  else
    echo "WARN: MCP health endpoint is not running at localhost:${MCP_PORT}; reload/start the remote extension, then rerun verification." >&2
  fi
else
  echo "WARN: curl is unavailable; MCP health was not checked." >&2
fi

if [[ "${HPCC_RUN_STATA_SMOKE_TEST:-1}" == "1" ]]; then
  RESULT="$(module purge >/dev/null 2>&1; module load "$STATA_MODULE" >/dev/null 2>&1; printf 'display 2 + 2\nexit, clear\n' | stata-mp -q 2>&1)" || fail "Stata smoke test failed."
  [[ "$RESULT" == *$'4'* ]] || fail "Smoke test did not contain result 4: ${RESULT}"
  pass "Stata smoke test: display 2 + 2 -> 4"
fi

echo
if [[ "$MCP_HEALTH_OK" == "1" ]]; then
  echo "Stata MCP ready: Stata available: true"
else
  echo "Local HPCC/PyStata checks passed; complete MCP activation and rerun to confirm Stata available: true."
fi
