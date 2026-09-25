# START HERE
*For a new session picking up BreadEconomySim.jl. Written 25 September 2026. This page is the current state; `HANDOFF_2026-09-18.md` is the chronological log behind it (older entries there are superseded where they disagree with this page).*

## 1. What this is
An agent-based simulation, in Julia, of one village built twice — debt money and SuMSy (guaranteed income + parking fee) — identical except for where money comes from. A **ladder** adds one institution per step to both villages; results are the survivors, prices, public debt and the rich–poor gap after ten years, ten runs per configuration, 512 villagers. It feeds a public report (English first, Dutch and others later), Stef's Dutch book on SuMSy, and a talk on **25 October 2026** ("A simulated economy – What it takes to survive").

## 2. Where things stand
- **Model version `2026-09-25e`** (`MODEL_VERSION` in `scripts/run_all.jl`), **584 tests** (`julia --project=. test/runtests.jl`), Julia **1.13**, EconoSim.jl from GitHub (branch main).
- **The full run on this version** was started by Stef on the evening of 25 September (about 2,250 runs, ~6 hours on his machine); it includes the wage threshold and no bailouts without a government. Its results are **not on GitHub** (files too large): Stef uploads a `results.zip`. Rebuild the summaries from its `results/parts/` with `SKIP_TESTS=1 julia --project=. scripts/run_all.jl` (skips finished runs, then summarises).
- **Stef is away from his computer 26 September – 11 October.** No 512-villager runs are possible in that window; the 128-villager ladder is feasible in a chat container (slow).

## 3. The plan to 25 October
**Division of labour (Stef, 25 September):** everything code-related — runs, analysis, fixes, the report build — happens in the *code* chat; the talk (outline, slides, rehearsal) is prepared in a *separate* chat in the same Project. The code chat hands the talk its numbers through `docs/talk/talk_numbers.md` (below).
1. From the 25 September results: check the model (in particular the 5 deaths seen at step 8 of the debt village in one check run after the land-market change), pick the transition's starting villages and target, write **version 4 of the public report**.
2. **Fill `docs/talk/talk_numbers.md`** from the same results — every number the talk quotes (the asterisked ones in `docs/talk/talk_outline_2026-10-25.md`), each with the step, the village, the measure and the file it comes from. If a number changes the story (e.g. a claim no longer holds), say so there in one line.
3. Any fixes the results call for: made and tested, run once on Stef's machine on **11 October**, then **freeze the model** as the report baseline and refresh `talk_numbers.md`.
4. After the talk: modularity refactor stage 1 (`docs/future_work/modularity_report_2026-09-25.md`), then the transition (`docs/future_work/design_transition_2026-09-23.md`).

## 4. The ladder (redefined 25 September)
Realistic price rules (5 % thresholds, cost floor, buyer ceiling 2.0) from step 0; invoicing settlement; founders distinct per firm with founding loans on business terms; the protected minimum of one loaf; villages run on without farms or bakeries and missing firms are restarted (theatres too, with a 3-month wait); land prices discovered by the money logic.
Steps: 0 bare · 1 planning margin · 2 government · 3 interest on deposits · 4 theatres · 5 bonds · 6 charge on balances · 7 four theatres · 8 shareholders & share market · 9 co-ops (side step) · **10 government reserve** · **11 fiscal policy and consumption tax**.
Variants: S1–S4 greed stress tests (steps 10, 11) · B co-op village (+ reserve) · SB1, SB2 greed on B · E2, E8, E10, EB full money stock (start at base prices) · L2, L10, LB land levy · LD10 levy + land dividend · N8, N10, NB, NLD10 market entry · G8/G10-20…50 public employment · GP10-20…50 SuMSy public employment with a parking-tax policy · X1, X2 the 2×2 (comparisons).

## 5. Standing decisions and principles (Stef's)
- **SuMSy never taxes income** (income tax under SuMSy only as a labelled comparison). The parking *fee* is money, not tax; the parking *tax* is the government's revenue.
- A SuMSy village has no public debt in steady state; during the filling-up it borrows its citizens' savings and repays them (a finding: the startup cost). "Least indebted" is a debt-village label; the best SuMSy village is judged on no hunger and the rich–poor gap **together with the poorest tenth's own holding**.
- Price rules are behaviour, not policy: realistic rules everywhere. Rules found to be defects are removed, not kept as steps.
- The rich–poor gap: richest tenth minus poorest tenth, **in meals**, always shown with the poorest tenth's holding. No ratios.
- A broad rise in prices is inflation; SuMSy *caps* it when the money stock reaches its equilibrium.
- Every tax is a family on the levers (income, consumption, wealth, profit, parking, land); the reserve rule adjusts taxes down on a surplus (floor 5 %).
- The guaranteed income is not to be touched; the parking fee is the lever (a future monetary-policy rule).
- Public employment is employer of last resort (up to a share of capacity, from leftover labour).
- Report register: general public, as the book chapters *Goed geld* / *Slecht geld* (project knowledge); technical detail in `\[ KADER … \]` frames; terms "guaranteed income", "parking fee", "parking tax"; see `docs/report_style.md` (binding).
- Each report version links to the previous and next; errata go in a box on the older version; every link right-clickable.

## 6. Where everything is
| | |
|---|---|
| code | `src/` (credit.jl is settlement, credit, liquidation, founding, entry; markets.jl the markets and land) |
| runs | `scripts/run_all.jl` (everything, parallel, resumable), `scripts/ladder_definition.jl` (the ladder), `RUN_LOCALLY.md` |
| designs built | `docs/designs_implemented/` |
| future work | `docs/future_work/` (transition, modularity, report plan; README lists unwritten items) |
| report | `docs/report_v3_en_public.md` (public register), `docs/report_v3_en.md` (technical), build `scripts/build_report_html.py`, style `docs/report_style.md` |
| talk | `docs/talk/talk_outline_2026-10-25.md` |
| reviews | in the claude.ai Project's knowledge (`BreadEconomySim_critical_report_*.md`), not in the repository; the latest is report 6 (on model 2026-09-24f) |
| the log | `HANDOFF_2026-09-18.md` |

## 7. Working with Stef
Peer-reviewer stance: examine every claim, disagree when the ground is shaky, no flattery; avoid "it's not X but Y" and "that's no coincidence". Design decisions are his — propose with a default, don't implement design changes unasked. Tell him plainly when something was wrong, including your own earlier statements.
