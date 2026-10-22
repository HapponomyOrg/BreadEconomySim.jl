# Handoff for the talk — "A simulated economy: what it takes to survive" (Sunday 25 October 2026)
*Written 22 October 2026 for a separate chat that works on the talk while the simulation chat keeps tweaking the model. This document is the bridge: what the talk is, what it may claim, where every number comes from, what is still moving, and how the two chats hand things back and forth. Stef reads it first; the talk chat reads only this file and the files it names.*

---

## 1. What the talk is

- **12 minutes at most.** Its job is to make people curious about the work, not to prove it. Fewer claims, better told.
- **It is about a work in progress, and the struggle has a place in it.** The realistic results go in even where things are not stable, with a comment to that effect. The audience should see how a result is made and unmade, not only the finished number.
- **Every side-by-side comparison is on the same fiscal and market rules.** The two villages differ in one thing only: how money works. **The 2026-10-20.4 ladder does not meet this rule**: it gives each money its own fiscal package (the debt village income taxes and a 2-loaf benefit, the SuMSy village a parking tax, a 1-loaf benefit, the land levy with its dividend and a reserve from step 8). The common-package runs (`fiscal = :taxes` and `:parking`, see §6) are what the side-by-side numbers come from; the 20.4 numbers in §4 are the per-money packages and must be labelled as such wherever two villages are set beside each other.
- **The question** (Stef's opening): can our current monetary system support a steady-state economy where public debt is manageable and everyone can have a good life? "Working" is defined in the intro: feeds everyone, with prices left free, without a public debt that must grow forever. The two premises stated with it: governments will not accept ever-rising debt; the economy does not grow (so a rising debt is a rising burden).

## 2. The opening text as it stands (Stef, 22 October) — with the simulation chat's review notes

> Can our current monetary system support a steady state economy where public debt is manageable and everyone can have a good life?
> Before I came to economics I had a career in IT. I also love complex board games and simulation games. Economics is basically a complex serious game and economists have been creating models for it since the 18th century so I decided to create a computer simulation of a small village running on two different monetary systems in order to find out which village would have the best survival chances and where live would be pleasant when survival is successful. The villages have a fixed population and a fixed production capacity that is enough to satisfy everyone's needs. In other words, a steady state economy.
> The first village uses the money we have today. It is created by the banks whenever they issue a loan and it's destroyed when instalments of the loan are paid back. For that service the banks charge interest which they collect as profit. This profit is used to build up a reserve and to pay their employees.
> The second village uses the Sustainable Money System I'm doing my PhD on. There an equal amount of money is created in each account at the beginning of the month and at the end of the month a parking fee on the remaining amount is collected and destroyed. There are still banks in that village. Those banks function as intermediaries between savers and borrowers and charge a small fee for managing the loan.
> The village starts with a bare bones setup of two banks, a quarter of the village as landowners, two farms and two bakeries. Farms buy or rent land from the landowners according to market rules to grow grain on, bakeries negotiate on a grain price and sell bread to the market at a price people are willing to pay. Afterwards more economic artifacts are added. Behaviour of the actors is the same in both villages. Only the way money works is different in every comparison.
> This is still a work in progress. I'll show you what the simulations brought to light so far.

Review notes (facts and wording; the talk chat decides what to do with them):
- **Bare bones has four farms and four bakeries, two banks** (not two farms and two bakeries). 512 villagers, 128 landowners (a quarter) with six plots each — 768 plots. Everyone needs two loaves a month; bread spoils after three months; everyone starts with 30 in money; a loaf starts at 5, a unit of work at about 4.
- **"Fixed production capacity that is enough"** is right in spirit: 512 people × 4 units of work a month is far more than the bread needs. Supply is *planned* to demand; capacity is not the limit. The honest phrase is "enough hands and land to feed everyone twice over".
- **"A parking fee on the remaining amount"** — say "on whatever is left above a small cushion" (the cushion is 30, three meals at the start), or the audience hears a tax on all savings.
- **"The banks charge interest which they collect as profit"** — accurate for the model; "the banks earn their living from the interest" keeps the mechanism without the edge.
- **Typos:** "live would be pleasant" → "life"; "artifacts" → "elements" or "institutions".
- **The money-stock bound is worth one sentence** if the SuMSy description gets a third: the income divided by the fee is the most money the village can hold (250 a head), so the money cannot run away.
- **Do not say "it will never succeed."** The village's own result is narrower and stronger: in every village built so far, the money we use today could not do all three (feed everyone, free prices, no ever-growing debt); the other money did, every time from the moment it had a government. See §4.

## 3. Where the numbers come from

**The talk's run: `results/parts/ladder2_512_120months_2026-10-20.4/`** (ten seeds, every step), with `results/ladder2_512_summary.csv` (one row per step and village: means, medians, quartiles, 5th–95th bands) and `results/ladder2_512_rungs.csv` (what each step contains). This run **reproduces the 17 October run exactly** in every behavioural column (all 1,910 runs both have — checked run by run), so the published report v4 (https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm) and `docs/talk/talk_numbers.md` (last refreshed 13 October on an older run — refresh it from 20.4 before use) rest on the same behaviour. 20.4 adds the three Ginis, bond ownership and the distributions.

**Scripts:** `scripts/report_numbers.py` (every figure the report quotes, from one run's parts), `scripts/paired_tests.py` (the two villages compared seed by seed: Wilcoxon, Holm), `scripts/dashboard_tables.py`. The deck: `docs/talk/deck/build.js` (node) from `docs/talk/deck/data.json` → `what_it_takes_to_survive.pptx`. The outline: `docs/talk/talk_outline_2026-10-25.md` (25 September; eleven slides; the thread and the "leave open" questions are still the right shape; its numbers are old).

**The realistic set** (what the model looks like with the realistic labour market and pricing of 18–22 October): run with `run_all(variant = REALISTIC_LABOUR, variant_label = "realistic")` into `results/parts/ladder2_512_realistic_…`. The greed-against-sufficiency runs: `results/pricing_strategy_summary_realistic.csv` and `_expected_contracts.csv` (ten seeds, step 8, half of each sector on margins). The tiered-demurrage test: `results/tiered_demurrage_test.csv`.

**Steps the talk uses** (names as in the summary's `rung` column): `0 bare bones`, `2 + government` (benefit, public jobs, taxes), `5 …` (bonds), `8 shareholders, share market`, `11 …` (VAT), `B best SuMSy / co-ops`, `V8 productive village` (free prices, balanced budget), `D8-60` (a 60 % debt ceiling), `A8` (austerity), `DGI8` (a basic income in debt money), `EU8` (basic income under a debt rule), `RV8` (the income halved from year five), `S3 step 10, everyone greedy`, `R8` (gold), `K8` (premium loaf), `PL8` (public land), `LPT8` (the levy passed on). Mirror cells (same configuration under another name) are copies.

## 4. What may be said, and the numbers (2026-10-20.4, ten-run means; worst run in brackets where it matters)

**Survival (alive of 512 after ten years):** step 0: debt 153, SuMSy 455 (no government: the SuMSy income of 5 buys less than a meal when bread is dear — say so). Step 2 (a government): debt 510, SuMSy 512. Step 8: debt 488, SuMSy 512. Step 11: debt 436.5 (worst run 408; bread −10.9 % a year; poorest tenth −4.7 meals), SuMSy 512. Productive village (free prices, balanced budget): debt 478 with 101 failed firms and prices falling 11 % a year; SuMSy 512. Everyone greedy: both 512. Public land with rents: debt 239, SuMSy 512 (a quarter-loaf dwelling rent on a two-loaf benefit starves the unemployed).

**Public debt:** the debt village borrows every month to pay for the people it leaves without work — 144,000 at step 8 after ten years, 340,000 with a basic income (DGI8, everyone alive), about zero only in the productive village (22,000, flat). The SuMSy government borrows once, at the start (4,870 at step 2, repaid by month 33; 608 at step 8, repaid by month 22), then never — and note that the fall from step 7 to step 8 is the land levy and its dividend switching on for SuMSy only in the 20.4 ladder. A 60 % debt ceiling (D8-60): 313 alive. Austerity (A8): 446 against 488. A basic income under a debt rule (EU8): the income is cut to a fifth when the rule binds, 494 alive, hungry from year five.

**The three conditions** (feeds everyone / free prices / no ever-growing debt): no debt-money configuration meets all three; SuMSy meets them from step 2 on. The productive village is the counter-case someone will raise (balanced budget) and it fails the first condition.

**Prices:** without contracts both villages deflate (debt −3 %/yr, SuMSy −8 %/yr at step 8); contracts (the realistic set) hold prices (about −1 %/yr); fixed prices are excluded from the talk.

**Inequality, step 8 (Gini of cash / wealth without gold / everything)** — SuMSy's lower wealth Gini holds from step 8 on; at steps 2–7 both villages sit near 0.74, and in the 20.4 ladder step 8 is also where the levy, the dividend and the reserve switch on for SuMSy alone, so the common-package runs decide whether the shares or the package did it: debt 0.36 / 0.78 / 0.78; SuMSy **0.60 / 0.45 / 0.45** — the SuMSy village's cash is *more* unequal, its wealth far less; show both or someone will ask. Poorest tenth: debt 0.8 meals, SuMSy 16. Everyone greedy: debt 0.36 / 0.73, SuMSy 0.29 / 0.15. Gold: both about 0.9 on everything — gold is reported beside wealth, never in it. Who holds the debt village's bonds (step 8): 104,000 in bonds, 60 % held by the richest tenth; the banks' retained money 12,000; in the productive village the banks' money is about the whole rise of the public debt. Stef's own paper (Kuypers, Goorden, Delepierre 2021) is the frame: no growth imperative in debt money *only if nothing accumulates*.

**Paired tests (2026-10-17.0 = same behaviour):** SuMSy keeps more alive in 10 of 10 pairs at every headline step (p = 0.002, Holm 0.020); owes nothing against six figures 10 of 10; its poorest tenth hold more at the headline steps the tests covered (2, 8, 11, the co-ops, V8) except step 0 (9 of 10) and the halved income (the debt village's poorest higher); at step 5 the SuMSy poorest hold 3.9 meals against the debt village's 4.8 (ten-run means), so "everywhere" is wrong. Ten pairs cannot see less than the spread — say so.

**Caveats to state once:** the income (5) and the cushion (30) are fixed in money, so a deflating village makes them worth more every year and an inflating one less — part of SuMSy's record at the later steps is that drift; the villages do not grow; one step of the ladder is one configuration, not a calibration.


## 4b. The same fiscal rules on both sides — the numbers for the side-by-side slides (22 Oct, four seeds, version 2026-10-22.12)

Four folders: package T (income taxes 15/15/30/10 %, benefit 2 loaves, public jobs 10 %) and package P (a 1.5 % tax on balances above a cushion of 30 instead of income taxes), each with the base labour market and with the realistic set. From step 8 both villages carry the land levy, its dividend and a 3-month reserve, surplus paid per head. Four seeds; the worst run in brackets. **These are the numbers to put beside each other.** Step 0 (no government) is the same under any package: debt 149 (144), SuMSy 453 (450).

**Base labour market, package T — alive / public debt / poorest tenth (meals) / wealth Gini:**

| step | debt village | SuMSy village |
|---|---|---|
| 2 government | 510 (510) / 198k / 1.0 / 0.74 | 512 / 0 / 16.0 / 0.74 |
| 8 shares | 477 (466) / 122k / 0.6 / 0.78 | 512 / 0 / 21.1 / 0.53 |
| 11 VAT | 390 (379) / 25k / −5.0 / 0.81 | 512 / 0 / 28.7 / 0.45 |
| V8 productive | 475 (467) / 18k / −4.1 / 0.66 | 512 / 0 / 76.9 / 0.22 |
| S3 everyone greedy | 480 (469) / 178k / 1.8 / 0.68 | 512 / 0 / 23.4 / 0.42 |

**Base labour market, package P:**

| step | debt village | SuMSy village |
|---|---|---|
| 2 | 510 (509) / 99k / 1.1 / 0.75 | 512 / 0 / 18.3 / 0.74 |
| 8 | 480 (448) / 18k / 0.8 / 0.70 | 512 / 0 / 17.4 / 0.52 |
| 11 | 425 (409) / 0.1k / −1.5 / 0.70 | 512 / 0 / 15.8 / 0.41 |
| V8 | 468 (458) / 22k / 0.2 / 0.60 | 512 / 0 / 38.9 / 0.25 |
| S3 | 494 (481) / 94k / 1.0 / 0.75 | 512 / 0 / 29.0 / 0.18 |

**What holds on identical rules, and may be said:** (1) with a government the SuMSy village keeps all 512 in every seed at every step, the debt village loses 2 to 122 people; (2) the SuMSy government never borrows, the debt village's borrows at every step under T (18k–198k) and far less under P — the parking tax funds its budget at steps 8 and 11 — but its people still die; (3) the poorest tenth: 16–77 meals in the SuMSy village against −5 to 1.8 in the debt one; (4) the wealth Gini: equal at step 2 (0.74 both), lower in the SuMSy village from step 8 (0.52–0.53 against 0.70–0.78; 0.22–0.25 against 0.60–0.66 in the productive village) — so the 20.4 gap was partly the levy's doing, and on the same rules it is smaller but it is there; (5) the SuMSy village's **cash** Gini is the higher one at step 8 (0.45–0.62 against 0.33–0.35) — show both Ginis. Prices deflate in both villages at every step (SuMSy faster); fixed income and cushion caveat as in §4.

**The realistic set on the same rules** (contracts 0.8, own-market planning, the :long floor, …): the same pattern, the debt village losing more — package T: debt 473 (409) at step 2, 435 (430) at step 8, 410 (400) at step 11, 454 (442) productive, 474 (451) greedy; SuMSy 512 at every step with a government (511, worst 508, at step 8); package P: debt 499 / 450 / 439 / 481 / 484; SuMSy 512. Step 0 under the realistic set: debt 16 (12), SuMSy 473 (358) — the bare-bones debt village cannot survive contracts and own-market planning without a government. Prices: SuMSy near the base's at steps 8 and 11, the debt village deflating 9–17 % a year under P. The realistic numbers are four seeds on a set frozen this afternoon; say so.

Not in these folders: the paired tests (run per folder, never across), the levy rates charged (§3.5) and the deposit interest paid (§3.12); the talk chat should ask for them by name.

## 5. The realistic results — in, with the struggle

**What the realistic set is** (18–22 October): contracts for four fifths of the hands (indexed to bread, three months' notice both ways), firms planning on their own market (three-month average of sales plus turned-away customers, net of stock; prices move only against expected sales; an adaptive buffer), the cost floor carrying the interest and the long loans' instalments and spreading what spoils over what sells, at least two firms of each kind, failing firms offered for sale before closure, farms buying land only on a term the rent and the reserve can carry, the land price meeting the best offer. Set `REALISTIC_LABOUR` in `scripts/run_all.jl` = `REALISTIC` in `scripts/pricing_strategy_test.jl`.

**What is settled there (ten seeds, step 8, 22 October, runs .6 and .8 pending):** with no inflation left (bread 4.2–4.8 debt, 2.7 SuMSy), **a firm that prices to cover its costs outlives one that prices for a margin wherever customers can walk away, in both moneys** — the greedy bakeries are gone within a year or two in both villages, the greedy SuMSy farms within a year; where demand is unlimited (SuMSy theatres: seats sell out at any price) the margin costs nothing and the strategies coexist. Stef's frame: *margin targets against reserve targets is greed against sufficiency — a margin target never has enough, a reserve target does.* Normal profit margins on every sector (payout) push the SuMSy wealth Gini from 0.45 to about 0.75 and its poorest tenth from 16 to 5 meals: a 6 % margin with no debt service becomes 38,000 a year of dividends. SuMSy equalizes money; it does not by itself address income from ownership (the levers are the dividend and profit taxes, and ownership — the co-op cells).

**What is not settled (the struggle, by name):** the debt village's *sufficient farms* die within five months in every version so far — the trace shows them growing from 111 to 187 units in six months on bank credit, pricing below a floor that rises with their debt, wound up in month 7 with 2,400 of debt; a firm pricing at cost can never repay its founding loan. Every attempt to make a zero-margin firm viable through its price has inflated (22 Oct, versions .3, .8, .10: the full debt service, the working credit, a reserve-building markup — each a persistent markup that contracts indexed to bread turned into a spiral). The stable set is .9/.11: the floor carries the interest and the founding loan's instalments only. On it the SuMSy village is clean (bread 2.9, 512 alive, every greedy bakery and farm gone) and the debt village's sufficient farms still fail while its greedy ones live, with bread at 8 and 452 alive. **The candidate reading, to be said as a conjecture:** under debt money a firm that only covers its costs cannot carry a founding loan — the money itself demands a margin; under SuMSy it can. That fits Stef's paper (no growth imperative only if nothing accumulates) and his greed-against-sufficiency frame. Four rules from this week were built, tested and dropped on the data: market rounds within the month (they ratchet prices down until the grain market freezes), a growth cap tied to the reserve (nobody grew, prices rose), the full debt service in the floor (bread 24–71, the first SuMSy deaths from a pricing rule), the whole unsold share in the floor (a permanent buffer became a permanent markup, and indexed wages made it a spiral). The comment bug of 18 October (mid-line comments silently dropped eighteen ladder rules; every run of 18–19 October void) is part of the same story: how a result is made and unmade.

**On the base, where both villages lose people under the realistic set at some steps** (the 20 October realistic run: debt 10–50 fewer at most steps; SuMSy fine at steps 2, 5, 8 and greedy, losing people at step 11 and in the productive village through inflation that the later fixes address) — that run is on the *old* realistic set and is void for the talk; the rerun on .8 is what the talk quotes.

## 6. Runs still to do for the talk, and how

The common fiscal packages are built (22 Oct, version 2026-10-22.12): `fiscal = :taxes` (package T: income taxes, benefit 2 loaves, public jobs 10 %) and `fiscal = :parking` (package P: a 1.5 % tax on balances above a cushion of 30 instead of income taxes); from the levy step both sides carry the levy, its dividend and a 3-month reserve, surplus paid per head. A test in the suite asserts that under either package the two villages differ in no field outside the money. The partial run for the talk (docs/talk/same_fiscal_rules_instructions_2026-10-22.md §4): steps 0, 2, 8, V8, then 11 and S3, both packages, both moneys, four seeds, base labour market first, then the realistic one.

```julia
include("scripts/run_all.jl")
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0", "2", "8", "V8 "])          # priority 1, base labour market
run_all(seeds = 4, fiscal = :parking, rungs = ["2", "8", "V8 "])
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0", "2", "8", "V8 "], variant = REALISTIC_LABOUR, variant_label = "realistic")   # the realistic set
run_all(seeds = 4, fiscal = :parking, rungs = ["2", "8", "V8 "],      variant = REALISTIC_LABOUR, variant_label = "realistic")
# priority 2: the same four calls with rungs = ["11", "S3 "]
run_all(summary_only = true, fiscal = :taxes)                                   # one per folder (and :parking, and both with the realistic variant)
include("scripts/pricing_strategy_test.jl")
strategy_test(extra = REALISTIC, label = "realistic")                           # greed against sufficiency, ten seeds, step 8
```
Where a four-seed cell swings (the summary's `_p5`/`_p95` bands wide, or the worst run far from the mean), rerun it with `seeds = 1:10` and `rungs = ["<step prefix>"]`. After Sunday, ten seeds for everything by default. Two machines: `shard = "1/2"` and `"2/2"`, merge with `scripts/merge_machines.jl`. Versions: the code's `MODEL_VERSION` names the folder; .8 is current (22 Oct 10:57). Fetch only the latest run's folder from the repository (sparse checkout), never the whole repository.

## 7. Schedule (Stef's)

Thursday: text and deck on 20.4 plus whatever of the realistic set is in. Friday: Stef's corrections, final version the same day. Saturday: memorising (two hours for 15 minutes, then a night's sleep). Sunday: the talk.

## 8. How the two chats work together

- **The talk chat** writes the text and the deck, reads this file, `talk_numbers.md` (after refresh), the summary CSVs, the report v4, and the outline. It does not run the model. When it needs a number that is not here, it names the step and measure and Stef asks the simulation chat.
- **The simulation chat** keeps the model and the runs; when a result in §4–5 changes it writes the change into this file's §4/§5 and says so. Nothing older than this document is quoted in the talk without checking it against 20.4.
- **Stef's standing preferences for both chats:** precision over flattery; a critical partner; examine every claim; no "it's not X but Y", no "that's no coincidence"; estimates of time are not wanted (they have been badly off).
