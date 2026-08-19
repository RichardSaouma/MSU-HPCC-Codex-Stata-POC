#!/usr/bin/env bash
set -Eeuo pipefail

PYTHON_MODULE="${HPCC_PYTHON_MODULE:-Python/3.11.3-GCCcore-12.3.0}"
STATA_MODULE="${HPCC_STATA_MODULE:-Stata/18-MP}"
MCP_PORT="${STATA_MCP_PORT:-4000}"
CONFIGURE_CODEX="${HPCC_CONFIGURE_CODEX_MCP:-1}"

fail() { echo "ERROR: $*" >&2; exit 1; }
note() { echo "[setup] $*"; }
trap 'echo "ERROR: setup failed near line ${LINENO}." >&2' ERR

OS_NAME="$(uname -s 2>/dev/null || printf '%s' unknown)"
[[ "$OS_NAME" == "Linux" ]] || fail "Run this on the remote HPCC Linux host."

if ! type module >/dev/null 2>&1; then
  for init in /etc/profile.d/modules.sh /usr/share/Modules/init/bash /usr/share/lmod/lmod/init/bash; do
    if [[ -r "$init" ]]; then
      # HPCC EESSI/Lmod initialization can return nonzero intermediate
      # statuses in non-interactive shells; verify the module function after it.
      trap - ERR
      set +e +u
      source "$init"
      set -e -u
      trap 'echo "ERROR: setup failed near line ${LINENO}." >&2' ERR
      if type module >/dev/null 2>&1; then break; fi
    fi
  done
fi
type module >/dev/null 2>&1 || fail "The environment module command is unavailable."

note "Loading ${STATA_MODULE} after clearing inherited modules to discover Stata."
module purge
module load "$STATA_MODULE"

STATA_BIN="$(command -v stata-mp || true)"
[[ -n "$STATA_BIN" ]] || fail "stata-mp was not found after loading ${STATA_MODULE}."
STATA_BIN="$(readlink -f "$STATA_BIN" 2>/dev/null || printf '%s' "$STATA_BIN")"
STATA_ROOT="$(dirname "$STATA_BIN")"
STATA_UTILITIES="${STATA_ROOT}/utilities"
[[ -d "$STATA_UTILITIES/pystata" ]] || fail "Missing ${STATA_UTILITIES}/pystata."

note "Purging the Stata context and loading ${PYTHON_MODULE} for the MCP venv."
module purge
module load "$PYTHON_MODULE"
export PATH="${STATA_ROOT}:$PATH"

mapfile -t MCP_EXTENSIONS < <(find "${HOME}/.vscode-server/extensions" -maxdepth 1 -mindepth 1 -type d -name 'deepecon.stata-mcp-*' -print 2>/dev/null | sort -V || true)
(( ${#MCP_EXTENSIONS[@]} > 0 )) || fail "Install deepecon.stata-mcp in the remote window, then rerun."
MCP_EXTENSION="${MCP_EXTENSIONS[${#MCP_EXTENSIONS[@]}-1]}"
note "Using newest discovered Stata MCP extension: ${MCP_EXTENSION}"
MCP_VENV="${MCP_EXTENSION}/.venv"
MCP_PYTHON="${MCP_VENV}/bin/python"
[[ -x "$MCP_PYTHON" ]] || fail "Missing MCP Python: ${MCP_PYTHON}"

if ! "$MCP_PYTHON" -c 'import pystata, stata_setup' >/dev/null 2>&1; then
  command -v uv >/dev/null 2>&1 || fail "uv is required to install stata-setup."
  note "Installing stata-setup into the MCP private environment."
  uv pip install --python "$MCP_PYTHON" stata-setup
fi

SITE_PACKAGES="$("$MCP_PYTHON" -c 'import site; print(site.getsitepackages()[0])')"
PTH_FILE="${SITE_PACKAGES}/msu-stata.pth"
if [[ ! -f "$PTH_FILE" ]] || [[ "$(<"$PTH_FILE")" != "$STATA_UTILITIES" ]]; then
  printf '%s\n' "$STATA_UTILITIES" > "$PTH_FILE"
  note "Installed ${PTH_FILE}"
fi

"$MCP_PYTHON" -c 'import pystata, stata_setup; print("pystata and stata_setup imports: OK")'
"$MCP_PYTHON" -c 'from pystata import config; config.init("mp", splash=False); print("PyStata initialization: OK")'

mapfile -t CODEX_BINARIES < <(find "${HOME}/.vscode-server/extensions" -type f -path '*/openai.chatgpt-*/bin/linux-x86_64/codex' -print 2>/dev/null | sort -V || true)
if (( ${#CODEX_BINARIES[@]} > 0 )); then
  CODEX="${CODEX_BINARIES[${#CODEX_BINARIES[@]}-1]}"
  if [[ "$CONFIGURE_CODEX" == "1" ]]; then
    if ! "$CODEX" mcp list 2>/dev/null | grep -q '^stata-hpcc[[:space:]]'; then
      note "Registering stata-hpcc with remote Codex."
      "$CODEX" mcp add stata-hpcc --url "http://localhost:${MCP_PORT}/mcp-streamable"
    fi
  fi
else
  note "Remote Codex binary not found; install/open the Codex extension and rerun."
fi

if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 3 "http://localhost:${MCP_PORT}/health" >/dev/null 2>&1; then
  note "Stata MCP health endpoint: OK"
else
  note "Stata MCP health endpoint is not responding; reload/start the remote extension."
fi

cat <<SUMMARY

Setup completed.
  Host:             $(hostname)
  Home:             ${HOME}
  Python module:    ${PYTHON_MODULE}
  Stata module:     ${STATA_MODULE}
  Stata root:       ${STATA_ROOT}
  MCP extension:    ${MCP_EXTENSION}
  MCP endpoint:     http://localhost:${MCP_PORT}/mcp-streamable

Next: run scripts/verify-hpcc.sh, then ask remote Codex to run display 2 + 2.
SUMMARY
