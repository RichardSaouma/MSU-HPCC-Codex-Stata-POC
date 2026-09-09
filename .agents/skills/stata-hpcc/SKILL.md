---
name: stata-hpcc
description: Use when Codex is running in a Remote-SSH VS Code window on MSU HPCC and the user asks it to run Stata through the stata-hpcc MCP server. Covers the verified remote setup and safe use of HPCC-resident files; do not use for local Stata.
---

# Stata on the MSU HPCC

Use this skill only after VS Code has connected to HPCC with Remote-SSH. Stata
runs through the `stata-hpcc` MCP server on the same HPCC development node as
remote Codex.

## Confirm the session before Stata work

Before the first Stata action in a session:

1. In the HPCC terminal, run `whoami` to identify the connected HPCC account.
2. With `stata_run_selection`, run:

   ```stata
   display "`c(pwd)'"
   ```

3. Continue only if the returned path is under that account's HPCC home
   directory. The server may begin in a VS Code extension folder rather than in
   the project folder; that is normal.
4. If the account does not match, do not read or write files through Stata. Run
   `bash scripts/verify-hpcc.sh`, then tell the user that the Stata MCP session
   needs attention.

Do not change the MCP port or VS Code settings from this skill. This project's
setup script owns that configuration.

## Run Stata and work with files

- Use `stata_run_selection` for short checks and small commands.
- For a reproducible analysis, create or run a `.do` file only when the user
  asks for it; explain the file changed and show its location.
- Use full HPCC paths for Stata files when the working directory could be
  ambiguous. Students may work with either data uploaded from their computer or
  data already stored on HPCC.
- Do not overwrite an existing source-data or analysis file unless the user
  asked to change that specific file. Check the result before reporting success.
