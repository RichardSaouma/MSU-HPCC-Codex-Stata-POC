# Agent instructions

This standalone repository packages the verified workflow. It is intentionally separate from the known-good HPCC reference checkout; treat that checkout as read-only reference material.

This repository's root is StudentDemo. Do not nest it inside another repository and do not copy its .git directory into HPCC.

The verified workflow is:

VS Code -> Remote-SSH -> MSU HPCC development node -> remote Codex -> Stata MCP -> MSU Stata 18-MP -> HPCC data

Keep the remote HPCC workflow primary. The local-Codex/forwarded-MCP workflow belongs only in the README fallback appendix.

## Safety

- Never commit SSH private keys, credentials, tokens, virtual environments, or personal configuration.
- Do not modify production VS Code, Claude, Stata, or global SSH configuration.
- Use placeholders and environment variables for NetID, hostnames, project accounts, and paths.
- Never submit SLURM jobs from setup or verification scripts.

## Implementation rules

- Preserve module purge before loading Python and Stata.
- Prefer dynamic discovery over version-specific extension paths.
- Make scripts safe to rerun and fail with actionable messages.
- Do not replace working behavior with untested compatibility workarounds.
- Do not commit or push unless explicitly requested.
