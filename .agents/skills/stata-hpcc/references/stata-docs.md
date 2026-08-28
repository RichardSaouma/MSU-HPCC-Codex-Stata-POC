# Looking up Stata syntax without guessing

Stata ships its complete manuals as PDFs inside the installation. Grep them
instead of inventing option names.

## Find the manuals

```bash
module load Stata/18-MP
STATA_ROOT=$(dirname "$(which stata-mp)")
ls "$STATA_ROOT"/docs/*.pdf 2>/dev/null || find "$STATA_ROOT" -name "*.pdf" | head -40
```

Typical set: `r.pdf` (base reference), `xt.pdf` (panel data), `te.pdf`
(treatment effects), `ts.pdf` (time series), `p.pdf` (programming),
`d.pdf` (data management), `u.pdf` (user's guide).

## Search them cheaply

`pdfgrep` if available — it searches PDFs directly and prints page numbers:

```bash
pdfgrep -n -i "absorb(" "$STATA_ROOT"/docs/*.pdf | head -20
```

If `pdfgrep` is not installed, use Python:

```bash
python3 - <<'PY'
import glob, sys
import pdfplumber          # pip install --user pdfplumber if missing
term = "cluster("
for path in glob.glob("/path/to/docs/*.pdf"):
    with pdfplumber.open(path) as pdf:
        for i, page in enumerate(pdf.pages, 1):
            text = page.extract_text() or ""
            if term in text:
                print(f"{path} p.{i}")
PY
```

**Extract only the pages you need.** Never load an entire manual into context —
these are thousands of pages. Find the page number first, then pull that page
and its neighbours.

## Faster options first

Before reaching for the PDFs, try Stata itself — it is quicker and costs almost
nothing:

```stata
help regress
help regress##options
search heteroskedasticity
```

Run these through `stata_run_selection` and read the output.

## For user-written commands

`ssc` packages carry their own help files:

```stata
help reghdfe
ssc describe reghdfe
```

If a command is not installed, say so rather than writing code that will fail:

```stata
which reghdfe
```
