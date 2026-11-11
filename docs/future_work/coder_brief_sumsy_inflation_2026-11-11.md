# Coder brief — trace the SuMSy village's inflation

*11 November 2026. For the coder working on Stef's machine. Model version `2026-11-11.0` on EconoSim 0.3.1; suite at 76,290 tests.*

## 1. The question

In the SuMSy village the price of bread rises by about 4 % a year on the realistic ladder (step 8: +4.2 %, ten runs, 120 months). Nobody has traced why. Report version 5 says so in as many words, and it should not have to.

Three things need an answer:

1. **What drives the rise?** Money, wages, costs, demand, or a rule of the model.
2. **Does it last?** Ten years of 4 % could be a transition to a new price level or a permanent rate. The two mean very different things for SuMSy.
3. **Is it a property of SuMSy, of the wage rules, or of a parameter?** The answer decides whether the report describes it as a design weakness or as a modelling choice.

A wrong answer here is worse than no answer. If the evidence does not settle a point, say so.

## 2. What is already known

All figures are ten-run means of the yearly change in the bread price, SuMSy village, 120 months, from `results/ladder2_512_2026-11-10.1_summary.csv` (standard) and `results/ladder2_512_realistic_2026-11-10.1_summary.csv` (realistic). The cell is the first word of the `rung` column.

| cell | what differs from step 8 | standard | realistic |
|---|---|---|---|
| `8` | (the reference) | −6.2 % | **+4.2 %** |
| `J8-100` | every worker on a contract (`contracts = true, contract_share = 1.0`) | +0.6 % | |
| `Y8-noloyalty` | employers hire the cheapest, not their own (`employer_loyalty = false`) | +0.1 % | |
| `Y8-nonotice` | no notice period (`notice_months = 0`) | **+20 %** | |
| `LPT8` | landowners pass the land levy on in rents (`levy_pass_through = true`) | | **+23.5 %** |
| `NDC8` | firms in distress do not cut costs (`distress_cost_cutting = false`) | | **+22.4 %** |
| `GP8-50` | half the village in public jobs, parking-tax policy | | +16 % |
| `Q8` | 5 % of villagers not working (`nonworking_share = 0.05`) | −4.6 % | +9.5 % |
| `S3` | everyone greedy (version `2026-11-11.0`) | −4.2 % | +6.7 % |
| `V8` | three times as productive | | −10.1 % |
| `P8` | prices fixed | 0 | 0 |

Read the empty cells from the summaries yourself; I have only quoted what I have checked.

**The lead.** On the standard ladder the labour rules alone move the SuMSy village's price drift from −6 % a year to +20 %. The realistic ladder differs from the standard one in its labour rules (`REALISTIC_LABOUR` in `scripts/run_all.jl`: contracts with `contract_share = 0.8`, and more) and in the wage floor. So the first suspect is the way wages are set, not the money.

**Two facts about the money that constrain any explanation.** The guaranteed income is 5 a month and the fee-free cushion is 30, both fixed in money terms; neither rises with prices. The fee destroys 2 % a month of what a person holds above the cushion. If that pins the amount of money, then prices cannot rise 4 % a year forever unless money changes hands faster every year. Check this before anything else (step B): it tells you whether you are looking at a transition or a permanent rate.

**Related findings, for context.** The wage floor (`wage_cut_maximum = 0`, `wage_indexation = true`: wages are not cut and rise with the bread price) doubles the nominal level of wages and prices in one tested run (step 8, SuMSy, one seed: wage 2.67 → 5.72, bread 3.53 → 7.25 at year ten) without changing who owns what. The debt village under the same rules is steady at +0.6 %.

## 3. Ground rules

- **Do not change the ladder's base.** Every new behaviour is a switch in `src/parameters.jl`, off by default, so that the golden values in `test/runtests.jl` do not move. Instrumentation (counters, extra columns) must not change any result: the suite must pass unchanged after you add it.
- **Evidence comes from paired runs.** Same seeds with the switch on and off. Four seeds are enough to explore; anything that goes into a table for Stef needs ten.
- **One change at a time.** If two switches are needed to see an effect, show each alone as well.
- **Report what failed.** A hypothesis that the data rejects is a result. List it.
- **Record the version.** Every table carries `MODEL_VERSION` and the seeds.
- Run the suite (`julia --project=. test/runtests.jl`, about six minutes) before committing anything in `src/`.

## 4. How to run one village

```julia
include("scripts/run_all.jl")                       # loads the package, the ladder and REALISTIC_LABOUR
def = ladder_definition(512, 120, :invoicing)       # villagers, months, settlement
(name, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))   # a cell by its first word; kd = debt village, ks = SuMSy village
m = run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., REALISTIC_LABOUR...))   # leave REALISTIC_LABOUR out for the standard ladder
d = round_data(m)                                   # one row a month; names(d) lists the columns
```

To change one rule, append it: `SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., REALISTIC_LABOUR..., wage_indexation = false)`. Later keywords win.

For many paired runs use `scripts/planning_ablation.jl`: add a named entry to `ABLATION_VARIANTS` (a `NamedTuple` of the switches to change) and call, for example,

```julia
include("scripts/planning_ablation.jl")
ablation(cells = ["8 "], seeds = 1:10, variants = [:base, :your_variant], jobs = 6)
```

It runs both villages on the realistic rules, writes one file a run under `results/parts/ablation_<version>_<variant>/`, and a run table `results/ablation_<version>_<variant>_runs.csv`. It resumes if interrupted.

## 5. The work, in order

### Step A — describe before explaining (no code changes)

From the part files of the `10.1` ladders (`results/parts/ladder2_512_realistic_120months_2026-11-10.1/8_*__sumsy__*.csv` and the standard folder), for step 8, ten seeds each, by year:

1. The yearly change of every price: `price_bread`, `price_wage`, `price_service`, `price_grain`, `price_rent`, `land_price`. Which rises first, and which fastest?
2. The real wage (`price_wage / price_bread`) and what a full-time worker's pay buys.
3. Whether the rate is steady, rising or fading across the ten years. Fit nothing fancy: years 1–3, 4–7, 8–10.
4. The same for the debt village at step 8 (steady at +0.6 %) as the control.

Check each column name against `names(d)` before using it; I have listed them from memory of the data files.

### Step B — the money

1. The amount of money over time (`money_in_circulation`; persons' share is `cash_persons`), and money made and destroyed each month (`money_created`, `money_destroyed`).
2. Spending each month at current prices (bread, services, grain, wages), and from it how fast money changes hands: spending divided by the amount of money.
3. **The test:** if prices rise 4 % a year, either the amount of money rises about as fast, or money changes hands faster every year. Which is it? If the amount of money is flat, the rise has to end, and step C's question becomes "what is the new level and when is it reached?".
4. Run step 8 for 480 months on four seeds (`ladder_definition(512, 480, :invoicing)`) and report the yearly change by decade. This is the direct answer to "does it last?".

### Step C — the wage and price rules, one at a time

Paired runs at step 8, SuMSy village, realistic rules. Start with four seeds, then ten for the ones that matter. Each line is one variant:

| variant | switches | what it tests |
|---|---|---|
| no indexation | `wage_indexation = false` | wages following bread upward |
| no floor | `wage_cut_maximum = 1.0, wage_indexation = false` | the wage floor as a whole |
| floor, no indexation, and the reverse | as needed | which half matters |
| every worker on contract | `contract_share = 1.0` | the lead from `J8-100` |
| no contracts | `contracts = false` | |
| no loyalty | `employer_loyalty = false` | the lead from `Y8-noloyalty` |
| no notice | `notice_months = 0` | the lead from `Y8-nonotice` (+20 % on the standard ladder) |
| smaller price steps | `ask_increase_after_sellout = 0.02, ask_decrease_after_partial_sale = 0.02` | the size of a price move |
| benefit not indexed | `benefit_indexed = false` | public spending following prices |
| no entry | `market_entry = false` | new firms bidding for workers |
| no expansion credit | `expansion_credit = false` | credit-financed bidding for workers |

For each: the yearly change of bread and of the wage, the real wage at year ten, people without work, firms wound up, and the wealth Gini, with the base beside it. The interesting variants are those that bring the rise near zero without breaking something else.

Then repeat the two or three decisive variants on the standard ladder (leave `REALISTIC_LABOUR` out), where the reference deflates by 6 % a year. An explanation has to account for both signs.

### Step D — who moves first

If step C points at a loop between wages and prices, show the loop directly. This needs instrumentation, behind a switch that is off by default or as extra columns that do not change results:

1. Each month, how many sellers raised their price, by good, and why: sold out, cost floor, or the expected-sales rule (`src/negotiation.jl`, where asks are adapted).
2. Each month, how many wages rose, and why: indexation to bread, or an employer bidding for workers it could not find.
3. From the monthly series: does a wage rise precede a bread price rise or follow it? Cross-correlate the monthly changes at leads and lags of up to six months, per seed, and report the ten-seed mean.

State the loop in three sentences once you have it, and name the one rule without which it does not run.

### Step E — the villages that inflate fast

For `LPT8`, `NDC8`, `GP8-50` (realistic) and `Y8-nonotice` (standard): repeat steps A and B briefly, then say which part of the mechanism from C and D each one amplifies. `LPT8` is the one that matters most for SuMSy's design: if the levy on land is passed on in rents, and rents feed prices, and the levy follows land values, is that a loop with a ceiling or without one? Run it for 480 months as well. Note that `NDC8` is the one SuMSy village whose government borrows (about 5,000); find out why.

## 6. What to deliver

One markdown file, `docs/future_work/sumsy_inflation_trace_<date>.md`, with:

1. **The answer in a paragraph:** what drives the rise, whether it lasts, and whether it belongs to SuMSy's design, to the wage rules, or to a parameter.
2. **The descriptive tables** of steps A and B, with the debt village beside the SuMSy village.
3. **The paired-run table** of step C, every variant, including those that changed nothing.
4. **The mechanism** from step D, with the lead-lag evidence.
5. **The fast-inflating villages** of step E, one paragraph each.
6. **What was tried and rejected,** and what remains uncertain.
7. **Candidate remedies,** if any, each as a switch that is off by default, with its paired-run effect on prices *and* on survival, work, firm failures and the spread of wealth. Do not turn any of them on in the base; that is Stef's decision.

Every number carries the model version, the ladder (standard or realistic), the cell, the seeds and the months.

## 7. Things that will mislead you

- **A single seed.** Runs differ a great deal. One run that confirms a hunch proves nothing.
- **The price level against its rate of change.** The wage floor raises the level. Whether it raises the rate is a separate question; keep them apart.
- **Columns that sound alike.** `unemployed` counts people who offered work and sold none; the SuMSy village offers less work than the debt village (68 % of capacity against 92 %), so compare work done (`labour_sold / persons_alive`) as well.
- **The two ladders.** They disagree on the sign of the SuMSy village's price drift. A result on one says nothing about the other until you have run it.
- **Background runs that die silently.** Check that every expected file exists and has 120 rows before reading a table.
