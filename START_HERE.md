# START HERE

*For a new session picking up BreadEconomySim.jl. Rewritten 16 October 2026. This page is the current state; `HANDOFF_2026-09-18.md` is the chronological log behind it, newest at the bottom.*

## 1. What this is
An agent-based simulation, in Julia, of one village of 512 people built twice — debt money and SuMSy (a guaranteed income, a parking fee on idle money, a parking tax, and from step 8 a levy on land paid out as a dividend) — identical in people, land and behaviour, different only in where money comes from. The village is built up on a ladder of steps (0–11) and put through some seventy variant cells. Results feed the public report (version 4, published at https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm, chained to version 3), the talk of 25 October (`docs/talk/`), and Stef's PhD and Dutch book.

## 2. Where things stand
- **Model version `2026-10-16.1`** (`MODEL_VERSION` in `scripts/run_all.jl`: the date the version was made, then .0, .1, … — bump it whenever the model or the ladder changes). **683 tests**. Julia **1.13**; EconoSim.jl from GitHub (main).
- **The ladder:** 113 steps, 183 village configurations (`scripts/ladder_definition.jl`); a side a step leaves empty is not run; 15 mirror cells are copied. About 1,680 runs, roughly four hours on Stef's machine (15 workers).
- **The run on 2026-10-16.1 is in progress (16 October).** The report is on the run of 15 October (`2026-10-15`) and moves to 2026-10-16.1 when it is in. **The folder `…_2026-10-16` (made 15 October) has the month-2 hunger regression and is not usable.**
- `run_all.jl` is resumable (finished part files are skipped) and runs the test suite once per version and code (a fingerprinted marker in `results/`, per machine). The summary reads only the current ladder's steps.
- This chat's container is reset now and then; the packages in the outputs and the GitHub repository are where nothing is lost. To rebuild: unzip the latest package, reinstall Julia 1.13, add the General registry from GitHub (`JULIA_PKG_SERVER=""`), `Pkg.instantiate()`.

## 3. Next
1. When the 2026-10-16.1 run is in: move the report to it (every figure), put in §18 the MMT paragraph (`docs/report_v4_s18_mmt_draft.md`) with the ten-run means of EU8, D8-60 and RV8, correct §10–§11 (most of the productive village's failures were farms; it now runs with free prices), the hoarders (the government loop; HC8 and HC8-10 beside it), Gesell's pass-through (LPT8, DDL8-PT); refresh `docs/talk/talk_numbers.md` and the deck (`docs/talk/deck/`, `node build.js`).
2. Open traces: why the public-jobs village with free prices and a balanced budget (UP8) dies completely; the greedy SuMSy village's late hungry month (if still there); the paid theatre's drifting asking price; the mechanism by which the labour rules set the sign of the SuMSy price trend.
3. After the talk: the Dutch report; the transition (`docs/future_work/design_transition_2026-09-23.md`); Gesell's own land scheme (public purchase, lease, rent paid out) as a village; the modularity refactor (Stef's MacroSim.jl).

## 4. The ladder
Steps: 0 bare · 1 planning margin · 2 government (public jobs, the benefit: two loaves debt, one loaf SuMSy) · 3 interest on deposits (debt only) · 4 theatres · 5 bonds (debt only) · 6 charge on firms' idle reserves · 7 four theatres · 8 shares and a share market; SuMSy: the land levy and its dividend · 9 (side) co-ops · 10 reserve · 11 fiscal policy and VAT.
Variants by family: fixed prices (P, V8-P, U8-P, UP8-P) · full employment (V8 the productive village; U8/UP8 public jobs; KV8 premium loaf; T8 transport line) · labour rules (M0/M8 the sharing margin; Y8 floor, loyalty, notice) · policies (A8 austerity; D8 debt ceilings; D8-60 and EU8 the euro rule; I8 the fixed benefit; F8/FF8 the parking fee; RV8 the income halved) · the debt-money twins (DGI8, DD8, DDL8, DDGL8, DDGL8-35, DDL8-PT) · land (Z8/RZ8 no levy; LPT8 the levy passed on; L2) · behaviour (S stress tests with greed; H8 the richest 1 % greedy; HC8/HC8-10 cash hoarders; Q8 not working; C8 and CT8 volunteers; R8 gold) · entry (N) · the public sector (G, GP) · cost cutting (NDC8, V8-NDC) · comparisons (X1, X2).

## 5. Standing decisions and principles (Stef's)
- **SuMSy never taxes income** (income tax under SuMSy only as a labelled comparison). The parking *fee* is money destroyed; the parking *tax* is the government's only tax; the levy on land is paid out in full and never cut.
- Behaviour is the same in both villages; the report says so and what it costs. Price and labour rules are behaviour, not policy; rules found to be defects are removed, not kept as steps.
- No village starves for want of hands: offers are sized on the village's need, and everyone offers everything when bread or hands fell short. Work is also done for its own sake (a minimum offer; unhired hours counted as volunteer hours).
- New behaviour is a switch; realistic behaviour is on by default (cost cutting), anything that would change the reference tests is on through the ladder's `RULES` (planning on sales).
- The rich–poor gap: richest tenth minus poorest tenth, **in meals**, always with the poorest tenth's holding. Gold is reported beside wealth, never in it.
- A finding is reported from ten-run means of one run of one model version; single runs are labelled as such. The report keeps legislation out; the monetary-sovereignty context gets one sentence.
- The greedy and the cash hoarders are chosen at month 12, once a trend shows. Those who do not work are "not working for reasons of their own", never "lazy".

## 6. Where things are
- `src/` the model · `test/runtests.jl` · `scripts/ladder_definition.jl` (the ladder, `RULES`) · `scripts/run_all.jl` (one command, parallel, resumable) · `scripts/build_report_v4_html.py` (the report page) · `scripts/dashboard_tables.py` (the dashboard's parameter tables).
- `docs/report_v4_en_public.md` (source of the published report) · `docs/report_style.md` · `docs/dashboard_spec.md` (version 3) · `docs/talk/` (outline, numbers, deck) · `docs/future_work/` (transition, work as purpose, modularity, systemic-and-knobs) · `docs/designs_implemented/`.
- `HANDOFF_2026-09-18.md` — everything, in order.
