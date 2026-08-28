# Writing to files that already exist

The goal is not to refuse edits. It is to make every edit either recoverable or
intentional, so nothing is lost silently.

## Decision procedure

Before writing to any path, check whether it already exists:

    ls -la "<path>"

Then:

**1. You created it earlier in this session** — overwrite freely. It is yours,
and the user watched you make it.

**2. It does not exist** — write it. Nothing to lose.

**3. It exists and the user explicitly asked for THIS file to be changed**
("update test.do", "regenerate table2.tex", "fix the cleaning script") —
preserve history, then edit. See below.

**4. It exists and the user did not name it** — do not touch it. Write to a new
filename instead and say which name you chose. If there is genuinely no
alternative, ask first.

## Exception: regenerable outputs

Rules 3 and 4 protect work that cannot be recreated. They do **not** apply to
files that a do-file rebuilds from scratch. Overwrite these freely, without
backups, without asking:

- anything under `output/`, `results/`, `figures/`, `tables/`
- `.log` files produced by running a do-file
- graph exports (`.png`, `.pdf`, `.eps`) written by `graph export`
- regression tables (`.tex`, `.rtf`, `.xlsx`, `.csv`) written by `esttab`/`estout`

Rerunning an analysis and replacing its outputs is normal work, not a
destructive act. Never refuse to run a do-file because it would overwrite its
own outputs, and never ask permission for it.

What stays protected: `.do` files, anything in `data/raw/` or `data/derived/`,
`.dta` files generally, and any file the user wrote by hand.

If a single command would overwrite both — say a do-file that regenerates a
table *and* resaves a derived dataset — protect the dataset and let the table
be rewritten.

## Preserving history before an intentional edit

Two mechanisms, in order of preference.

### If the file is tracked by git

    git -C "<project>" status --porcelain -- "<path>"

- **Empty output** — the file is committed and unmodified. Edit it directly;
  git already holds the previous version. Tell the user they can recover it
  with `git diff` or `git checkout -- <path>`.
- **Any output** — there are uncommitted changes that git cannot recover.
  Back up first, as below.

### Otherwise, timestamped backup

    mkdir -p "<project>/.backups"
    cp -p "<path>" "<project>/.backups/$(basename <path>).$(date +%Y%m%d-%H%M%S)"

Backups are cheap. Data loss is not.

## The one required action

Before editing any existing protected file, run:

    bash ~/.agents/skills/stata-hpcc/scripts/safe-edit.sh "/abs/path/to/file" "what you are changing"

That single call does all of it: finds the project root, checks whether git
already holds the file's history, makes a timestamped copy in `.backups/` only
when git cannot cover it, and appends a line to `logs/file-changes.log`.

Run it **before** the edit. Do not reconstruct the log afterwards from memory —
if you realise you edited without running it, run it then and say the entry is
retrospective, so the user knows the backup postdates the change.

Do not hand-write log lines. One mechanical call is reliable in a way that a
remembered convention is not, and the log is only useful if it is complete.

### What the log looks like

    2026-08-27T18:17:30	modified	/mnt/home/brakelin/proj/test.do	renamed variables

Tab-separated: timestamp, action, path, note. Greppable, and it diffs cleanly.

Mention the log once per session, the first time you write to it. After that,
just do it silently.

### Its limits — be honest about them

This log records what the agent did when the agent remembered to record it. It
is not an audit trail and cannot catch edits made outside this workflow. Git is
the only history that cannot be bypassed. If the user is doing work that
matters, encourage them to commit regularly rather than relying on this.

## Absolute prohibitions

- **Never write to `data/raw/`.** Raw data is read-only by convention. Derived
  files go to `data/derived/`.
- **Never `save ..., replace` over a `.dta` you did not create this session**
  unless the user named that file.
- **Never delete.** Move to `.backups/` instead and say so.

## Reporting

When you modify an existing file, say so plainly:

> Updated `03_analysis.do`. Previous version backed up to
> `.backups/03_analysis.do.20260827-160312`.

Not "I've made the changes." The user should never have to ask what you touched.
