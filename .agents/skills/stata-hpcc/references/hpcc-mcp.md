# The stata-hpcc MCP server: mechanics and failure modes

## How it fits together

```
VS Code (laptop) --SSH--> hpcc.msu.edu --> dev-amd24
                                              |
                                        Codex (remote)
                                              |
                                     stata-hpcc MCP server
                                        (localhost:<port>)
                                              |
                                          Stata 18-MP
```

The MCP server is an HTTP process started by the `deepecon.stata-mcp` VS Code
extension, running as the user, on a port set in VS Code's **Remote** settings.

## Tools

- `stata_run_selection` — run a short snippet. Good for `display`, `describe`,
  quick checks.
- `stata_run_file` — run a `.do` file. Preferred for anything real.

## Failure mode 1: you are in someone else's Stata session

The extension defaults to port 4000 and, unless `stata-vscode.forcePort` is
true, will silently attach to an existing server on that port — including one
belonging to another user. Symptoms:

- `display "`c(pwd)'"` returns a path under a different username
- Files "written successfully" cannot be read back (permission denied)
- Everything else passes, including smoke tests

Diagnosis:

```bash
ss -ltnp | grep <port>          # a listener with NO PID belongs to someone else
grep url ~/.codex/config.toml   # must match the port in Remote settings
```

Fix: set a per-user port in VS Code Remote settings
(`"stata-vscode.mcpServerPort": <10000 + uid % 20000>`, `"forcePort": true`),
reload, then point Codex at it and start a **new Codex chat**.

## Failure mode 2: Codex says the server is "not connected in this session"

Codex loads MCP servers when a conversation starts. After any window reload or
config change, start a **new chat** — the running one will never see it.

## Failure mode 3: output lands somewhere unexpected

The server's working directory is not necessarily the project folder. Always
use absolute paths. To pin the session:

```stata
cd "/mnt/home/<netid>/<project>"
```

## Where output goes

- Graphs: wherever `graph export` is told to write. Use an absolute path.
- Server log: `~/.vscode-server/extensions/deepecon.stata-mcp-*/logs/stata_mcp_server.log`
- Viewing a PNG: it is on HPCC — open it in VS Code's file explorer. No
  download tool is needed, and its absence is not a limitation of the setup.
