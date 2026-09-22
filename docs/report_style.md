# Style and conventions for the Bread Economy report

Read this before writing or rebuilding any version of the report, in any language. Every rule here came from a correction; do not re-learn them.

## 1. Register
- The running text is for a general reader, in the register of the book chapters *Goed geld* and *Slecht geld* (in the project knowledge): a story told about a village, short paragraphs, everyday images, numbers mostly in words.
- Technical detail — figures, definitions, parameter values, mechanics — goes in frames, never in the running text. A frame is written as
  `\[ KADER` on its own line, the content, then `\]` on its own line. The build turns it into `<aside class="frame">`. A frame may open with a bold title. The running text must read completely without the frames.
- Words to avoid in the running text: seed, Gini, deficit, demurrage, responsive prices, artefact, subsystem, parameter. Say: run, how evenly the money is spread, shortfall, parking fee, prices that move when bread runs short or piles up.
- No "it's not X but Y" constructions, no "that's no coincidence", no rhetorical questions answered by the next sentence, no "note that".
- Predictions that were wrong are reported as wrong; results that rest on a chosen rule say so.
- A broad rise in prices is inflation, whatever its cause. The SuMSy filling-up phase is inflation that stops when the money stock reaches its equilibrium — say "bounded" or "capped", never "not inflation".
- Public employment is "up to a tenth of the village's capacity, hired from whoever is left after the private markets" (employer of last resort); a fall in it under greed is the labour drain, not a change of rule.

## 2. Terminology (English)
- **guaranteed income** — the SuMSy monthly payment. Never "allowance" (that word means the debt village's unemployment benefit if it appears at all; prefer "benefit").
- **parking fee** — the demurrage; **parking tax** — the 1 % surcharge on the same base paid to the government, always described as *on top of* the fee, never as a slice or share of it. "Demurrage" appears only in the glossary entry and in the parameter frame, in brackets.
- **cushion** for the buffer in running text; "buffer" in frames.
- **shortfall** for the deficit; "public debt" for government debt; "settlement" for clearing, with "(clearing)" once in the glossary.
- **step** for a ladder rung in running text; "rung" in frames and code.
- Debt village / SuMSy village; "debt money" and "SuMSy" as the two column headings.

## 3. Front matter, in this order
1. Title: *The Bread Economy*; subtitle in italics.
2. Version and date.
3. Navigation line: `← Previous report: [version n−1, date](link) · Next report: [version n+1, date](link)` — "none yet" when there is no next report. Every published version links to both neighbours; when a new version is published, the previous one's "next" link is updated and republished.
4. The disclaimer, verbatim, in every language:
   *This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*
5. The frame "How to read the numbers in this report", which states the seed count, the round count, the village size, and what "alive" means.

## 4. Numbers
- State the seed count wherever it differs from the front matter's; never claim ten seeds for a three-seed result.
- Means of ten runs, with the worst run in brackets whenever it differs by more than a few people; where runs are bimodal, give the count of runs that stayed whole, never a mean.
- A number quoted in the text must exist in a results file in the repository at the version stated; the charts are drawn from those files at build time (`scripts/build_report_html.py`) and the frames' figures should be checked against `results/*_summary.csv` before publication.
- "% of GDP" uses yearly output (twelve rounds); guard against a zero denominator.
- The rich–poor gap is the richest tenth against the poorest tenth of the living — never the bottom four tenths, which averages the worst-off away — measured as a *difference* in meals (two loaves at that month's price), so that it works with zero and negative holdings and compares across the two villages' price levels. It is always shown with the poorest tenth's own holding in meals (the gap can narrow because the top falls), the number alive, and the counts under water and without cash; for net wealth and for cash. No rich-to-poor ratios.

## 5. Structure (version 3)
1 A village, twice · 2 Two kinds of money · 3 Who lives there · 4 A month in the village · 5 How the villagers decide · 6 Why the rules matter more than the money — at first · 7 The ladder (one scene per step, one frame per step, "What the ladder says", the two things that mattered more than they should) · 8 What a stock market does · 9 Cooperatives · 10 Greed · 11 Taxes · 12 What this shows, and what it cannot · 13 The stress test · Glossary.
- The ladder ends on two villages, best-surviving and least-indebted, and says they are a trade-off. "Least indebted" is a debt-village label only. The SuMSy columns at steps 11–12 are *twins* — the SuMSy village with the same fiscal rules, kept for comparison — and are labelled as such. The best SuMSy village is chosen on SuMSy's own measures (no hunger, the most evenly spread money) **under the realistic price rules** — the price rules are behaviour, not policy, and the realistic set (5 % thresholds, cost floor, buyer ceiling 2.0) runs in every village from step 10 on and in every stress test; a village made equal by timid buyers is not a result. On the ladder the best SuMSy village is the co-op village with those prices and the public reserve.
- The conclusions lead with the price rules and the fiscal frontier (review 2, §6), and carry the distributional cost of responsive prices.
- The fiscal asymmetries between the villages (benefit only under debt money, account fees only under SuMSy) are disclosed in §2 and at step 2.

## 6. Errata on earlier versions
A published version is never rewritten. When a later version corrects a statement a critical reader would trip on, the earlier version gets an **erratum box** under its navigation line — in English in every language block, in that language where the block is translated — listing the corrected statements and linking to the version that corrects them. Version 2 carries one (21 September 2026: the price-level claim, rung 0's 8 %, the two one-in-three results, the greed mechanism, the 0.63 multiplier).

## 7. Glossary
One entry per paragraph: `**Term (code name).** One sentence.` A blank line between entries. Eight to twelve entries; every word listed in §2 above appears.

## 8. Markdown and build
- Source: `docs/report_v3_en_public.md` (the register above); `docs/report_v3_en.md` is the technical companion and follows §3–4 but not §1.
- Build: `python3 scripts/build_report_html.py` → `docs/html/bread_economy_report_en.html`, self-contained, light and dark, phone-safe. The build renders each frame's markdown separately (raw HTML blocks are not converted otherwise) and refuses to build if the disclaimer or the navigation line is missing.
- Publish with the Artifact tool, updating the existing artifact's URL rather than creating a new one; favicon 🍞.
- Links: the artifact viewer blocks a plain click on a link, in the frame and in a new tab alike; a reader can still open it with a right-click or by copying the address. Every link must therefore be right-clickable: an address that appears as plain text (the repository address in the disclaimer, the address in brackets after a navigation link) is itself an `<a>` — the build makes it one — so that a reader can right-click it; where an embedded link and a literal address both exist, either will do. Every external link opens in a new tab (`target="_blank" rel="noopener"` — the build adds it; a click inside the artifact frame does not navigate otherwise), and link colour is a theme variable readable on both backgrounds (`--link`: dark orange on light, light orange on dark), never the browser default purple.
- Other languages: the same file structure per language; the front matter (title, navigation, disclaimer, reading frame) is translated first; untranslated sections carry one line saying so and then the English text.

## 9. The "what is there" panel
Every step of the ladder opens with a two-column panel — debt money left, SuMSy right — listing what the village contains at that step, **even where nothing changed from the step before**: the number of villagers and landowners; the number and kind of firms, with cooperatives and theatre seats where they apply; the founders and whether shares trade; how the money is made (bank rates and the government's borrowing rate, or the guaranteed income, cushion and parking fee); the government (public jobs, benefit, every tax rate, bonds); public finance (reserve, tax policy and levers) where present; the starting prices and wages in money, with a full month's wage spelled out; and greed where present. The panel is generated by `scripts/build_report_html.py` from `results/ladder2_<N>_rungs.csv`, which `scripts/dump_rungs.jl` writes from the effective parameters of each rung — never typed by hand.
