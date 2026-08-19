# MSU HPCC + Codex + Stata MCP

This project gives you a ready-to-use way to work with Stata on Michigan State University's High Performance Computing Cluster (HPCC) from your own computer. You use VS Code on your computer as the interface, connect to HPCC, and ask the OpenAI Codex agent in that connection to help you run Stata. This lets you combine your familiar local workflow with HPCC's Stata installation and computing environment.

In everyday use, you will connect to HPCC from VS Code, clone this repository on HPCC, open the new project folder in the connected window, and follow the setup steps.

## How the setup works

The preferred setup is:

    🧩 Local VS Code
        -> 🔌 Remote-SSH
        -> 🖥️ MSU HPCC development node
        -> 🤖 remote Codex
        -> Stata MCP
        -> MSU Stata 18-MP
        -> HPCC-resident data

The goal is to let the Codex agent in the HPCC-connected VS Code window run Stata commands while the code, Stata installation, and research data remain on HPCC.

## Prerequisites

You need:

- an MSU HPCC account and NetID (the part before `@msu.edu`; for example, `AccountingRocks@msu.edu` has the NetID `AccountingRocks`);
- permission to use HPCC;
- local VS Code;
- an SSH key kept on your local computer.

This repository provides workspace recommendations, setup and verification scripts, and documentation. It does not contain VS Code, extensions, private keys, credentials, virtual environments, or personal HPCC configuration.

## What the files are for

- `README.md`: these instructions.
- `.vscode/extensions.json`: the extensions VS Code recommends when this project folder is opened.
- `.vscode/settings.json`: the shared Stata settings for the MSU installation.
- `scripts/setup-hpcc.sh`: prepares Python, Stata, PyStata, Stata MCP, and remote Codex on HPCC.
- `scripts/verify-hpcc.sh`: checks that the setup is working and that Stata can calculate `2 + 2`.
- `ssh/config.example`: a template for your personal SSH connection settings. It contains placeholders only; do not edit and commit it with your personal values.
- `AGENTS.md`: instructions for Codex when it works on this project.
- `.gitignore` and `.gitattributes`: keep personal files out of Git and make text files work correctly on Linux and Windows.

## 1. Obtain HPCC access

Start with the [MSU HPCC connection documentation](https://docs.icer.msu.edu/Connect_to_HPCC_System/). The gateway is hpcc.msu.edu; authenticate with your own MSU NetID.

If SSH reports Home directory not found or Could not chdir to home directory, this may be an account-provisioning issue rather than an SSH-key problem.

Useful references:

- [SSH key-based authentication](https://docs.icer.msu.edu/SSH_Key-Based_Authentication/)
- [VS Code over SSH](https://docs.icer.msu.edu/Connect_over_SSH_with_VS_Code/)
- [Stata on HPCC](https://docs.icer.msu.edu/Stata/)
- [Available software](https://docs.icer.msu.edu/available_software/overview/)
- [Home space](https://docs.icer.msu.edu/Home_Space/)

## 2. Set up your SSH key

If your instructor or MSU has already given you an SSH key, use that key and skip to step 3. Otherwise, keep the private key on your Windows PC and never put it in this repository. Open a **regular PowerShell window on your PC (not Administrator PowerShell)** and run:

    ssh-keygen -t ed25519 -f "$HOME\.ssh\msu_hpcc" -C "MSU HPCC"

Install the public key on HPCC as described in the [MSU SSH key instructions](https://docs.icer.msu.edu/SSH_Key-Based_Authentication/). If you already have a key installed, do not repeat this step.

If you want Windows to remember the key passphrase, run these commands in **regular PowerShell on your PC**:

    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ssh-add "$HOME\.ssh\msu_hpcc"
    ssh-add -l

If Windows reports **Access denied** on either service command, close PowerShell, open **PowerShell as Administrator** from the Windows Start menu, and run only those first two service commands again. Then return to regular PowerShell for `ssh-add` and `ssh-add -l`.

## 3. Configure Remote-SSH

In **🧩 VS Code on your PC**, install the [Microsoft Remote - SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh). Use VS Code's **🔌 Remote-SSH: Connect to Host...** command to connect to HPCC. Connect onward to a development node when prompted; do not run the tools on the gateway.

If VS Code asks for an SSH configuration, copy `ssh/config.example` to your personal SSH configuration. In that copy, replace the example `AccountingRocks` with your own NetID and replace `<LOCAL_PROJECT_DIR>` with the folder containing your local SSH key. The example development node is `dev-amd24`; use a different node only if MSU or your instructor tells you to. This personal configuration stays on your PC and must not be committed to GitHub.

You do not need a second or portable copy of VS Code for this project.

## 4. Open and clone the project remotely

Once the **🔌 Remote-SSH window** is open, continue using **🧩 VS Code on your PC**; the new window is connected to HPCC. In that remote window, open **🖥️ Terminal > New Terminal**. That terminal is running on HPCC, so use it to clone this repository into a new folder in your HPCC home or approved project space. Open the cloned folder in the same remote window.

In the **🖥️ remote terminal on HPCC**, run:

    git clone https://github.com/RichardSaouma/MSU-HPCC-Codex-Stata-POC.git
    cd MSU-HPCC-Codex-Stata-POC

When the folder opens, VS Code normally displays a notification saying that the workspace has extension recommendations. Click **Install** to install all of them, or click **Show Recommendations** to review them one at a time. If the notification does not appear, open the Extensions view on the left and search for `@recommended`. Install the recommendations while the remote window is active. They are listed in `.vscode/extensions.json`: Codex, Stata MCP, Stata Workbench, Python, and Python Environments.

The Remote-SSH extension is installed on your PC, but Codex and Stata MCP must run in the remote VS Code window. This keeps Stata and your data on HPCC.

## 5. Run HPCC setup

In **🖥️ Terminal > New Terminal in the Remote-SSH window**—not in PowerShell on your PC—run:

    bash scripts/setup-hpcc.sh

The script does the setup for you. It finds Stata, Python, PyStata, the Stata MCP extension, and the Codex extension, then connects them. It is safe to run again if setup needs to be repeated.

If HPCC shows different module names (unlikely; these are the names used by this setup), an instructor can override them. This command also runs in the **Remote-SSH VS Code terminal on HPCC**:

    HPCC_PYTHON_MODULE='<PYTHON_MODULE>' \
    HPCC_STATA_MODULE='<STATA_MODULE>' \
    bash scripts/setup-hpcc.sh

If VS Code has not finished installing the extensions, wait for installation to finish, then rerun the command.

## 6. Verify the environment

After installing or reloading the extensions in the remote VS Code window, run this in the **🖥️ remote terminal**, not in PowerShell on your PC:

    bash scripts/verify-hpcc.sh

This checks that the HPCC setup, Stata, Python, and the Stata MCP extension are working.

These are example results printed by the remote terminal:

    Stata MCP health: ... "stata_available":true ...
    Stata smoke test: display 2 + 2 -> 4
    Stata MCP ready: Stata available: true

The command may show warnings if the Stata MCP extension has not started yet. The setup is ready for the final test only when the health line contains `"stata_available":true`.

## 7. Test remote Codex + Stata

In the **🔌 Remote-SSH window in VS Code on your PC**, open the **🤖 Codex agent** supplied by the Codex extension. Ask that agent—not a separate local Codex session—to use the Stata MCP server and run:

    display 2 + 2

The result should be 4. You do not need to configure an MCP URL or forward a port on your PC.

## Troubleshooting

### Verification says `Stata available: false` or the MCP health endpoint is not running

This means the lower-level setup may be present, but the Stata MCP extension is not running or cannot reach Stata. In the remote VS Code window, reload or activate the Stata MCP extension, then rerun `bash scripts/verify-hpcc.sh`. Continue only when the health response contains `"stata_available":true`.

### Setup or verification reports `No module named pystata` or `No module named stata_setup`

The MCP Python environment cannot see MSU's PyStata utilities. From the remote VS Code terminal, rerun `bash scripts/setup-hpcc.sh`; it installs `stata-setup` in the MCP environment and creates the path file that points to the MSU Stata utilities.

### PyStata reports `libpython3.11.so.1.0` is missing

The matching Python module is not loaded in the remote terminal. Run this in the **Remote-SSH VS Code terminal on HPCC**:

    module purge
    module load Python/3.11.3-GCCcore-12.3.0

### Setup says the remote Codex command was not found

The Codex extension is not installed or has not finished starting in the remote VS Code window. Install or reload the Codex extension there, then rerun `bash scripts/setup-hpcc.sh`. Do not install a separate Codex package with `apt`; the setup script finds the binary bundled with the remote VS Code extension. It also finds the installed Stata MCP extension without requiring a hard-coded extension version.

### Remote-SSH hangs, fails to open the remote window, or reports a Node `navigator` error

Update VS Code and the Remote - SSH and Codex extensions on your PC, disconnect, and reconnect to HPCC. If the error persists, check the MSU [VS Code over SSH instructions](https://docs.icer.msu.edu/Connect_over_SSH_with_VS_Code/) and confirm that you are connecting to a development node rather than trying to run the remote tools on the gateway.

## Working with local or HPCC data

You can work with data stored on your PC, or with data stored in your HPCC home or approved project space. In the preferred workflow, the Codex agent, Stata MCP, and Stata can access HPCC files directly. Files on your PC are not automatically visible in the remote session; upload or copy them to HPCC when you want the remote tools to use them. Keep research data wherever your course or research requirements allow.

## Appendix A: Local Codex + forwarded remote MCP

The local-Codex fallback was also proven, but is not the recommended student workflow. It requires forwarding remote port 4000 to a local port, checking the forwarded health endpoint, and configuring local Codex with the assigned local MCP URL. This adds networking and process-location concepts without improving data locality.

Use it only when remote Codex is unavailable, and never expose the MCP endpoint beyond the intended local/SSH boundary.

## Further references

- [Codex/VS Code guide](https://claesbackman.com/codex-vscode-guide.html)
- [OpenEcon Stata MCP](https://openecon.ai/projects/stata-mcp)
- [Stata MCP repository](https://github.com/hanlulong/stata-mcp)
