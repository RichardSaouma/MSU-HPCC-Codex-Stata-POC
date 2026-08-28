#!/usr/bin/env bash
# Confirms the stata-hpcc MCP server belongs to you before you trust it.
# Usage: bash check-session.sh [port]
PORT="${1:-$(( 10000 + $(id -u) % 20000 ))}"

echo "== expected port: $PORT"
echo
echo "== Codex is pointed at:"
grep -H url "$HOME/.codex/config.toml" 2>/dev/null || echo "  (no ~/.codex/config.toml)"
echo
echo "== listener on $PORT:"
if ss -ltnp 2>/dev/null | grep -q ":$PORT "; then
  ss -ltnp | grep ":$PORT "
  if ss -ltnp 2>/dev/null | grep ":$PORT " | grep -q "pid="; then
    echo "  OK: process is yours."
  else
    echo "  WARNING: no PID shown — this server belongs to another user."
  fi
else
  echo "  nothing listening. Open a .do file in VS Code to start the extension."
fi
echo
echo "== port 4000 (the shared default — should not be yours):"
ss -ltnp 2>/dev/null | grep ":4000 " || echo "  free"
echo
echo "Now ask Codex, in a NEW chat:"
echo "  Using the stata-hpcc MCP server, run: display \"\`c(pwd)'\""
echo "The answer must be under $HOME"
