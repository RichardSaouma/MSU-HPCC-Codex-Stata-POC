---
name: kinney-paragraphs
description: Produce or evaluate a Kinney Three Paragraph document (What / Why / How, plus predictive-validity tables and outcome risks) for an empirical accounting research idea. Use when formalizing a new paper idea, stress-testing an existing one, or preparing a workshop presentation — before any data work or paper drafting begins. Not for writing the paper itself, literature reviews, or analysis.
---

# Kinney Three Paragraphs

Every paper idea passes through Steps I, II, and III before implementation work
begins. The framework converts what is in the researcher's head into language
others can evaluate.

Based on Kinney, W. R. (2019), "The Kinney Three Paragraphs and Beyond,"
*Accounting Horizons* 33(4), 1–14.

**Read `references/rules.md` before drafting** — it carries the full framework,
the stop-sign criteria, and the domain-customization guidance.
`references/template.md` is the output format.

## Step 1 — Gather background

Search the current project for relevant material. Every command degrades
gracefully; skip silently if a folder is absent.

```bash
[ -f explorations/PAPER_INVENTORY.md ] && cat explorations/PAPER_INVENTORY.md
grep -lin "<key term>" explorations/*.md 2>/dev/null
ls quality_reports/kinney/ 2>/dev/null
```

For PDFs, use `pdftotext` (present on MSU HPCC; `pdfgrep` is not):

```bash
for f in explorations/*.pdf; do
  pdftotext "$f" - 2>/dev/null | grep -qi "<key term>" && echo "$f"
done
```

Extract: what conceptual X and Y prior work has established, what data prior
papers used, what identification strategies adjacent papers relied on, and what
gaps the literature has flagged.

## Step 2 — Draft Step I (150–300 words)

Three paragraphs. Nothing more, nothing less.

**What** — "I am trying to find out whether [X] [affects/causes] [Y]." X and Y
are *conceptual* factors, not proxies. One to three sentences on the mechanism,
with the expected sign and magnitude of the effect implied.

**Why** — "It is important to find out because [audience] needs to understand
[how X→Y bears on their decisions]." Push past accounting mechanics to policy,
governance, capital markets, or theory. State what a large effect implies *and*
what a near-zero effect implies — the null is also informative. This is the
paragraph most often underwritten; do not accept a thin answer.

**How** — "I will find out by [method] on [setting] over [period] using [data]."
Name X̂ and Ŷ, the identification strategy, and the V (prior) and Z (concurrent)
controls.

## Step 3 — Step II, predictive validity

Fill both tables from `references/template.md`: What-PV (is the conceptual claim
testable?) and How-PV (will the operationalization work?). Every cell gets a
substantive assessment — no blanks, no single words. Mark stop signs honestly;
the tables are worthless if they always say proceed.

State an overall verdict for each: PROCEED / REVISE / STOP.

## Step 4 — Step III, outcome risks

Assess each risk in the template with a probability and a *specific* mitigation.
"Be careful" is not a mitigation; "hand-collect 200 firm-years to reach 80%
power" is.

Close with an overall risk level and a "good bet" verdict: YES / MAYBE / NO.

## Step 5 - Save, then present

**Always write the document to a file.** Delivering it only in the chat defeats
the purpose: the value is a durable artifact the researcher revisits, revises,
and brings to a workshop. A Kinney document that exists only in a transcript is
lost work.

Default location, relative to the workspace root:

```
quality_reports/kinney/YYYY-MM-DD_<short-title>.md
```

Create the folder without asking - it is cheap and additive:

```bash
mkdir -p quality_reports/kinney
```

The absence of an existing `quality_reports/` convention is **not** a reason to
skip saving or to ask permission. Ask where to save only if the workspace root
cannot be determined or is not writable. If the workspace root is a home
directory rather than a project folder, say so and save under the current
working directory instead.

After writing, confirm the file exists and report its **absolute** path:

```bash
ls -la quality_reports/kinney/
```

Then present, in this order:

1. The three paragraphs (Step I)
2. The PV verdicts and any stop signs triggered (Step II)
3. The top two or three risks with mitigations (Step III)
4. Your recommendation: proceed, revise, or stop
5. The path to the saved file

## Quality bar

Do not save a document that fails these:

- Step I is 150–300 words
- The What opens "I am trying to find out whether..."
- The Why names an audience and reaches beyond accounting mechanics
- No blank cells in the Step II tables
- Every Step III risk has a probability and a specific mitigation
- A "good bet" verdict is stated

Scoring, out of 100: complete Step I (40), non-trivial Step II assessments (30),
specific risk mitigations (20), verdict stated (10). Below 80, revise before
saving.

## Be a critic, not a cheerleader

The framework's value is in the stop signs. A Kinney document that says
"proceed" on every line has done nothing for the researcher. If X cannot be
operationalized, if identification is not credible, or if several risks are high
with no mitigation, say so plainly and recommend revision or abandonment. It is
cheaper to kill a bad idea here than after two years of data work.

## After a "good bet"

Once a document clears Step II/III, `references/proposal-template.md` expands it
into a full research proposal — the Kinney spine maps onto it directly
(What → Objectives, Why → Benefits, How → Method). Use that for a workshop
proposal, dissertation prospectus, or committee document.
