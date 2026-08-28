# Looking up Stata syntax without guessing

## Try `help` first

Stata's own help is faster than anything else and costs almost nothing. Run it
through `stata_run_selection`:

    help regress
    help regress##options
    help xtreg
    search heteroskedasticity

For user-written commands, `help` works once the package is installed, and
`which <command>` tells you whether it is:

    which reghdfe
    ssc describe reghdfe

If a command is not installed, say so rather than writing code that will fail.

Go to the PDF manuals only when `help` is too terse - worked examples, the
formula behind an estimator, methodological discussion.

## The manuals on MSU HPCC

Confirmed present, Stata 18-MP:

    /opt/software-current/2023.06/x86_64/generic/software/Stata/18-MP/docs/

Discover the path rather than hardcoding it, in case the module version changes:

    module load Stata/18-MP
    STATA_DOCS="$(dirname "$(readlink -f "$(which stata-mp)")")/docs"
    ls "$STATA_DOCS"/*.pdf

The ones worth knowing:

| File | Manual |
|---|---|
| `r.pdf` | Base Reference - most commands live here |
| `causal.pdf` | Causal Inference and Treatment-Effects |
| `xt.pdf` | Longitudinal / Panel Data |
| `d.pdf` | Data Management |
| `u.pdf` | User's Guide |
| `p.pdf` | Programming |
| `ts.pdf` | Time Series |
| `sem.pdf` | Structural Equation Modeling |
| `lasso.pdf` | Lasso |
| `meta.pdf` | Meta-Analysis |
| `g.pdf` | Graphics |

## Searching them: use `pdftotext`

**`pdfgrep` and `pdfplumber` are NOT installed on MSU HPCC.** Do not try them.
`pdftotext` (poppler) is at `/usr/bin/pdftotext` and does the job.

### Find the page

`pdftotext` writes a form feed between pages, so treating it as awk's record
separator makes `NR` the page number:

    pdftotext "$STATA_DOCS/r.pdf" - | awk -v RS='\f' '/vce\(robust\)/{print NR}' | head

### Read only that page

    pdftotext -f 412 -l 414 "$STATA_DOCS/r.pdf" -

Always pass `-f` and `-l`. **Never extract a whole manual** - these run to
thousands of pages and will flood the context for no benefit.

### Case-insensitive search

    pdftotext "$STATA_DOCS/causal.pdf" - | awk -v RS='\f' 'tolower($0) ~ /difference-in-differences/{print NR}' | head

### Search several manuals at once

    for f in "$STATA_DOCS"/{r,causal,xt}.pdf; do
      echo "== $(basename "$f")"
      pdftotext "$f" - | awk -v RS='\f' '/hdfe/{print NR}' | head -5
    done

## Workflow

1. `help <command>` - usually enough.
2. Still unclear -> pick the right manual from the table above.
3. Find candidate pages with the awk one-liner.
4. Extract that page plus one either side with `-f`/`-l`.
5. Quote what you found and name the manual and page, so the user can check it.

## If you want richer extraction

`pdfplumber` handles tables better than `pdftotext`. It is not installed, but a
user-level install works on the dev node:

    module load Python/3.11.3-GCCcore-12.3.0
    pip install --user pdfplumber

Do not install it unprompted. `pdftotext` is sufficient for syntax lookup, and
adding packages to someone's environment is their decision.
