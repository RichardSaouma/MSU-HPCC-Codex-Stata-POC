# MSU HPCC + Codex + Stata MCP

MSU HPCC is Michigan State University's remote Linux computing system, not a folder on your local computer. This repository is the complete student project. After you connect to HPCC with VS Code Remote-SSH, clone this repository into your HPCC home or approved project space and work in the new folder created by that clone. If an older demonstration folder is already on HPCC, ignore it; you do not need to copy anything from it.

The folder created by cloning this repository is your project folder. Open that folder in the remote VS Code window. Do not put this project inside another project folder or edit an older demonstration folder.

## How the setup works

The preferred setup is:

    Local VS Code
        -> Remote-SSH
        -> MSU HPCC development node
        -> remote Codex
        -> Stata MCP
        -> MSU Stata 18-MP
        -> HPCC-resident data

The goal is to let remote Codex run Stata commands on HPCC while the code, Stata installation, and research data remain on HPCC.

For serious computation, use the appropriate HPCC SLURM allocation rather than treating a development node as a production target.

## Prerequisites

You provide:

- an MSU HPCC account and NetID;
- HPCC access and, where required, an HPCC project/account allocation;
- local VS Code;
- an SSH key kept on your local computer.

This repository provides workspace recommendations, setup and verification scripts, and documentation. It does not contain VS Code, extensions, private keys, credentials, virtual environments, or personal HPCC configuration.

## 1. Obtain HPCC access

Start with the [MSU HPCC connection documentation](https://docs.icer.msu.edu/Connect_to_HPCC_System/). The gateway is hpcc.msu.edu; authenticate with your own MSU NetID.

If SSH reports Home directory not found or Could not chdir to home directory, this may be an account-provisioning issue rather than an SSH-key problem.

Useful references:

- [SSH key-based authentication](https://docs.icer.msu.edu/SSH_Key-Based_Authentication/)
- [VS Code over SSH](https://docs.icer.msu.edu/Connect_over_SSH_with_VS_Code/)
- [Stata on HPCC](https://docs.icer.msu.edu/Stata/)
- [Available software](https://docs.icer.msu.edu/available_software/overview/)
- [Home space](https://docs.icer.msu.edu/Home_Space/)

## 2. Create a dedicated SSH key

Keep the private key local and never put it in this repository. For example, run locally:

    ssh-keygen -t ed25519 -f "<LOCAL_PROJECT_DIR>\\ssh\\hpcc_poc" -C "HPCC POC"

Install only the public key on HPCC. On HPCC:

    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

On Windows, an SSH agent can cache the passphrase:

    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ssh-add "<LOCAL_PROJECT_DIR>\\ssh\\hpcc_poc"
    ssh-add -l

## 3. Configure Remote-SSH

Install [Microsoft Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) locally. The gateway is the entry point; VS Code Server should run on an HPCC development node, not the gateway.

Copy ssh/config.example to a user-local SSH configuration, replace MSU_NETID, HPCC_DEV_NODE, and LOCAL_PROJECT_DIR, and select hpcc-dev in VS Code. Do not commit a personalized copy.

The optional portable VS Code ZIP installation is useful for strict separation from an existing production VS Code installation, but is not required for every student.

## 4. Open and clone the project remotely

Connect to the development node through Remote-SSH, clone this repository into a new folder in your HPCC home or approved project space, and open that folder in the remote window. Accept the recommended extensions in .vscode/extensions.json. If an older proof-of-concept folder is already on HPCC, leave it alone; do not merge it with this project or overwrite its files.

Remote-SSH is local-side tooling. Codex and Stata MCP must operate in the remote window for the preferred architecture. Do not check extension binaries into Git.

## 5. Run HPCC setup

From the remote VS Code terminal:

    bash scripts/setup-hpcc.sh

The script is safe to rerun. It clears inherited modules, loads Python/3.11.3-GCCcore-12.3.0 and Stata/18-MP, discovers the Stata installation and PyStata utilities, discovers the newest installed MCP extension, installs stata-setup if either stata_setup or pystata is missing, creates the durable msu-stata.pth file, verifies PyStata, and dynamically discovers/configures the remote Codex binary.

If an HPCC inventory uses different module names, override them:

    HPCC_PYTHON_MODULE='<PYTHON_MODULE>' \
    HPCC_STATA_MODULE='<STATA_MODULE>' \
    bash scripts/setup-hpcc.sh

If extensions are not installed, install them through the remote VS Code window and rerun the script. It intentionally fails clearly instead of guessing.

## 6. Verify the environment

After installing or reloading remote extensions:

    bash scripts/verify-hpcc.sh

Verification checks the modules, Stata executable, PyStata, MCP extension, MCP private Python, MCP health endpoint, and a lightweight display 2 + 2 smoke test. It does not submit a SLURM job.

Expected results include:

    Stata MCP health: ... "stata_available":true ...
    Stata smoke test: display 2 + 2 -> 4
    Stata MCP ready: Stata available: true

The verifier can exit successfully after lower-level HPCC, Stata, and PyStata checks even if the MCP server is not currently running. In that case it emits a warning and reports that MCP activation is still pending. End-to-end readiness requires the MCP health check to report stata_available: true.

## 7. Test remote Codex + Stata

In remote Codex, ask it to use stata-hpcc to run:

    display 2 + 2

The verified result is 4. The remote MCP endpoints are:

    http://localhost:4000/mcp-streamable
    http://localhost:4000/health

No local MCP port forwarding is required by the preferred workflow.

## HPCC and Stata notes

The Python and Stata modules must be loaded in separate purged contexts. Loading them together caused the validated ncurses conflict. Use this sequence:

    # Stata discovery or a Stata smoke test
    module purge
    module load Stata/18-MP

    # MCP/PyStata checks
    module purge
    module load Python/3.11.3-GCCcore-12.3.0

module purge matters because inherited default modules previously caused an ncurses conflict. When the Stata extension needs a path, use the installation directory ending in /Stata/18-MP, not the executable path ending in /stata-mp. The setup and verification scripts implement these separate contexts.

The reproducible workspace setting in .vscode/settings.json points to the verified MSU installation directory /opt/software-current/2023.06/x86_64/generic/software/Stata/18-MP. It contains no personal Windows path, NetID, SSH key path, credential, or token.

Keep data on HPCC and use paths appropriate to your home/project allocation. For serious workloads, follow MSU HPCC SLURM guidance rather than treating a development node as a production target.

## Troubleshooting

### Stata available: false

Check the Stata root, Python 3.11 module, stata-setup installation, and msu-stata.pth path to /Stata/18-MP/utilities. If verification says the MCP health endpoint is not running, reload or activate the remote Stata MCP extension and rerun verification. Then perform the manual remote Codex smoke test.

### Missing pystata or stata_setup

Run setup so it can install stata-setup and create the path file. The previous remote.SSH.remoteEnv and server-env-setup approaches were not reliable and are not used as the core fix.

### Missing libpython3.11.so.1.0

Load the matching Python module after module purge:

    module purge
    module load Python/3.11.3-GCCcore-12.3.0

### Remote Codex command not found

Do not install Codex with apt. The VS Code extension contains a bundled binary below ~/.vscode-server/extensions/openai.chatgpt-*/bin/linux-x86_64/codex; setup discovers the newest installed matching directory dynamically. The scripts likewise discover the newest installed deepecon.stata-mcp-* directory and do not require a hard-coded extension version.

### Remote-SSH hangs or reports a Node navigator error

Check current VS Code, Remote-SSH, and Codex versions first. The POC encountered navigator is now a global in nodejs. Compatibility settings such as remote.SSH.useLocalServer: false and extensions.supportNodeGlobalNavigator: true are version-sensitive and are not enabled by default here.

## Working with HPCC-resident data

Keep research data on HPCC and use paths in your HPCC home or approved project space. The local VS Code client is only the interface; remote Codex, the MCP server, Stata, and data remain on HPCC in the preferred workflow.

## HPCC project and SLURM notes

The development node is suitable for setup and lightweight testing. Use the appropriate HPCC project/account and SLURM workflow for serious computation. This repository does not orchestrate SLURM jobs.

## Appendix A: Local Codex + forwarded remote MCP

The local-Codex fallback was also proven, but is not the recommended student workflow. It requires forwarding remote port 4000 to a local port, checking the forwarded health endpoint, and configuring local Codex with the assigned local MCP URL. This adds networking and process-location concepts without improving data locality.

Use it only when remote Codex is unavailable, and never expose the MCP endpoint beyond the intended local/SSH boundary.

## Appendix B: Optional portable VS Code isolation

The original proof of concept used a portable VS Code ZIP installation to avoid interfering with an existing production VS Code environment. This is optional and especially useful for instructors, demonstrations, pilots, or heavily customized workstations; it is not a universal student prerequisite.

## Appendix C: Further references

- [Codex/VS Code guide](https://claesbackman.com/codex-vscode-guide.html)
- [OpenEcon Stata MCP](https://openecon.ai/projects/stata-mcp)
- [Stata MCP repository](https://github.com/hanlulong/stata-mcp)

## Definition of done

A fresh environment should be able to connect over Remote-SSH, install recommended extensions, run setup and verification, report Stata available: true, and have remote Codex call stata_run_selection with display 2 + 2 and receive 4, without secrets or local MCP forwarding.
