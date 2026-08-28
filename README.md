# Run Stata on the MSU HPCC with an AI assistant

This project connects VS Code on your own computer, Stata on Michigan State University's High Performance Computing Cluster (HPCC), and the OpenAI Codex AI assistant. You write in VS Code and ask Codex to run Stata on HPCC. Stata and the Codex tools run on HPCC; you can use data already stored there or upload local data when you need the remote tools to use it.

You do not need to know Linux to follow the main path. You copy commands from this page into the stated terminal, and two scripts do the technical work.

## 1. Before you start

Complete this checklist before beginning. HPCC and GitHub access can take time to arrange.

| You need | Details |
|---|---|
| MSU HPCC account | Request one through [ICER](https://docs.icer.msu.edu/). Your instructor may arrange this for you. |
| MSU NetID | The part of your email before `@msu.edu`. For example, `AccountingRocks@msu.edu` has the NetID `AccountingRocks`. |
| VS Code | Download it from [code.visualstudio.com](https://code.visualstudio.com/download). |
| ChatGPT or OpenAI account | Codex needs an account. Ask your instructor which account or plan to use. |
| GitHub account | It must have access to this private repository. Send your GitHub username to your instructor if you do not have access. |
| SSH key | Step 4 creates one unless MSU or your instructor already gave you one. |

Plan about 90 minutes for the first installation. Later, a normal work session takes only a few minutes.

## 2. Three places you will use

Every command below has one of these labels. Use the stated place.

| Label | Where to use it |
|---|---|
| **[LOCAL SHELL]** | PowerShell on Windows or Terminal on macOS/Linux, on your own computer. |
| **[LOCAL VS CODE]** | The VS Code application on your own computer. |
| **[HPCC TERMINAL]** | Terminal > New Terminal inside the VS Code window after it is connected to HPCC. |

After step 6, use **[HPCC TERMINAL]** for HPCC commands. Do not run a separate `ssh` session in PowerShell.

## 3. How the parts connect

```text
Your computer                         MSU HPCC
-------------                         --------
VS Code
  -> Remote-SSH extension --------->  gateway (hpcc.msu.edu)
                                         -> development node (dev-amd24)
                                              -> Codex assistant
                                                   -> Stata MCP server
                                                        -> Stata 18-MP
```

The gateway is the entry door. The development node is where you work. VS Code connects you to `hpcc-dev`, which passes through the gateway automatically.

## 4. Create your HPCC SSH key

An SSH key is a pair of files. The private file stays on your computer. The public file goes to HPCC. Never send the private file to anyone.

If your instructor or MSU already gave you an HPCC SSH key, skip to step 5.

**[LOCAL SHELL] — Windows PowerShell. Do not use Administrator PowerShell.**

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\msu_hpcc" -C "MSU HPCC"
```

**[LOCAL SHELL] — macOS or Linux Terminal.**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/msu_hpcc -C "MSU HPCC"
```

The command asks for a passphrase and creates two files:

- `msu_hpcc` — your private key; it stays on your computer.
- `msu_hpcc.pub` — your public key; it goes to HPCC.

Install the public key on HPCC using the [MSU SSH key instructions](https://docs.icer.msu.edu/SSH_Key-Based_Authentication/). If you already have a key installed, do not repeat this step.

### Optional: let Windows remember the passphrase

**[LOCAL SHELL] — regular Windows PowerShell.**

```powershell
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add "$HOME\.ssh\msu_hpcc"
ssh-add -l
```

If Windows shows **Access denied** on either of the first two commands, open **PowerShell as Administrator**, run only those two commands again, then return to regular PowerShell for `ssh-add` and `ssh-add -l`.

## 5. Write your SSH configuration file

This file tells VS Code how to reach HPCC. It stays on your computer.

Create or open:

- Windows: `C:\Users\<your-name>\.ssh\config`
- macOS/Linux: `~/.ssh/config`

Add this text. Replace `AccountingRocks` with your own NetID in both places.

```text
Host hpcc-gateway
    HostName hpcc.msu.edu
    User AccountingRocks
    IdentityFile ~/.ssh/msu_hpcc

Host hpcc-dev
    HostName dev-amd24
    User AccountingRocks
    IdentityFile ~/.ssh/msu_hpcc
    ProxyJump hpcc-gateway
```

`hpcc-gateway` is the door. `hpcc-dev` is the place where you work. Always connect to **hpcc-dev**. The `dev-amd24` name is the class example; use a different development node only if MSU or your instructor tells you to.

Never commit this personal configuration file or your private key to GitHub. The repository’s `ssh/config.example` contains the same example for reference after you clone.

## 6. Connect VS Code to HPCC

1. **[LOCAL VS CODE]** Install the [Remote - SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh).
2. Press `F1` and choose **Remote-SSH: Connect to Host...**.
3. Select **hpcc-dev**. Do not select `hpcc-gateway`.
4. Wait for the new VS Code window to open. The first connection can take several minutes.

VS Code makes the SSH connection in the background. Work in the new VS Code window and in its terminal; do not open a separate PowerShell SSH session.

If the connection reports `Home directory not found` or `Could not chdir to home directory`, your HPCC account is not ready. Contact ICER or your instructor; this is usually an account issue, not a key issue.

## 7. Copy the project to HPCC

This repository is private. HPCC needs a GitHub SSH key to copy it. This key is separate from your HPCC login key.

**[HPCC TERMINAL]** In the new VS Code window, choose **Terminal > New Terminal**, then run:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github -C "HPCC GitHub" -N ""
cat ~/.ssh/github.pub
```

Copy the printed line. In a web browser, open [GitHub SSH keys](https://github.com/settings/keys), choose **New SSH key**, and paste the line. Your GitHub account must have access to this private repository.

**[HPCC TERMINAL]** Tell SSH to use that key for GitHub:

```bash
printf 'Host github.com\n  IdentityFile ~/.ssh/github\n' >> ~/.ssh/config
```

**[HPCC TERMINAL]** Now copy the project:

```bash
git clone git@github.com:RichardSaouma/MSU-HPCC-Codex-Stata-POC.git
cd MSU-HPCC-Codex-Stata-POC
```

If Git reports `Repository not found`, your GitHub account does not have access yet. Send your GitHub username to your instructor.

Open the new folder in the same VS Code window: choose **File > Open Folder**, then select `MSU-HPCC-Codex-Stata-POC`.

## 8. Install the recommended extensions

VS Code normally displays a notification saying the workspace has extension recommendations. Click **Install** to install all recommendations, or **Show Recommendations** to review them one at a time. If no notification appears, open Extensions and search for `@recommended`.

Install these extensions in the **remote VS Code window**, not the local window:

- Codex — `openai.chatgpt`
- Stata MCP — `deepecon.stata-mcp`
- Stata Workbench — `tmonk.stata-workbench`
- Python — `ms-python.python`
- Python Environments — `ms-python.vscode-python-envs`

The Remote-SSH extension belongs on your computer. The extensions above belong on HPCC. Look for **Install in SSH: hpcc-dev** on an extension page.

## 9. Sign in to Codex

**[LOCAL VS CODE]** In the remote VS Code window, open the Codex panel and sign in with your ChatGPT or OpenAI account.

The sign-in page opens in a browser on your computer. Complete sign-in there, then return to the remote VS Code window. Do not paste an API key, password, or token into this repository or into any command here.

## 10. Run the setup script

**[HPCC TERMINAL]**

```bash
bash scripts/setup-hpcc.sh
```

The script finds Stata, Python, PyStata, the Stata MCP extension, and Codex, then connects them. It is safe to run again. If extensions are still installing, wait and run the command again.

If HPCC uses different module names (unlikely; these names were used by the validated setup), an instructor can override them:

**[HPCC TERMINAL]**

```bash
HPCC_PYTHON_MODULE='<PYTHON_MODULE>' HPCC_STATA_MODULE='<STATA_MODULE>' bash scripts/setup-hpcc.sh
```

## 11. Check the setup

**[HPCC TERMINAL]**

```bash
bash scripts/verify-hpcc.sh
```

A correct result contains lines like these:

```text
PASS: Stata module and executable found: ...
PASS: PyStata is visible to the MCP environment
PASS: remote Codex has stata-hpcc registered
PASS: Stata MCP health: ... "stata_available":true ...
PASS: Stata smoke test: display 2 + 2 -> 4

Stata MCP ready: Stata available: true
```

The final line is the important one. Continue only when you see `Stata available: true`. Warnings can appear while the Stata MCP extension is still starting; wait briefly and run the check again.

## 12. Test Codex with Stata

**[LOCAL VS CODE]** In the VS Code window connected to HPCC, open the Codex panel. This is the Codex agent operating on HPCC, not a separate local Codex session.

Ask Codex:

```text
Use the stata-hpcc MCP server and run: display 2 + 2
```

Codex should use `stata_run_selection`, and Stata should return `4`. You do not need to configure an MCP URL or forward a port on your computer.

## Your normal work session

After the first setup:

1. Start VS Code on your computer.
2. Choose **Remote-SSH: Connect to Host... > hpcc-dev**.
3. Open the project folder on HPCC.
4. Open the Codex panel and give it work.

Run `bash scripts/setup-hpcc.sh` again in the **[HPCC TERMINAL]** after the Codex or Stata MCP extension is updated, after MSU changes the Python or Stata modules, or when verification tells you to rerun setup.

## Rules and limits

- Development nodes are for setup and small tests. Ask your instructor before using this workflow for long or resource-heavy work.
- You can use data stored on your computer or data already on HPCC. Local files are not automatically visible to Stata on HPCC; upload or copy them to HPCC before asking remote Codex or Stata to use them.
- Follow your course and research requirements for where data may be stored.
- Never commit a private key, password, token, or personal SSH configuration to GitHub.

## Troubleshooting

### The check says `Stata available: false`

The Stata MCP extension is not running or cannot reach Stata. In the remote VS Code window, use `F1 > Developer: Reload Window`, wait briefly, then run:

**[HPCC TERMINAL]**

```bash
bash scripts/verify-hpcc.sh
```

### `No module named pystata` or `No module named stata_setup`

The MCP Python environment cannot see the MSU PyStata files.

**[HPCC TERMINAL]**

```bash
bash scripts/setup-hpcc.sh
```

### `uv is required to install stata-setup`

The Stata MCP extension did not finish installing its private Python environment. In the remote VS Code window, open Extensions, remove `deepecon.stata-mcp`, install it again, wait for installation to finish, then rerun setup.

### `libpython3.11.so.1.0` is missing

The matching Python module is not loaded in the HPCC terminal.

**[HPCC TERMINAL]**

```bash
module purge
module load Python/3.11.3-GCCcore-12.3.0
```

### `Remote Codex binary not found`

The Codex extension is not installed in the remote VS Code window or has not started. Install it there, open the Codex panel once, and rerun setup. Do not install Codex with `apt`.

### The Stata MCP address is already in use

Another process on the development node may already be using port 4000.

**[HPCC TERMINAL]**

```bash
ss -ltnp | grep 4000
```

If the process is not yours, ask your instructor for a different port. The same port must be used by the Stata MCP extension and the setup script. The setup script accepts a different port like this:

**[HPCC TERMINAL]**

```bash
STATA_MCP_PORT=4137 bash scripts/setup-hpcc.sh
```

### Stata is not found even though the module loaded

MSU may have moved the Stata installation. Compare the `Stata root:` line printed by setup with the path in `.vscode/settings.json`. Ask your instructor before changing the shared setting.

### Remote-SSH hangs or reports a Node `navigator` error

Update VS Code and the Remote-SSH and Codex extensions on your computer. Disconnect and reconnect to `hpcc-dev`, not `hpcc-gateway`. If the problem continues, check the [MSU VS Code over SSH instructions](https://docs.icer.msu.edu/Connect_over_SSH_with_VS_Code/).

## What is in this repository

| File | Purpose |
|---|---|
| `README.md` | These instructions. |
| `scripts/setup-hpcc.sh` | Prepares Python, Stata, PyStata, Stata MCP, and Codex on HPCC. |
| `scripts/verify-hpcc.sh` | Checks the setup and makes Stata calculate `2 + 2`. |
| `ssh/config.example` | A copy of the example SSH configuration from step 5. |
| `.vscode/extensions.json` | The recommended remote VS Code extensions. |
| `.vscode/settings.json` | The Stata path and edition setting. |
| `AGENTS.md` | Instructions for Codex when it changes this project. |
| `.gitignore`, `.gitattributes` | Keep personal files out of Git and keep text compatible across systems. |

## Short glossary

- **HPCC:** MSU's shared high-performance computing system.
- **NetID:** The part of your MSU email address before `@msu.edu`.
- **SSH:** The secure connection method used by Remote-SSH.
- **Gateway:** The HPCC entry point. You pass through it; you do not work there.
- **Development node:** The HPCC computer where this project runs.
- **MCP:** The connection that lets Codex operate Stata.
- **PyStata:** The Python interface used by the Stata MCP server.
- **Health check:** A quick status check that reports whether Stata is available.

## Appendix: local Codex fallback

The preferred workflow uses Codex in the Remote-SSH VS Code window. A local Codex session with a forwarded remote MCP server is a fallback only. It requires port forwarding and separate local MCP configuration, so use it only when remote Codex cannot run.

## Further information

- [MSU HPCC connection guide](https://docs.icer.msu.edu/Connect_to_HPCC_System/)
- [SSH key authentication](https://docs.icer.msu.edu/SSH_Key-Based_Authentication/)
- [VS Code over SSH](https://docs.icer.msu.edu/Connect_over_SSH_with_VS_Code/)
- [Stata on HPCC](https://docs.icer.msu.edu/Stata/)
- [Home space](https://docs.icer.msu.edu/Home_Space/)
- [Codex and VS Code guide](https://claesbackman.com/codex-vscode-guide.html)
- [OpenEcon Stata MCP](https://openecon.ai/projects/stata-mcp)
- [Stata MCP repository](https://github.com/hanlulong/stata-mcp)
