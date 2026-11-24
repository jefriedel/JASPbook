# LaTeX → Quarto workflow notes

Personal notes for converting *Learning Statistics with JASP* and keeping it in sync with upstream.
This file lives in `.qmd_translation/`; Quarto ignores folders starting with `.`, so it never ends up in the book.

## Setup (once per machine)

- Quarto must be on the PATH. Bundled copy with Positron — add to `~/.zshrc`:

  ```bash
  export PATH="/Applications/Positron.app/Contents/Resources/app/quarto/bin:$PATH"
  ```

- Remotes: `origin` = my fork, `upstream` = tomfaulkenberry/JASPbook (branch **master**).
- All commands are run from the repo root.

## Folder layout

| Path | What it is | Edit? |
|---|---|---|
| `tex/` | upstream LaTeX | **never** (changed only by `pull_upstream.sh`) |
| `img/` | figures; `.png` versions made by `eps_to_png.sh` | add PNGs only |
| `qmd/.raw/<chapter>.qmd` | pandoc output of a whole chapter | **never** (merge base) |
| `qmd/.sections/<chapter>/<label>.qmd` | same, split at each `## ` | **never** (merge base) |
| `qmd/.sections/<chapter>/_order.txt` | original section order | no |
| `qmd/_sections/*.qmd` | **my** edited sections — rename/move freely | yes |
| `qmd/<class-chapter>.qmd` | **my** chapters: a list of `{{< include >}}` lines | yes |
| `.qmd_translation/UPSTREAM_BASE` | upstream commit the base files were built from | no |

Folders starting with `.` or `_` are not rendered by Quarto; sections appear only where included.

## Converting a new chapter

```bash
.qmd_translation/eps_to_png.sh img/<folder>          # make PNGs for its figures (skips existing)
.qmd_translation/tex_to_qmd.sh chapter10_chisquare    # → qmd/.raw/ and qmd/.sections/
cat qmd/.sections/chapter10_chisquare/_order.txt      # see the section names
```

What `tex_to_qmd.sh` does to the LaTeX (on a temp copy) before pandoc:

- puts `macros.tex` in front: simplified versions of the book's custom macros
  (`\keyterm`, `\FOOTNOTE`, `\SUBSECTION`, `\boldm`, `\HR`) — otherwise pandoc drops them *and their text*.
  **When a scan finds another custom macro, add it there** (real definitions: `tex/header.tex`, `tex/contentstyle.tex`).
- `\epsfig{file=…,width=…}` → `\includegraphics[width=…]{…}` (pandoc ignores `\epsfig`)
- removes `\begin{center}`, `\end{center}`, `\HR` (they force raw-HTML figures)
- removes `\cline{2-3}` (otherwise "2-3" appears as text in tables)
- `fix-images.lua`: image extension → `.png`; drops `[t]` placement (also forces raw HTML)
- `crossrefs.lua`: LaTeX labels/refs → Quarto cross-refs, so numbering is automatic:
  - `{#fig-x}`, `{#tab-x}`, headings `{#sec-x}` (chapters use `sec-` too)
  - `Figure~\ref{fig:x}` → `@fig-x` (Quarto writes "Figure 2.1"); other refs → `[-@sec-x]` (number only)
  - refs into chapters not converted yet show as `?@sec-x` + a warning until that chapter is in the book

Checking a converted chapter for leftovers:

```bash
f=qmd/.raw/chapter01_whystats.qmd
grep -n -o '\\[a-zA-Z]\+' $f | sort -u     # LaTeX commands left as text (ignore ones inside $math$)
grep -n '{=latex}\|<[a-z]\+[ >]' $f         # raw LaTeX / HTML blocks
grep -n 'reference-type\|label="' $f        # unconverted refs/labels
quarto render --to html 2>&1 | grep WARN    # unresolved refs / citations
```

## Working on sections

```bash
# start editing a section (copies it to qmd/_sections/ with an upstream marker line)
.qmd_translation/adopt.sh chapter10_chisquare/sec-goftest chisq-goodness-of-fit

# rename / move — ALWAYS with git mv, then update the include line
git mv qmd/_sections/chisq-goodness-of-fit.qmd qmd/_sections/gof.qmd
```

- **Never edit or delete line 1** (`<!-- upstream: chapter/label -->`) — that is how merges find the file.
- A class chapter is just includes, so reorder/combine by moving lines:

  ```markdown
  {{< include _sections/ch09-intro.qmd >}}

  {{< include _sections/gof.qmd >}}
  ```

- Images use `../img/...`, which works because chapters sit one level down in `qmd/`.
- Add chapters to `_quarto.yml` under `book: chapters:` (`index.qmd` must be first).

## Key terms

- Converted LaTeX `\keyterm{x}` becomes `[x]{.keyterm}`; I can mark new ones the same way.
- Definitions live in `glossary.yml` (repo root), one per term; keys ignore capitals.
  Different wording in the text → `[biased]{.keyterm term="belief bias effect"}`.
- HTML: purple bold; with a definition also a dotted underline and a popup on hover,
  keyboard focus (Tab) or tap. Typst/PDF: purple bold only.
- Which terms still need definitions:

  ```bash
  .qmd_translation/keyterms_missing.sh                     # all my sections
  .qmd_translation/keyterms_missing.sh qmd/.raw/chapter10_chisquare.qmd
  ```

- Pieces: `styles/keyterms.lua` (render filter), `styles/keyterms.html` (popup script, uses
  Quarto's built-in tippy.js), CSS in `styles/html-style.css`, `keyterm()` in `styles/typst-style.typ`.

## Previewing

```bash
quarto preview qmd/chapter09_hypothesistesting.qmd   # one chapter, live reload
quarto render qmd/chapter09_hypothesistesting.qmd --to html
quarto preview                                       # whole book
```

## Pulling upstream edits

1. Commit everything first (the script refuses to run otherwise).
2. Run:

   ```bash
   .qmd_translation/pull_upstream.sh
   ```

3. Read the report: `updated`, `CONFLICT`, new sections upstream, removed sections.
4. Review: `git status`, `git diff`. Fix conflicts — search for `<<<<<<<`:

   ```text
   <<<<<<< mine
   my version
   ||||||| base
   original version
   =======
   upstream's new version
   >>>>>>> upstream
   ```

   Keep what you want, delete the marker lines.
5. Accept: `git add -A qmd .qmd_translation && git commit`
   Undo everything instead: `git reset --hard`

Notes:

- Merging works per line, and each paragraph is one line — two edits in the *same paragraph*
  conflict even if they touch different sentences.
- Text I moved from one section file to another won't get upstream edits automatically;
  it shows up as a conflict in the original file.
- If I change the converter (`tex_to_qmd.sh`, `fix-images.lua`), rebuild the base and commit it
  *before* pulling upstream, or the converter change will look like an upstream edit.

## Known conversion issues / TODO

- [x] Cross-refs → Quarto format (`crossrefs.lua`)
- [x] `\keyterm`, `\boldm`, `\FOOTNOTE` dropped → fixed with `macros.tex`
- [x] `\cline` leaves "2-3" in tables → removed in pre-pass
- [x] Add `index.qmd` to `chapters:`; `bibliography: tex/refs.bib` in `_quarto.yml`
- [ ] `index.qmd` is empty → Quarto numbers it as chapter 1. Give it `# Preface {.unnumbered}` (or similar)
- [x] `\keyterm` → `[term]{.keyterm}`, purple bold + glossary popups (see **Key terms**)
- [ ] Replace the two DRAFT definitions in `glossary.yml` with my own
- [ ] Indentation in verse (`\hspace`) is lost (ch01 Auden quote)
- [ ] Typst cites in numbered style ([1]) while HTML is author-date — set a CSL (e.g. APA) for both
- [ ] Chapter 9 base (`qmd/.raw`, `qmd/.sections`) was built with the old converter — re-run `tex_to_qmd.sh` before adopting its sections

## Log

<!-- date — what I did / learned -->
- 2026-11-24 — Set up conversion + upstream-tracking scripts; chapter 9 split into `qmd/_sections/ch09-*`.
- 2026-11-24 — Added `crossrefs.lua`, `macros.tex`, `\cline` fix. Rebuilt chapter 1; builds in HTML + Typst
  (only warning: `@sec-housingpriceexample`, which lives in a chapter not converted yet).
- 2026-11-24 — Key terms: `[term]{.keyterm}` + `glossary.yml` popups. Rebuilt ch01 + ch09 bases;
  merged the converter change into `01-intro`, `01-whywhywhy` with `git merge-file`.
