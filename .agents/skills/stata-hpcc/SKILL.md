---
name: stata-hpcc
description: Run Stata on the MSU HPCC through the stata-hpcc MCP server. Use for any Stata work on HPCC — writing or running do-files, regressions, data cleaning, tables, graphs — and before creating files or submitting batch jobs there. Covers session-ownership safety checks, absolute-path rules, do-file structure, SLURM batch submission, and looking up syntax in Stata's local PDF manuals. Do not use for Stata running on a local laptop.
---

# Stata on the MSU HPCC

You are working on a **shared** HPCC development node. Stata runs through the
`stata-hpcc` MCP server (`stata_run_selection`, `stata_run_file`). Several
people share this machine, so a mistake here can write into someone else's
account or consume a scarce Stata MP license.

## Relationship to the other Stata skills

The `stata-*` skills that ship with `mcp-stata` (`stata-run`, `stata-graph`,
`stata-causal-inference`, `stata-table-builder`, and the rest) own **econometric
technique and Stata craft**. Defer to them for that. This skill owns only the
**MSU HPCC environment**: whose session you are in, where files may be written,
module names, license limits, and when to submit a batch job. Do not restate or
contradict their guidance.

## Session check — run once per session, before writing anything

```stata
display "`c(pwd)'"
```

Read the **username** in the returned path, and nothing else:

- **A username other than the current user** (e.g. `/mnt/ffs24/home/someoneelse/...`)
  → **STOP. Do not run anything that writes.** The MCP server belongs to another
  user. Tell the user to compare `grep url ~/.codex/config.toml` against
  `ss -ltnp | grep <their port>`. See `references/hpcc-mcp.md`.
- **The current user's own username** → everything is fine. Proceed.

Being in a directory other than the project folder is **not** a problem and never
a reason to stop. `/mnt/ffs24/home/<netid>/.vscode-server/...` is normal — the
server starts in its own directory. Note also that `/mnt/home/<netid>` and
`/mnt/ffs24/home/<netid>` are the same place; the second is what the first
resolves to. Neither is a mismatch.

If the working directory is not the project folder, just set it and carry on:

```stata
cd "/mnt/home/<netid>/<project>"
```

## Non-negotiable rules

1. **Absolute paths always.** Every `use`, `save`, `graph export`, `log using`,
   `export delimited`, and `estout`/`esttab` output takes a full path starting
   `/mnt/home/<netid>/...`. Bare filenames land in whatever the server's working
   directory happens to be.
2. **Verify what you claim.** After writing a file, confirm it with `ls -la` (or
   Stata's `confirm file`) before reporting success. Never report a path you
   have not checked.
3. **Before editing any file that already exists, run this first — every time,
   no exceptions:**

   ```bash
   bash ~/.agents/skills/stata-hpcc/scripts/safe-edit.sh "<absolute path>" "<what you are changing>"
   ```

   It backs the file up (or confirms git already has it) and records the change
   in `logs/file-changes.log`, in one call. Run it *before* the edit, not after.
   If you edited a file without running it, run it now and say that the log
   entry is retrospective.

   Then edit, and tell the user which file changed and where the old version
   went. Never write to `data/raw/`. Do not overwrite a file the user did not
   name — write a new one and say what you called it.

   **Skip the script entirely for regenerable outputs** — tables, figures,
   logs, and anything under `output/`, `results/`, `figures/`, or `tables/`.
   Overwrite those freely, and never refuse to run a do-file because it would
   replace its own output.

   Full procedure and edge cases in `references/file-safety.md`.
4. **Dev node is for small work.** Anything long-running, memory-hungry, or
   parallel goes to SLURM — see `references/slurm.md`. Say so rather than
   quietly running a 40-minute job on a shared login node.
5. **Free the license.** Stata MP seats are limited campus-wide. Don't leave
   idle interactive sessions holding one.
6. **Look up syntax, don't guess.** Stata's full PDF manuals are installed
   locally — see `references/stata-docs.md`. Prefer `help <command>` first.

## Writing do-files

Follow the structure in `references/do-file-conventions.md`: a header block,
`version 18`, explicit `set seed`, logging, paths defined once as globals at the
top, and one do-file per analytical step.

Prefer creating a `.do` file and running it with `stata_run_file` over sending
long command sequences through `stata_run_selection`. The do-file is the
reproducible artifact; the chat transcript is not.

## Reporting results

Show the actual Stata output — coefficient tables, N, R², error messages —
rather than paraphrasing. If Stata errors, show the error code and the offending
line. Do not silently retry with different code.

## When to stop and ask

Stop only for: a session owned by another user, a command that would overwrite
existing data, or a job that clearly belongs on the scheduler. Everything else,
proceed and report what you did.
