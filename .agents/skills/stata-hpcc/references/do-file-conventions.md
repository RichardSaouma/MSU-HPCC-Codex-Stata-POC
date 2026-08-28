# Do-file conventions

## Template

```stata
*==============================================================================
* <project> — <what this step does>
* Author:  <name>
* Created: <date>
* Inputs:  /mnt/home/<netid>/<project>/data/raw/<file>
* Outputs: /mnt/home/<netid>/<project>/output/<file>
*==============================================================================

version 18
clear all
set more off
set seed 20260827          // only if anything is random

* ---- paths (define once, use everywhere) ------------------------------------
global PROJ "/mnt/home/<netid>/<project>"
global RAW  "$PROJ/data/raw"
global DTA  "$PROJ/data/derived"
global OUT  "$PROJ/output"
global LOG  "$PROJ/logs"

cap mkdir "$DTA"
cap mkdir "$OUT"
cap mkdir "$LOG"

log using "$LOG/<name>.log", replace text

* ---- body -------------------------------------------------------------------

use "$RAW/<file>.dta", clear

* ...

save "$DTA/<file>_clean.dta", replace

log close
```

## Rules

- **`version 18`** at the top. Guarantees the file still behaves the same after
  a Stata upgrade — essential for replication packages.
- **`set seed`** whenever anything is random: simulation, bootstrap, sampling,
  random assignment. Record the seed in the header.
- **Globals for paths**, defined once. Never repeat a literal path.
- **One do-file per step** — `01_import.do`, `02_clean.do`, `03_analysis.do`,
  with a `00_master.do` that runs them in order. Keeps reruns cheap and makes
  it obvious where a number came from.
- **Log everything.** `log using ..., replace text` at the top, `log close` at
  the end. Plain text logs diff well in git.
- **Never modify raw data.** `data/raw/` is read-only by convention; derived
  files go to `data/derived/`.
- **Label as you go.** `label variable`, `label define`/`label values`. Future
  you will not remember what `x3` was.
- **Comment the why, not the what.** `* winsorize at 1/99 per Smith (2020)`
  beats `* winsorize`.

## Regression output

Prefer `estout`/`esttab` for tables that go into a paper, written to
`$OUT` as `.tex` or `.rtf`:

```stata
eststo clear
eststo: reghdfe y x, absorb(firm year) cluster(firm)
esttab using "$OUT/table2.tex", replace booktabs se star(* 0.10 ** 0.05 *** 0.01)
```

Check whether a user-written command is installed before using it:

```stata
which reghdfe
```

If it is missing, install to a personal ado directory rather than a shared one:

```stata
net set ado "~/ado"
ssc install reghdfe
```

## Graphs

```stata
graph export "$OUT/figure1.png", replace width(1600)
```

Always an absolute path (or a `$OUT` global resolving to one), always `replace`,
and set `width()` so the PNG is legible in a paper.
