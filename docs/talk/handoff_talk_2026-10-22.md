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



## 4i. THE TALK'S NUMBERS ON ONE VERSION — the talk run on 2026-10-24.9 (24 Oct, 22:00; 344 runs, four seeds; supersedes §4c–§4h for every figure)

Five folders, all `…_120months_2026-10-24.9`: `realistic_fiscal_taxes` (88), `realistic_fiscal_parking` (80), `fiscal_taxes` (88), `fiscal_parking` (80), `realistic_levybase_fiscal_taxes` (8). Summaries `results/ladder2_512_<folder>_2026-10-24.9_summary.csv`.

**The realistic set under income taxes — the talk's main table** (alive (worst seed) / public debt at month 120 / poorest tenth's wealth in meals / wealth Gini / unemployed):

| step | debt village | SuMSy village |
|---|---|---|
| 0 bare bones (no government) | **59** (52) / 0 / −0.6 / 0.72 / 4 | 479 (380) / 0 / 28.6 / 0.72 / 39 |
| 2 government | 489.5 (469) / **132k** / 1.0 / 0.74 / 110 | **499.2 (461)** / 0 / 28.9 / 0.74 / 16 — see below |
| 8 shares | 510.5 (509) / 53k / 1.1 / 0.59 / 22 | 512 / 0 / 5.4 / 0.77 / 4.5 |
| 11 VAT | 505 (503) / 21k / −2.9 / 0.67 / 16 | 512 / 0 / 9.8 / 0.76 / 2 |
| V8 productive | 511.8 (511) / 28k / −1.7 / 0.81 / 112 | 512 / 0 / 66.7 / 0.68 / 27 |
| B co-ops + reserve | 511.2 (509) / 75k / 3.0 / 0.54 / 48 | 512 / 0 / 35.8 / 0.73 / 4 |
| BG with gold (Gini with gold) | 487.2 (424) / 68k / 1.8 / 0.55 (0.58) / 54 | 512 / 0 / 20.0 / 0.72 (0.90) / 18 |
| SB2 everyone greedy | 511.8 (511) / 122k / 0.7 / 0.42 / 90 | 512 / 0 / 36.9 / 0.62 / 0 |
| B-nodiv (land tax kept as revenue) | 494.2 (487) / 79k / 2.1 / 0.69 / 99 | 512 / 0 / 19.2 / 0.74 / 3.5 |

**What the talk can say from it:**
1. **With a government the SuMSy village keeps everyone in every seed at every step but one** — step 2, where one seed of four loses 51 people (below). The debt village loses up to 25 at most steps (BG worst seed 424).
2. **The SuMSy government never borrows after its start-up loan** (peak about 7k at step 2, repaid). The debt village borrows 21–132k by year ten at every step with a government.
3. **The poorest tenth:** SuMSy 5–67 meals; the debt village −2.9 to 3.0 — at or under a meal, in debt at steps 11 and V8.
4. **Inequality on the realistic set:** SuMSy's wealth Gini is the higher one at most steps (0.62–0.77 against 0.42–0.69); only at V8 is it lower (0.68 against 0.81). **SuMSy lifts the floor; on realistic labour rules it does not flatten the distribution.** Say it that way.
5. **The bare village:** without a government, realistic labour rules leave the debt village 59 of 512; SuMSy 479 (worst seed 380).

**The step-2 deaths (traced, seed 3, the only seed that loses anyone)** *(the first reading in this paragraph — "the bakeries planned too little", "the famine is the bake-to-target rule's" — was corrected the same night by a bakery-level trace; see "Corrected" at its end)*: for three months (77–79) the village's two bakeries baked half the bread it needed (464–578 loaves against about 1,100); every loaf sold; 225–236 went hungry; 51 died in month 79. The dead had money — 116 in cash on average, about twelve meals — none was in debt, 12 owned land, 21 drew the benefit. **A famine with full pockets: the bakeries planned too little.** Under own-market planning a bakery plans on its last three months' sales plus the customers it turned away, so its plan lags a rise in demand; with only two bakeries (the contraction trap) nothing covers the gap; the village's emergency rule fired in months 74–81, too late. The likely trigger is the `.6` rule that a bakery bakes to its target rather than to its hands (Stef, 24 Oct): before it, a bakery with hands and grain baked past its plan and covered the lag — `.4` had no deaths at step 2. **For the talk:** one run in four; the rule is the same in both villages; it is a planning lag, and it is fixable (a bakery that turns customers away should bake more the next month). **Confirmed (24 Oct, 22:00, folder `realistic_handsbake_fiscal_taxes_…24.9`, 8 runs):** with bakeries baking to their hands, seed 3 keeps all 512 (its hungriest month 118 instead of 236); seeds 1, 2 and 4 are identical to the talk run, and so are all four debt-village seeds. **The famine is the bake-to-target rule's**, acting with own-market planning's lag and two bakeries. The debt village at step 2 is not touched by it: it loses 3–43 people a seed (469–509 alive) with hungry months of 258–281 in three of its four seeds, under either rule. **Corrected (24 Oct, 22:30, a month-by-month trace of the two bakeries):** baking to hands changed the path, so seed 3 never got there — but the rule is not the mechanism. In months 70–72 one bakery dominated, its target at its cap and its buffer at its 50 % maximum, leaving 300–450 loaves a month unsold and losing money; in month 73 it failed and was refounded, starting with no hands; by months 74 and 78–80 both bakeries' plans were large enough (288 units each, 2,300 loaves against a need of about 1,100), but they hired only 116–304 units of labour while 111–143 villagers were unemployed. **A hiring failure, with money in the villagers' pockets.** The trace also found a planning bug: since 22 Oct the expected-sales rule cancelled the step by which a sold-out firm plans more (bakery 9 sold out every month 70–73 and grew from 52 to 79 units). Fixed in `2026-10-24.10` (`respond_to_turned_away`, on in the base): seed 3's SuMSy village then keeps 512 — but the debt village gets worse in two of three seeds (433 and 443 alive instead of 483 and 469; bread 47 and 13 in seeds 2 and 4, an inflation the fix sets off). **So the talk stays on `.9`.** For the talk: SuMSy keeps all 512 at step 2 in three runs of four; in the fourth, two bakeries could not hire the hands their plans needed for three months, and 51 starved with money in their pockets. **Found the same night (the real cause):** the bakeries hired for the grain they had, and they had half the grain they wanted because the refounded farm 5 sat on 272–836 units it could not sell: its cost floor was doubled by the floor-per-unit-sold rule (22 Oct), which divided its floor by (1 − the share of its stock that spoiled) — its first harvest did not sell, 51–99 % spoiled, the floor went to the cap (×2, 9.5–10 against the bakeries' ceiling of 6.8–7.6 and farm 4's 4.9), so it sold nothing, more spoiled, and the floor stayed doubled. Every idle worker would have taken the bakeries' wage; there was no hiring failure. **Fixed in `.11`** (`lost_share_capped_at_buffer`, on in the base): the floor passes on at most the spoilage of the firm's planned buffer. With it the SuMSy village keeps 512 at step 2 in seeds 2, 3 and 4 (seed 1's check died for memory). **But the realistic debt village at step 2 is unstable**: its bread price runs away in two of three seeds whatever is changed (talk run 11.7 and 6.2 in seeds 2 and 4; with the cap 77.6 and 27.1; with the planning fix too 39 and 28) — an instability of its own, to trace next week. The talk stays on `.9`.

**The land tax on the realistic set (Q&A) — the base-set pattern does not carry over:**

| rung B, income taxes | land tax paid out | debt village: alive (worst) / debt / unemployed |
|---|---|---|
| realistic, the lever (levy up to its cap, paid out) | 0.82 a head | 511.2 (509) / 75k / 48 |
| realistic, levy at its base rate, paid out | 0.68 a head | 492.2 (456) / **129k** / 52 |
| realistic, levy kept as revenue (B-nodiv) | none | 494.2 (487) / 79k / 99 |
| base, the lever / kept as revenue | — | 511.8 / 76k / 66 · 508.8 / 176k / 135 |

On the base the more the debt village pays out, the less it borrows (176k → 76k). **On the realistic set the debt is about the same with or without the dividend (75k against 79k); without it 99 are unemployed instead of 48 and 17 more die.** So for a realistic talk the answer to "is the debt just the dividend?" is: no — keeping the land tax as revenue doesn't reduce the debt village's borrowing, and costs it jobs and lives.

**Full employment in the debt village (Q&A):** on the base, every cell that pays everyone an income employs everyone — DGI8 (basic income 5) 0 unemployed at 376k of debt, DDGL8 (SuMSy's arrangement in debt money) 0 at 335k, RV8 0 at 254k. On the realistic set none does (DGI8 31 unemployed, DDGL8 38, RV8 11 — the contracts' outsiders), they cost 300–440k, and two lose people (DDGL8 497, worst 452; RV8 483, worst 395). **The debt village employs everyone only by paying everyone, on the base, at 250–380k; on realistic rules not even then.** The SuMSy village: 0–27 unemployed on the realistic set (27 at V8, 39 at step 0), 0 on the base at every step with a government.

**V8 on the realistic set (valid now):** the debt village deflates 24 % a year (bread 0.20 at year ten) with 112 unemployed, its poorest tenth in debt (−1.7), 28k borrowed; the SuMSy village deflates 4 % a year, 27 unemployed, its poorest at 67 meals, no debt. On realistic rules the runaway deflation is the debt village's alone.

**Under the parking package (Q&A),** realistic: the SuMSy village 511–512 everywhere (worst seeds 509–510 at steps 2 and V8), no debt; the debt village 486–512 (B worst seed 409), borrowing 4–115k — 4k at B-nodiv with its poorest tenth 8.5 meals in debt and 56 unemployed. The meal under P: SuMSy from the land tax, the debt village from the tax on idle money and borrowing (§4e).

**The base labour market on `.9`, for "what the realistic rules change":** with a government the SuMSy village keeps 512 in every seed at every step, 0 unemployed; the debt village 509–512, borrowing 24–195k (step 2: 195k, 146 unemployed); the poorest tenth SuMSy 4–65 meals, debt 0.1–8.6. So the realistic rules cost the SuMSy village its full employment (0 → 2–39) and one bad run at step 2, cost the debt village jobs at the bare step and lives at BG and B under P, and turn V8's deflation into the debt village's alone.

**Consistency:** the realistic B, BG, SB2, 8 and 11 under income taxes are identical to `.4`; what moved between `.4` and `.9` is step 0 and step 2 in the SuMSy village (the bake-to-target rule), V8 (the restored starting prices) and SB2 under P.

**The debt village's price runs at step 2, realistic (traced 24 Oct, late night; for the Q&A — the talk stays on `.9`).** Two mechanisms. (1) A ratchet in the price rule (mine, 22 Oct): a firm raised its price 6 % on any sell-out with one customer turned away but cut it only when sales fell 10 % short; with fixed demand that pushed bread up about 3 % a month. Fixed in `.13` (`price_rise_band`: prices now rise only when demand exceeds expectation by the same 10 %); the worst seed's bread at year ten fell from 39 to 16. (2) **What remains is the money's own loop, and it may be the finding:** in seed 2, from year 5 to year 10, the public debt and the money in circulation both grew ×3.5 (56k → 198k; 60k → 206k), the benefit bill ×9.6, and bread ×6. The government borrows to pay a benefit set at two loaves at the going price; under debt money the borrowing creates money; output cannot grow, so the money goes into prices; dearer bread makes the benefit dearer and the next deficit larger. It is not the wage contracts: indexation at 0.8 leaves it unchanged (15.6 and 20.4 against 15.9 and 21.3), and without contracts one seed calms and the other collapses (188 alive). It cannot happen in the SuMSy village, whose government does not borrow. It shows in two of four seeds; seeds 1 and 4 stay stable. **For the Q&A:** "In two of four realistic runs, a government that borrowed to keep everyone fed also created the money that drove up the price of the bread it was buying." What a real economy has that the model lacks is a central bank that raises rates as prices rise — the government here borrows at a fixed 0.5 % a month whatever the inflation.

**Correction on unemployment (24 Oct, midnight) — the two zeros are NOT the same kind.** I told the reviewer on 23 Oct that every villager offers all their labour on the base ladder; that was wrong (I had read only the non-working branch of `labour_supply`). The ladder uses need-based labour supply (`offer_full_capacity = false`): a villager offers the hours that cover a meal, a top-up of the savings cushion and the standard-of-living tickets, *less* their other income — land rent, the benefit, **the guaranteed income and the dividend** — with a floor of a minimum offer and their share of the work the village needs; when the village is short of bread or hands, everyone offers everything. So the SuMSy villager, whose income covers part of the meal, offers fewer hours. **Capacity used, tenth year, seed 1 (capacity = 4 units a head, 2,048 for 512):**

| cell | debt: offered / sold, % of capacity | SuMSy: offered / sold, % of capacity |
|---|---|---|
| base step 2 | 89 / 63 | 58 / 58 |
| base step 8 | 80 / 66 | 71 / 71 |
| base B | 81 / 66 | 72 / 72 |
| base V8 | 75 / 55 | 56 / 56 |
| realistic step 2 | 85 / 65 | 75 / 61 |
| realistic B | 80 / 68 | 73 / 73 |
| realistic V8 | 73 / 62 | 64 / 61 |

Both villages use about the same share of their hands — 55–73 % — and produce what is needed (2.0–2.1 loaves a head). The difference is on the offer side: the debt villager offers 75–89 % and cannot sell a fifth to a third of it; the SuMSy villager offers less because the income pays part of the meal, and sells nearly all of it. Land: a plot yields one unit of grain a month, so the farms work about 520–570 of the 768 plots (68–74 %; V8, which needs half the grain, about 270, 35 %). **The villages run at about two-thirds of their labour capacity and are demand-limited.** For the slide and the Q&A: "59 looked for work and found none, against none" is true as a count, but the SuMSy villagers were looking for fewer hours — say "in the SuMSy village everyone who looked for work found the hours they looked for; they looked for fewer, because their income already pays part of their bread." The reviewer's caution of 23 Oct was right.
**Checked the same night — nobody stays out of the labour market in the talk's cells.** Steps 0, 2, 8, V8, B, SB2 and DGI8, base and realistic, both moneys, seed 1, months 12, 24 and 36: **no villager offers zero hours; nobody is non-working by design** (that exists only in rung Q8, 5 % not working, which is not in the talk); **the smallest offer is 2.0–2.9 of 4 units** — the floor is each villager's share of the work the village needs. The median offer is 3–4 units in the debt village and 2.3–3.0 in the SuMSy village (realistic V8: 4). So "unemployed" counts the same population in both villages — everyone — and the two counts are comparable as counts; what differs is the hours each villager looks for. The line for the Q&A: "everyone looks for work in both villages; in the debt village 59 found none, in the SuMSy village everyone found the hours they looked for — fewer hours, because the income pays part of their bread."

## 4k. THE TALK'S NUMBERS — the talk run on 2026-10-24.13 (25 Oct, morning; 344 runs, four seeds; SUPERSEDES §4i and §4j for every figure)

Folders `…_120months_2026-10-24.13`: `realistic_fiscal_taxes` (88), `realistic_fiscal_parking` (80), `fiscal_taxes` (88), `fiscal_parking` (80), `realistic_levybase_fiscal_taxes` (8). What changed since `.9`: the floor-per-unit-sold trap capped (the step-2 famine), a sold-out firm plans more, the land tax never below its base rate, prices rise only on a real excess of demand.

**Main table — realistic set, income taxes** (alive (worst seed) / public debt at month 120 / poorest tenth's wealth in meals / wealth Gini / unemployed at month 120):

| step | debt village | SuMSy village |
|---|---|---|
| 0 bare bones (no government) | **59** (52) / 0 / −1.5 / 0.73 / 6.5 | 481 (390) / 0 / 10.0 / 0.73 / 43.5 |
| 2 government | 499 (492) / **109k** / 0.9 / 0.74 / 91.5 | **512** / 0 / 24.6 / 0.73 / 19.2 |
| 8 shares | 511 (510) / 55k / −1.2 / 0.61 / 57.5 | 512 / 0 / 31.1 / **0.26** / 0.8 |
| 11 VAT | 503 (492) / 24k / −6.6 / 0.65 / 94.5 | 512 / 0 / 54.4 / 0.28 / 31.5 |
| V8 productive | 512 / 26k / −0.9 / 0.80 / 90 | 512 / 0 / 54.6 / 0.17 / 0.5 |
| B co-ops + reserve | 510.5 (507) / 49k / 2.8 / 0.45 / 44.5 | 512 / 0 / 28.5 / 0.28 / 20.0 |
| BG with gold | 510 (504) / 47k / 4.3 / 0.43 / 80 | 512 / 0 / 30.9 / 0.26 / 11.2 |
| SB2 everyone greedy | 511.8 (511) / 90k / 0.3 / 0.47 / 48.5 | 512 / 0 / 30.1 / 0.33 / 0.0 |
| B-nodiv (land tax kept as revenue) | 480 (452) / 84k / 3.4 / 0.70 / 69.8 | 512 / 0 / 20.3 / 0.50 / 6.2 |

**What the talk can say:**
1. **With a government the SuMSy village keeps all 512, in every seed, at every step.** The debt village loses up to 32 (B-nodiv; worst seed 452).
2. **The SuMSy government borrows once, 4–7k at the start, repaid by month 22, and never again.** The debt village is still borrowing at month 120 in every cell: 24k–109k.
3. **The poorest tenth: 20–55 meals in the SuMSy village with a government; −6.6 to 4.3 in the debt village** — in debt at steps 8, 11 and V8.
4. **Inequality: from step 8 the SuMSy village's wealth Gini is 0.17–0.33 against 0.43–0.80; at step 2, before the land tax, they are equal (0.73 / 0.74).** The difference is the land tax paid out to everyone, at no less than its base rate. The rule is the same in both villages; in the debt village it raises little, because the land tax follows the cost of holding money. Kept as revenue (B-nodiv) the SuMSy Gini is 0.50 against 0.70. *(The `.9` sentence "SuMSy lifts the floor but doesn't flatten the distribution" is withdrawn: on `.9` the lever had cut SuMSy's land tax to half its base rate.)*
5. **The bare village:** the debt village keeps 59 of 512, SuMSy 481.

**Work wanted and work done** (realistic, tenth year, mean of four seeds, share of capacity — `docs/talk/work_capacity_2026-10-24.13.csv`):

| step | debt: offered / accepted / looked for, not found | SuMSy: offered / accepted / looked for, not found |
|---|---|---|
| 2 government | 84 / 67 / 17 % | 65 / 61 / 4 % |
| 8 shares | 80 / 74 / 6 % | 76 / 74 / 2 % |
| 11 VAT | 80 / 69 / 11 % | 78 / 75 / 3 % |
| B co-ops | 79 / 70 / 9 % | 77 / 74 / 3 % |
| SB2 greedy | 79 / 71 / 8 % | 75 / 73 / 1 % |
| B-nodiv | 89 / 72 / 17 % | 76 / 74 / 1 % |

Both villages do about the same work (2.4–3.0 units a head a month, debt 2.0–3.0). The SuMSy villager looks for a little less and gets nearly all of it; in the debt village 6–17 % of capacity is work looked for and not found. The slide line of §4j stands. (Unemployed in this table is the tenth-year mean; the main table's is month 120.)

**V8 realistic, traced (25 Oct, seed 2) — why its prices run in opposite directions.**
*The SuMSy village inflates (bread 1.2 in year 3 → 4.5 in year 10) because of two rules added on 24 Oct, acting together:* the land-tax floor (the dividend grows to about 17.6 a head a month, twice the meal) and the rule that a firm which turned customers away plans more (at full employment, firms that want more hands bid wages up: wage 1.9 → 6.5). Seed 2: both on, bread 5.6 at year ten; the floor off, 2.3; both off, 0.81 — the gentle deflation of `.9`; only the planning response off, bread y1/3/5/10 [2.25, 1.49, 2.79, 4.72]. So this is a property of those two rules in a fully employed village — not yet a finding; for next week.
*The debt village deflates from year 1 (bread 3.0 → 0.15, about 25 % a year), and it did on `.9` too:* not the affordability rule (off on the ladder), not the planning response (unchanged without it). Its money stock halves in five years (17.9k → 8.3k) as loans are repaid, then stays flat while prices keep falling; wages follow bread down; 60–180 villagers are without work. What stops a fall in a village whose demand is fixed by needs is unclear — cheaper bread does not make anyone buy more. Unexplained; possibly a debt-money finding (money destroyed as debts are paid), not yet shown.
**Do not quote (unstable, for next week):** prices in V8 realistic — the debt village deflates 25 % a year (bread 0.17), the SuMSy village *inflates* 8 % a year (bread 4.8); the debt village's step 2 realistic inflates 6.8 % a year (bread 11.3: the borrowing loop of §4h-bis); SuMSy step 0 +2 %. Elsewhere prices fall 3–11 % a year in both villages.

**Q&A, the parking package (realistic):** SuMSy 512 everywhere, no debt, poorest 4–32 meals; the debt village 467–512 — **step 11 loses 45 on average (worst seed 365)**, a loss `.9` did not have, untraced; B-nodiv 485 (476) with 3k of debt, its poorest tenth 10 meals in debt and 112 unemployed. **The land tax (realistic, income taxes):** the debt village borrows least when its land tax is paid out at the lever's rate (49k), more at the base rate paid out (96k, 500 alive), and 84k kept as revenue with 480 alive. **Full employment in the debt village:** on the base only when everyone is paid an income (DGI8, DDGL8, RV8: 0 unemployed at 254–376k of debt); on the realistic set not even then (36–96 unemployed at 311–397k).

**The base labour market on `.13`** (for "what the realistic rules change"): the SuMSy village keeps 512 with a government at every step, 0 unemployed; the debt village 509–512, borrowing 24–195k; the base numbers barely moved from `.9`.

## 4j. Work wanted and work done — for the work/life slide (24 Oct, night; `docs/talk/work_capacity_2026-10-24.9.csv`)

Capacity is 4 units of work a head a month. "Offered" is the work the villagers looked for; "accepted" is the paid work they got (firms and public jobs); both as a share of capacity, the tenth year, mean of four seeds, the talk run (`.9`), income taxes.

**Realistic set (the talk's case):**

| step | debt: offered / accepted / looked for and not found | SuMSy: offered / accepted / looked for and not found | unemployed, debt / SuMSy |
|---|---|---|---|
| 0 bare bones | 89 / 51 / 37 % | 63 / 53 / 10 % | 7.5 / 40 |
| 2 government | 85 / 65 / 19 % | 67 / 61 / 6 % | 101 / 24 |
| 8 shares | 77 / 71 / 6 % | 73 / 72 / 1 % | 33 / 2.6 |
| 11 VAT | 79 / 68 / 11 % | 73 / 73 / 0 % | 58 / 1 |
| V8 productive | 76 / 59 / 17 % | 63 / 62 / 1 % | 110 / 5 |
| B co-ops | 78 / 69 / 9 % | 74 / 73 / 0 % | 51 / 2 |
| BG with gold | 82 / 71 / 11 % | 76 / 74 / 2 % | 54 / 7 |
| SB2 everyone greedy | 81 / 68 / 12 % | 76 / 75 / 2 % | 67 / 7 |
| B-nodiv | 89 / 71 / 18 % | 74 / 73 / 1 % | 88 / 4 |

On the base labour market the pattern is cleaner: the SuMSy village sells 100 % of what it offers at every step with a government (0 unemployed), the debt village 74–92 % offered, 55–66 % accepted, 61–171 unemployed.

**What it shows — and the framing that holds:**
1. **Both villages do about the same amount of work**, about seven hours in ten of what they could (SuMSy 61–75 %, the debt village 59–71 % with a government) — the village needs the same bread and seats either way. The SuMSy villager does *not* work less; at most steps slightly more (2.4–3.0 units a head against 2.3–2.8).
2. **What differs is whether people get the work they look for.** In the debt village 6–19 % of capacity is work people looked for and did not find, and it falls on 33–110 unemployed people; in the SuMSy village 0–6 %.
3. **The SuMSy villager looks for less work** (63–76 % against 76–89 %), because the income already pays part of the bread — and gets it. So the free time in the SuMSy village is chosen and spread over everyone; in the debt village it is unwanted and lands on a few.
4. **The slide's line:** "Both villages do the same work. In the SuMSy village people get the hours they ask for — and ask for fewer, because their income pays part of their bread. In the debt village one in five or ten hours people want goes unsold, and it falls on the unemployed." "Better work/life balance" is fair if it means *control over one's hours*; it would be wrong if it meant *fewer hours worked*.

**Caveats to keep ready:** (a) the offer is the model's rule — each villager offers the hours that cover a meal, a cushion top-up and the standard-of-living tickets, less other income, and at least their share of the village's needed work; it is an assumption about people, not a measurement; (b) public jobs are in "accepted" — about 10 % of capacity in the debt village (≈ 200 units a month) and 5–9 % in the SuMSy village; (c) the realistic SuMSy village has some unwanted idleness at step 0 (10 %, 40 unemployed, no government) and step 2 (6 %, 24 unemployed) — the contracts' outsiders; (d) four seeds, the tenth year.

## 4h. Why prices fall in the greedy village — "greed without collusion" (24 Oct, night; for the talk and the Q&A)

**What "greedy" means in the model.** A greedy firm that sells out sets its ask at what the market allows (the price last paid times the overpay multiplier); greedy buyers spend their cash above the buffer on extra loaves and tickets. That is all greed does on the price side. A greedy firm prices at cost like any other when it does not sell out — no margin in its floor unless the margin switch is on, and it is not in SB2.

**Why that does not stop prices falling** (the rules, not a measured decomposition; the greedy village's deflation has not been traced month by month):
1. Greed acts only on a sell-out. When a firm sells less than 90 % of what it expected, its ask falls by the same rule as everyone's.
2. Sellers compete and nobody colludes. Buyers go to the cheapest seller first; a greedy bakery that raised its ask after a sell-out is left with unsold bread and its ask comes down again.
3. Nobody withholds supply. Firms plan to the village's need and produce it, and bread spoils in three months, so unsold stock must be cleared.
4. The floor follows wages, and where workers compete for jobs (the debt village: 65–90 unemployed) wages drift down.

Greed's own effect, greedy village against the best village (base `.7`, income taxes): in the debt village greed slows the deflation (−1.8 % a year against −3.3 %), as the sell-out ceiling would; in the SuMSy village prices fall faster with greed (−8.0 % against −4.6 %), unexplained — SuMSy's base villages deflate at every step anyway.

**How to frame it (Stef and the code chat, 24 Oct):** "ego-centred greed" fits — every greedy actor acts on its own account, and nobody coordinates: no two bakeries agree on a price, no firm holds back supply, no group of sellers acts together. That is the same individualism as the missing mutual care (§ what the model cannot show): the village has neither cooperation among neighbours nor collusion among sellers — and collusion is cooperation too, aimed at the buyers. **Do not say the firms "want to maximise the number of sales"**: they plan to the village's need, produce that, and adjust the price after the fact; they never cut a price to win a competitor's customers. Prices fall because unsold bread forces the cut; the cheaper seller gets the customers as a consequence, not as a strategy.

**The sentence for the talk:** "In this village greed is individual. Each seller takes the highest price a good month allows, and nobody works with a competitor to keep prices up. Competition does the rest."

**For the Q&A:** the result depends on that individualism. Two bakeries in a real village could agree on a price, or bake less than the village needs; then greed would raise prices. The model has not run that. The nearest it comes is the strategy test of 22 October: firms that priced for a margin lost their customers wherever buyers could walk away. So the claim is narrow — greed without collusion does not drive up prices here.

## 4g. The 2026-10-24.7 runs (24 Oct, evening; Stef's talk_run.jl list) — what they confirm and what they overturn

On `.7`: base B, BG, SB2, V8 under both packages; realistic B, BG, SB2 under both; V8 with its old theatres (1.0) under T; rung 1 with own planning. **Not in it:** the realistic steps 0, 2, 8, 11, V8 and B-nodiv.

**Confirmed — the realistic set is stable across .4 → .7:** realistic B, BG and SB2 under T are identical to `.4` to the last decimal (the `.6` bake-to-target rule never binds there; `.7`'s price rule was already in the realistic set). Under P two cells move: B SuMSy (bread 3.72 → 3.38) and **SB2 debt village (public debt 46k → 74k, poorest −0.9 → 6.6, unemployed 36 → 8.5)**. So the §4f realistic numbers stand for B, BG and SB2 under T; under P use `.7` for SB2.

**Overturned — the greedy village does not equalise the poorest.** The talk chat's slide point ("the greedy SuMSy village's poorest end as poor as the debt village's", 5.2 against 5.1) came from base SB2 on `.4`. It does not hold on the realistic set (SuMSy 36.9 meals against 0.7 under T; 15.6 against 6.6 under P) and no longer on the base either once the expected-sales price rule is in (`.7`: SuMSy 65.1 against 4.3 under T). **Withdraw it from the slide.** The greedy village remains a stress test SuMSy passes: everyone alive, no debt, the poorest well above the debt village's.

**V8 with its prices restored (base `.7`):** both villages still deflate about 8 % a year (bread 3.0 → 1.1), so the deflation is real on the base too, if far slower than the void run's 27 %; the debt village borrows 72k under T (42k with the old theatre ratio, 54k under P) with 160–180 unemployed; the SuMSy village keeps everyone, 0 unemployed, poorest 37–39 meals. **The `.13` V8 ("holds its debt at 17k, its poorest pay for it") does not survive the newer rules**: on the current version V8 borrows. If the talk keeps a V8 slide it is either `.13` (labelled as the older rules) or the current one with the message "even the productive village borrows". The realistic V8 is still unknown (the `.4` run is void).

**Rung 1 with own planning (`.7`, T):** debt 189 (worst 173), SuMSy 481 (451); the SuMSy village inflates 3.4 % a year there (poorest 3.8 meals) — own planning helps survival at the bare step and costs SuMSy price stability.

**Base `.7` against `.8`, for the record:** less deflation in the SuMSy village (B: −8.0 → −4.6 % a year, as the expected-sales rule should do), its poorest tenth lower (B: 42 → 31 meals; under P 39 → 29), the debt village's B unchanged (75–76k). SB2 moves a lot (debt 160k → 78k under T) but mixes two changes (the `.0` greedy ask and the `.7` price rule).

**Still to run for a realistic talk on one version** (`.9` = `.7` in results): realistic V8 (both packages, 16 jobs) — needed; and, for one label throughout, realistic 0, 2, 8, 11 and B-nodiv (72 jobs; the `.4` values are probably unchanged under T, as B/BG/SB2 show, but not proven).
```julia
include("scripts/run_all.jl")
run_all(seeds = 4, fiscal = :taxes,   rungs = ["V8 "], variant = REALISTIC_LABOUR, variant_label = "realistic")
run_all(seeds = 4, fiscal = :parking, rungs = ["V8 "], variant = REALISTIC_LABOUR, variant_label = "realistic")
# optional, one version throughout:
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0 ", "2 ", "8 ", "11 ", "B-nodiv"], variant = REALISTIC_LABOUR, variant_label = "realistic")
run_all(seeds = 4, fiscal = :parking, rungs = ["2 ", "8 ", "11 ", "B-nodiv"],       variant = REALISTIC_LABOUR, variant_label = "realistic")
```
(`variant_label` without a `variant` is ignored by design, so the base calls of talk_run.jl wrote to the plain `fiscal_<pkg>` folders.)

## 4f. The realistic set on the current base (24 Oct, version 2026-10-24.4, four seeds, both packages) — and the levy-at-base-rate run

**Realistic = the base of `.4` plus contracts for four fifths of the hands, own-market planning, the :long floor and the land rules. Alive / public debt / poorest tenth (wealth) / wealth Gini:**

| rung | T, debt | T, SuMSy | P, debt | P, SuMSy |
|---|---|---|---|---|
| 0 bare bones (T only) | **59** (worst 52) / 0 / −0.6 / 0.72 | 489 (422) / 0 / 22.7 / 0.73 | — | — |
| 2 government | 489.5 (469) / 132k / 1.1 / 0.74 | 512 / 0 / 29.3 / 0.74 | 503.75 (492) / 66k / 2.2 / 0.75 | 512 / 0 / 24.1 / 0.74 |
| 8 shares | 510.5 / 53k / 1.1 / 0.59 | 512 / 0 / 5.5 / 0.77 | 499.75 (463) / 78k / 7.8 / 0.63 | 512 / 0 / 9.8 / 0.75 |
| 11 VAT | 505 / 21k / −2.9 / 0.67 | 512 / 0 / 7.7 / 0.76 | 512 / 18k / −5.7 / 0.61 | 512 / 0 / 7.4 / 0.76 |
| V8 productive | 512 / 82k / 2.5 / 0.94 | 511.75 / 0 / 142 / 0.59 | 512 / 44k / 25 / 0.52 | 511.5 / 0 / 131 / 0.52 |
| B co-ops | 511.25 / 75k / 3.0 / 0.54 | 512 / 0 / 35.8 / 0.73 | 486.25 (409) / 110k / 12.2 / 0.53 | 512 / 0 / 19.7 / 0.73 |
| BG with gold | 487.25 (424) / 68k / 1.8 / 0.55 | 512 / 0 / 20.0 / 0.72 | 512 / 115k / 17.8 / 0.61 | 512 / 0 / 13.4 / 0.72 |
| SB2 greedy | 511.75 / 122k / 0.7 / 0.42 | 512 / 0 / 36.9 / 0.62 | 512 / 46k / −0.9 / 0.52 | 512 / 0 / 15.6 / 0.63 |
| B-nodiv (levy as revenue) | 494.25 (487) / 79k / 2.1 / 0.69 | 512 / 0 / 17.4 / 0.74 | 496.75 (491) / **3.8k** / **−8.5** / 0.69 | 512 / 0 / 12.7 / 0.75 |

**What holds on the realistic set, same as the base:** with a government the SuMSy village keeps all 512 at every step in every seed (V8: 511–512) and never borrows after its start-up loan; the debt village loses 0–25 at most steps (BG worst 424, B under P worst 409) and borrows 18–132k under T (V8 82k, step 11 21k), 4–115k under P; its poorest tenth are at or under a meal, in debt at steps 11 and B-nodiv under P (−5.7, −8.5), while SuMSy's hold 5–37 meals. **What is different from the base:** (1) **the bare debt village dies** (59 of 512; the base: 167); contracts and own-market planning without a government are lethal for debt money and a help for SuMSy (489 against 452). (2) **SuMSy's wealth Gini is the higher one at most steps** (0.72–0.77 against 0.42–0.69), the reverse of the base's story — only V8 (0.52–0.59 against 0.52–0.94) and SB2 favour SuMSy; its advantage on the realistic set is the poorest tenth, not the Gini. (3) ~~**The productive village (V8) is broken on the realistic set**~~ **WITHDRAWN: the V8 rows of this table ran without V8's initial prices (the comment bug); the deflation to 0.22 is the artefact. V8 realistic must be rerun on .5.** (4) Prices deflate everywhere (SuMSy 2–16 % a year, debt 1–12 %) except the debt village at step 2 under T (+1.4 %) and SB2 SuMSy under P (+1.5 %). (5) Under P with the levy kept as revenue (B-nodiv) the debt village's books balance (3.8k) with its poorest tenth 8.5 meals in debt and 56 unemployed — the balanced budget bought from the poor, again. (6) Contracts give the SuMSy village some unemployment at most steps (2–26; 40 at step 0).

**The levy at its base rate, paid out, lever off (`levybase`, rung B under T, four seeds — the run Stef had not pushed):** debt village 511 alive / **142k** / poorest 11.7 (cash 1.7) / Gini 0.67, 74 unemployed; SuMSy 512 / 0 / 25.8 / **0.48**. Set beside B with the lever (levy at its cap: 75k, Gini 0.71) and B-nodiv (no payout: 170k): **the more the debt village pays out of its land tax, the less it borrows** — 170k with none, 142k at the base rate, 75k at twenty times — because the payout keeps people spending and employed (unemployed 128 → 74 → 59). And **SuMSy's wealth Gini at B depends on how much its levy pays out**: 0.42 with the whole surplus per head (§4c, .13), 0.48 with the base-rate levy paid out, 0.71 with the lever (which cuts the levy to half its base rate once income + dividend is a meal). The §4d sentence stands and sharpens: SuMSy's equality is what its fiscal rule pays out, and its money is what makes paying out affordable.

## 4e. Answers to the talk chat's fix handoff of 24 Oct (docs/talk/handoff_code_talk_fix_2026-10-24.md)

**§1, the land tax paid out whatever the budget:** confirmed, that is what `.8` and later do; nothing changed.

**§2, rung B with the land tax kept as revenue — built as rung `B-nodiv`** ("best village, the land tax kept as revenue"), both packages, both villages: the levy is collected and stays in the budget (no dividend, so it is scaled with the other taxes when the reserve is full), the levy lever is off, and under P the meal is off and the unemployment benefit is back on at two loaves on both sides, as asked. Under T only the dividend changes. The identity test covers it (0 differences outside the money under both packages). The call and the report format are below; the numbers go here when the run is in.

**§3, the meal under P — one correction to the talk chat's description:** the meal is not "paid as the land-tax dividend scaled to two loaves" on both sides. On the **SuMSy** side it is: the levy's scale is the lever that keeps income (5) + levy dividend at two loaves at the price last paid. On the **debt** side the levy stays at its base rate and a **basic income** brings income + dividend to two loaves, funded by the **parking tax**, whose scale is the lever (up to twenty times; what it cannot cover is borrowed). No unemployment benefit beside it on either side. The talk's spending line for P should read: "a meal for everyone — from the land tax in the SuMSy village, from the parking tax and borrowing in the debt village; no separate benefit". The debt village borrows 142–178k for it over ten years (§4d).

**§4, one version for the slides:** the `.0` change (the greedy ask on the price last paid) acts wherever greedy firms sell out — SB2 is affected, B and BG are not (no greedy firms there). The `.1`–`.3` changes are speed only and proven identical (§ regression). So B and BG on `.8` stand; **SB2 must be rerun** on the current version, and so must step 0 (the bank changes of `.8` act there). 

```julia
include("scripts/run_all.jl")
run_all(seeds = 4, fiscal = :taxes,   rungs = ["0 ", "SB2", "B-nodiv"])     # 8 + 8 + 8 jobs
run_all(seeds = 4, fiscal = :parking, rungs = ["SB2", "B-nodiv"])           # 8 + 8 jobs
run_all(summary_only = true, fiscal = :taxes); run_all(summary_only = true, fiscal = :parking)
```
**The run is in (24 Oct, 16:00, version 2026-10-24.4, four seeds). The answer to §2: keeping the land tax as revenue does NOT balance the debt village's books — under T its debt is higher without the dividend than with it.**

| rung B-nodiv (land tax kept as revenue; the benefit on) | alive (worst) | public debt m120 (peak) | climbing in the last two years? | tax scale | unemployed | poorest tenth: cash / wealth | Gini cash / wealth / with gold |
|---|---|---|---|---|---|---|---|
| T, debt | 509.5 (506) | **170k** (170k) | yes: 138k → 158k → 175k (months 96/108/120, seed 1; all four seeds alike) | 1.0 | 128 | 1.1 / 9.1 | 0.30 / 0.61 / 0.61 |
| T, SuMSy | 512 | 0 (peak 1.6k, the start-up loan) | no | 0.05 | 0 | 2.6 / 18.9 | 0.63 / 0.74 / 0.74 |
| P, debt | 505.75 (501) | 21k (22k) | no: flat at 16–25k | 1.0 | 96 | 0.8 / 2.3 | 0.39 / 0.71 / 0.71 |
| P, SuMSy | 512 | 0 (peak 1.7k) | no | 0.05 | 0 | 2.8 / 21.4 | 0.68 / 0.74 / 0.74 |

For comparison, rung B *with* the dividend (§4d): T debt 75k, 512 alive, poorest 4.1; P debt 154k with the meal. **Reading:** under T the dividend was reducing the debt, not causing it — without it the villagers have less to spend, unemployment rises from about 20 to 128, the benefit bill rises, and the debt climbs faster (to 170k, still rising). The claim "the debt village borrows without end" stands with the land tax kept as revenue, and stands stronger. Under P the books nearly balance without the dividend (21k, flat), at the price of 96 unemployed, a poorest tenth at two meals of wealth and under a meal of cash, and six dead — the balanced budget of the productive village again, by another route. The SuMSy village under either package: everyone alive, taxes cut to 5 %, the poorest tenth at 19–21 meals.

**Step 0 on `.4`** (T; no government, so the package is empty): debt 167 (worst 155), SuMSy 451.5 (448) — the bank changes of `.8` lift the bare debt village from 141 (§4c) to 167; SuMSy unchanged. **SB2 on `.4`** (greedy ask fixed): T — debt 511.75 / 166k / poorest 5.1, SuMSy 512 / 0 / poorest 5.2 (bread 5.7; the greedy SuMSy poorest are as poor as the debt village's under T); P — debt 512 / 175k / 48.2 (the meal), SuMSy 512 / 0 / 26.2. One slide, one version: these three cells on `.4`; B and BG on `.8` (unchanged by `.0`–`.4`, see §4).

## 4d. The 2026-10-23.8 runs (24 Oct, four seeds): the new fiscal rule, the meal under P, the bank and theatre changes — READ BEFORE MIXING WITH §4c

Six folders on `.8`: B, BG, SB2 and V8 under both packages (base labour market), B/BG/SB2 under both with the realistic set, rung 1 with own-market planning, and V8 with its old theatre ratio (`V8_full`). **These are on different rules from §4c** (the levy paid out per head and never scaled as a tax, taxes cut to 5 % once the 3-month reserve is full, the meal under P funded by the parking tax with no unemployment benefit beside it, the banks' rate on the going wage with staff scaling with loans, theatres at two customers per unit) **and they move the SuMSy inequality numbers a lot**. Do not put a `.8` number beside a `.13` number on one slide.

**Base labour market — alive / public debt / poorest tenth / wealth Gini:**

| rung | T, debt | T, SuMSy | P, debt | P, SuMSy |
|---|---|---|---|---|
| B co-ops + reserve | 512 / 75k / 4.1 / 0.49 | 512 / 0 / 42.0 / **0.71** | 512 / 154k / 32.7 / 0.54 | 512 / 0 / 38.9 / 0.73 |
| BG with gold (everything) | 511 / 73k / 3.8 / 0.53 | 512 / 0 / 32.2 / 0.90 | 512 / 142k / 22.3 / 0.78 | 512 / 0 / 35.0 / 0.90 |
| SB2 everyone greedy | 512 / 160k / 4.0 / 0.44 | 512 / 0 / 5.7 / 0.27 | 512 / 178k / 37.9 / 0.37 | 512 / 0 / 19.7 / 0.44 |
| V8 productive (theatres at 2.0) | 512 / **87k** / 0.5 / 0.80 | 512 / 0 / 180 / 0.64 | 512 / 53k / 37.2 / 0.36 | 512 / 0 / 125 / 0.66 |
| V8 with its old theatres (1.0), T only | 511 / 52k / 0.9 / 0.70 | 512 / 0 / 151 / 0.70 | — | — |

What changed against §4c and why it matters for the slides:
- **SuMSy's wealth Gini at B went from 0.42 (§4c) to 0.71.** Under the old rule the whole surplus was paid per head every month; under the new one only the levy is paid out and the surplus cuts taxes to 5 % — the poorest tenth are richer (42 meals against 27) but the middle gets less, and the Gini rises to the debt village's level (0.49–0.54 debt, 0.71–0.73 SuMSy). **The inequality slide's SuMSy advantage is a property of the per-head surplus, not of the money alone.** Say it that way or keep the slide on `.13` throughout.
- **V8 no longer holds its debt** (87k under T; 52k with its old theatres): with the levy paid out instead of into the budget the balanced-budget village borrows. The "cost of keeping the debt under wraps" slide is a `.13` story; on `.8` the story is that V8's surplus went to the villagers.
- **Under P the debt village pays the meal and borrows for it**: 142–178k in ten years, its poorest tenth at 22–38 meals; SuMSy pays it from the levy with taxes at 5 % and no debt. That is the fair comparison Stef asked for and the cleanest `.8` result: the same meal for everyone, one money borrowing 150k for it, the other not.
- SuMSy's cash Gini is still the higher one (0.38–0.49 against 0.12–0.19).

**Realistic set (contracts 0.8, own-market planning, the :long floor, land rules)** *(the SB2 SuMSy inflation and public debt quoted in this paragraph were largely an artefact of the greedy ask — see the correction at the end of this section)*: T — B debt 511 / 75k / 3.0; BG debt 487 (worst 424); SuMSy 512 everywhere, B poorest 35.8; **SB2 SuMSy inflates 6 % a year (bread 19.6) and its government borrows 73k**. P — B debt 486 (worst 409) / 110k; SuMSy 512; **SB2 SuMSy bread 16.5, +10.6 % a year, 41k of public debt**. The realistic set with everyone greedy is not stable and the SuMSy village borrows there for the first time; the realistic numbers stay "work in progress".

**Rung 1 with own-market planning** (no government): debt 187 (base: about 140), SuMSy 475 (base 452); SuMSy inflates 3 % a year there and its poorest hold 3.3 meals. Own planning helps survival a little at the bare steps.

**Correction (24 Oct, version 2026-10-24.0, four seeds; the greedy village is no longer a way to break SuMSy):** the inflation in the greedy SuMSy village (SB2, realistic set) came mostly from the greedy firms' ask, which was set from the *expected* price — and the expected price comes from the asks, so with wages indexed to bread every sell-out ratcheted from a higher base. With the ask set from the price last paid instead:

| SB2 greedy SuMSy, realistic, mean of 4 seeds | bread y3 / y5 / y10 | wage y10 | worst seed's bread y10 | unemployed y10 | SuMSy public debt | poorest tenth |
|---|---|---|---|---|---|---|
| T, old ask (.8) | 4.7 / 6.9 / **21.0** | 16.9 | 71 | 35 | 73k | 29.5 |
| T, **new ask (.0)** | 4.4 / 4.3 / **3.9** | 3.1 | 4.3 | 0 | **0** | 36.9 |
| P, old ask (.8) | 5.6 / 6.7 / **18.0** | 14.2 | 40 | 36 | 41k | 8.5 |
| P, **new ask (.0)** | 4.4 / 4.9 / **6.2** | 4.8 | 7.4 | 0 | **0** | 15.6 |

All 512 alive in every seed. Under T the village now deflates like the base (bread −22 % over ten years); under P there is a residual drift of about 5 % a year from year 3 on (bread 4.4 → 6.2, wage 3.4 → 4.8), far from the spiral and unexplained: it coincides with the levy lever raising the levy as the price rises (the meal target, two loaves, rises with the price; levy scale 0.06 → 0.31 over years 5–10), which would make the guaranteed meal a price-indexed transfer. Not yet tested; the test is `strategy`-style: SB2 realistic under P with `levy_dividend_target_in_breads = 0`. **For the talk: the greedy inflation is not evidence that SuMSy breaks.** What strains the SuMSy village remains the five items of the earlier list (no government, fixed income while prices move, money pooling where the fee cannot reach, indexed contracts' unemployment, and the surplus rule). Also unsettled: the realistic SB2 *debt* village moved a lot with the same single change (T: public debt 49k → 122k, unemployed 17.5 → 90, bread 2.2 → 6.4; P: debt 87k → 46k) — four seeds, treat its realistic numbers as unsettled. In all variants the village runs on **two bakeries from year 2–3** (the contraction trap, open since 21 October).

## 4c. THE TALK'S NUMBERS — the full ladder on the same fiscal rules, with the two-loaf floor (23 Oct, four seeds, version 2026-10-22.13; the folders `…_fiscal_taxes_…22.13` and `…_fiscal_parking_…22.13`, 876 runs each)

The base now has a collection floor of one meal (two loaves) in both villages. **These supersede §4b for every side-by-side figure.** Alive of 512 / public debt after ten years / poorest tenth (meals) / wealth Gini; the worst run in brackets.

**Package T (income taxes 15/15/30/10 %, benefit 2 loaves, public jobs 10 %):**

| step | debt village | SuMSy village |
|---|---|---|
| 0 bare bones (no government, any package) | 141 (124) / 0 / 8.3 / 0.53 | 452 (448) / 0 / 9.2 / 0.72 |
| 2 government | 511 (510) / 196k / 1.1 / 0.74 | 512 / 0 / 16.0 / 0.74 |
| 5 bonds | 509 (505) / 169k / 6.0 / 0.72 | 512 / 0 / 3.8 / 0.75 |
| 8 shares (+ levy) | 509 (508) / 130k / 0.8 / 0.76 | 512 / 0 / 18.3 / 0.55 |
| 11 VAT | 502 (492) / 30k / −5.8 / 0.83 | 512 / 0 / 28.0 / 0.44 |
| B co-ops + reserve | 509 (504) / 132k / 4.1 / 0.68 | 512 / 0 / 26.8 / 0.42 |
| V8 productive (free prices) | 510 (507) / 17k / −4.0 / 0.70 | 512 / 0 / 70.6 / 0.21 |
| N8 market entry | 510 (509) / 118k / 0.4 / 0.71 | 512 / 0 / 48.1 / 0.26 |
| S3 everyone greedy | 499 (493) / 186k / 1.4 / 0.69 | 512 / 0 / 23.6 / 0.42 |
| DGI8 basic income in debt money | 512 / **335k** / 20.5 / 0.69 | — |
| A8 austerity from year 5 | **397** (392) / 121k / 0.3 / 0.73 | — |
| D8-60 debt ceiling 60 % | **322** (308) / 79k / 0.1 / 0.73 | — |
| EU8 basic income under the ceiling | 476 (469) / 148k / −0.3 / 0.81 | — |
| PL8 public land with rents | 472 (459) / 25k / −6.2 / — | 512 / 0 / 3.7 / 0.27 |

**Package P (a 1.5 % tax on balances above a cushion of 30 instead of income taxes):**

| step | debt village | SuMSy village |
|---|---|---|
| 2 | 510 (510) / 98k / 1.2 / 0.75 | 512 / 0 / 18.3 / 0.74 |
| 5 | 504 (492) / 116k / 1.2 / 0.76 | 512 / 0 / 3.9 / 0.75 |
| 8 | 508 (505) / 27k / 0.6 / 0.73 | 512 / 0 / 16.5 / 0.53 |
| 11 | 496 (495) / 0.7k / −2.8 / 0.78 | 512 / 0 / 18.5 / 0.42 |
| B | 507 (504) / 23k / 0.1 / 0.73 | 512 / 0 / 27.4 / 0.31 |
| V8 | 494 (486) / 20k / −0.8 / 0.65 | 512 / 0 / 30.7 / 0.26 |
| N8 | 508 (506) / 19k / 0.4 / 0.74 | 512 / 0 / 31.3 / 0.13 |
| S3 | 509 (505) / 96k / 1.9 / 0.75 | 512 / 0 / 28.1 / 0.19 |
| DGI8 / A8 / D8-60 / EU8 | 512 / 397k / 33 · 431 / 111k / −0.3 · 357 / 90k / −0.5 · 487 / 190k / 1.0 | — |

**What the talk may now say, on identical rules:**
1. **With the floor at a meal and a government, both villages feed almost everyone**: the debt village 494–511, the SuMSy village 512 in every seed at every step. What kills in the debt village are its own fiscal rules — austerity (397), a debt ceiling (322), the ceiling even with a basic income (476) — and public land with rents (472). The deaths of §4b (390 at step 11) were the collection rule's: a floor below subsistence, now gone from the base.
2. **The debt village borrows every year; the SuMSy government never does after its start-up loan.** Under T 118–196k by year ten at every step but 11 (30k) and V8 (17k); under P far less, because the levy charges the cost of holding money (§4b). A basic income in debt money keeps everyone (DGI8) at 335–397k. SuMSy: 0 at every step, everyone alive.
3. **The poorest tenth:** under a meal, or in debt, in the debt village at every step (0.1–6 meals; negative at 11, V8, PL8); 16–71 meals in the SuMSy village — **except step 5 (bonds), where the SuMSy poorest hold 3.8–3.9, less than the debt village's 6.0 under T**; say "at every step but one" or leave step 5 out.
4. **Inequality:** equal at steps 2 and 5 (0.72–0.76 both); from step 8 the SuMSy village's wealth Gini is 0.53–0.55 against 0.73–0.76, and where the village is productive, has co-ops or market entry, 0.13–0.31 against 0.65–0.74. The SuMSy **cash** Gini is the higher one (0.45–0.60 against 0.32–0.33 at step 8); show both. Gold makes both about 0.9.
5. **Prices fall in both villages** (the debt village 1–12 % a year, SuMSy 4–16 %); the fixed-income caveat of §4 stands.

**Why SuMSy's cash Gini is the higher one at step 8 (0.45 against 0.32), and why its poorest tenth hold only 3.8 meals at step 5 — both are about where the money sits (23 Oct, from the `.13` part files, package T):**

Where the SuMSy village's 130,000 is at month 120:

| holder | step 2 | step 5 | step 8 |
|---|---|---|---|
| villagers | 91,000 | **25,800** | 92,400 |
| the theatres | 0 (none yet) | **54,000** (two theatres) | 23,000 (four) |
| the government | 22,700 | **33,400** | 700 |
| banks, farms, bakeries | 16,600 | 16,800 | 13,200 |

- **Step 8, the cash Gini.** SuMSy villagers hold 92,400 of their village's money, the richest tenth 103 meals each and the poorest 3.4; the debt village's villagers hold 15,800 of 52,000, the richest tenth 10 meals each and the poorest 1.2. From step 5 on the debt village's savers keep their wealth in government bonds and later in shares, so cash is thin for everyone there and its Gini is the Gini of a scarce thing. SuMSy has no bonds and a 2 % fee, so its rich keep a good part of their wealth as money. The cash Gini says "SuMSy's rich hold their wealth in a form the debt village's rich don't"; the wealth Gini, which counts the bonds and shares, is the fair comparison. Show both, with this sentence ready.
- **Step 5, the poorest tenth.** Steps 4–7 have firms with no owners (`ownership = :none`): a theatre's profit has nobody to go to, so its cash climbs until the 2 % fee on it equals the inflow — about 27,000 each for two theatres selling every seat. And under the packages the government pays its surplus out per head only from the levy step (D6), so before step 8 it accumulates: 22,700 at step 2, 33,400 at step 5. The poorest at step 5 therefore live on the income of 5 alone, about four meals; at step 8 the share market returns the theatres' money and the surplus is paid out, and they hold 18. The debt village's money at step 5 is also mostly out of its villagers' hands (banks 27,700, bakeries 14,300), but they hold bonds, which count in their wealth — hence 6.0.
- **For the talk:** step 5 is a point about design rather than an exception to hide — an income alone does not keep the poorest above a meal when money can pool, and here it pools in ownerless firms and an unpaid surplus; the dividend and the shares are what fix it. **For the ladder:** the government's hoard before step 8 is a package choice (surplus per head from the levy step), not a property of either money; paying it from step 2 is one line in `fiscal_package`. The ownerless firms' hoarding is real behaviour and stays — co-ops (B) and shareholders (8) are the village's answers to it.

**The loan rate, and what the public debt is made of — settled by the cap test (23 Oct, four seeds, steps 2 and 8, both packages):** capping the banks' rate at 0.4 % a month changes the debt village's public debt by nothing: step 2 under T 198k against 196k, step 8 163k against 130k (higher, since cheaper credit lets the government and the firms borrow more); under P 99k and 27k against 98k and 27k. Survival, the poorest tenth and the Gini are unchanged too. The reason: **the government does not borrow at the banks' rate.** It borrows at a policy rate of 0.5 % a month (`government_rate`, about 6 % a year), and through bonds at 0.25–0.4 %. The banks' 1.5 % a month is what firms and households pay, and it IS the ladder's cap: the rate rule's cost term is the bank's labour bid, which tracks the bank's cash (thousands a month) rather than its one employee's wage (about 4), so the rule asks for 15–25 % a month and the cap holds it at 1.5 % (traced 23 Oct, step 8, month 36). The fix (the going wage as the cost) gives 0.2–0.3 % a month and is Monday's first model change — docs/future_work/banks_on_real_world_economics_2026-10-23.md. My earlier reading — "a third to a half of the debt is interest at 18 %" — assumed the government paid the banks' rate; it does not. **So the public debt is the primary deficit:** the benefit and the public wages the taxes do not cover (at step 2: 236k spent, about 106k collected, over ten years), plus about 6 % a year on what that leaves. The "living on debt" slide stands on the deficit, which is the stronger ground, and the Belgian parallel is about the rate the deficit is financed at, which here is a policy rate near Belgium's. If asked about the 18 %: that is what the village's firms and households pay their banks, and it is high because the rate rule divides one employee's wage and the deposit interest by a small loan book — docs/future_work/banks_on_real_world_economics_2026-10-23.md.

**The SuMSy start-up loan (the talk chat):** the roadmap's step 10 says the SuMSy village starts below its own equilibrium money stock, so the one loan repaid in two years is partly a starting condition; "while the money builds up" is the honest phrase, and if asked: a village starting at its own steady state would most likely not need it.

**Banks on the real-world net margin (23 Oct, step B, four seeds, `bankmargin` folders; Banks (Regional) 29.67 % after tax on the loan rate, and on the SuMSy banks' spread if run with `BANK_MARGIN_BOTH`):** no measurable effect within ten years — **and the test was empty**: with the default settings the banks already keep 83–89 % of their interest revenue in the debt village (the loan rate sits at its 1.5 %-a-month cap; a bank has one employee) and about 97 % of their account fees in the SuMSy village, so a 29.67 % target was below what they already made. Future work: docs/future_work/banks_on_real_world_economics_2026-10-23.md (costs that scale with customers and loans, calibrated to the margin data). Debt village: 510 alive against 509 (T), 505 against 507 (P); public debt 134k against 132k (T), 32k against 23k (P); wealth Gini 0.68–0.69 either way; poorest tenth 4.8 against 4.1 (T), 1.8 against 0.1 (P). SuMSy: 512, 0, 0.31–0.42 either way. The banks' interest revenue in this village is small (the loan rate is about 1.5 % a month — 18 % a year — in every run, from the rate rule with a small loan book), so a 30 % margin retains about 2,000 a year — the `p` of the 2021 paper is there but too small, at this scale and horizon, to move anything. Not a slide; a Q&A line at most: "real bank margins change nothing in ten years here; the paper's instability is a long-run ratio effect".

Paired tests: to be rerun on these folders (four seeds: counts, not significance). The realistic set on this base: running (`:taxes` first); the `.12` realistic folders are one-loaf-floor data.

## 4b. The same fiscal rules on both sides — the numbers of 22 Oct (four seeds, version 2026-10-22.12, floor at ONE loaf) — superseded by §4c for every side-by-side figure; kept for the record and the death traces

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

**What holds on identical rules, and may be said:** (1) with a government the SuMSy village keeps all 512 in every seed at every step, the debt village loses 2 to 122 people; (2) the SuMSy government borrows once at the start (step 2: 7,230 under T, repaid by month 22; 8,200 under P, repaid by month 36; step 8: 0.9–2.1k, repaid by months 20–22) and never again; the debt village's borrows at every step under T (18k–198k; at step 11 it levels off at 20–30k, flat or falling in three seeds of four) and far less under P — **and what closes its budget under P is the land levy, not the tax on balances**: at step 8 the parking tax brings it 400–1,400 a year, the levy 5,500–9,700 (3,400–4,000 under T) against a benefit bill of 3,500–8,300. The levy rule charges the cost of holding money, so a parking tax on debt money raises the levy rate. Said plainly: raising the cost of holding money closes the debt village's budget, through the levy. The SuMSy village's levy brings 23–40k a year in both packages. The people still die under either package; (3) the poorest tenth: 16–77 meals in the SuMSy village against −5 to 1.8 in the debt one; (4) the wealth Gini: equal at step 2 (0.74 both), lower in the SuMSy village from step 8 (0.52–0.53 against 0.70–0.78; 0.22–0.25 against 0.60–0.66 in the productive village) — so the 20.4 gap was partly the levy's doing, and on the same rules it is smaller but it is there; (5) the SuMSy village's **cash** Gini is the higher one at step 8 (0.45–0.62 against 0.33–0.35) — show both Ginis. Prices deflate in both villages at every step (SuMSy faster); fixed income and cushion caveat as in §4.

**The realistic set on the same rules** (contracts 0.8, own-market planning, the :long floor, …): the same pattern, the debt village losing more — package T: debt 473 (409) at step 2, 435 (430) at step 8, 410 (400) at step 11, 454 (442) productive, 474 (451) greedy; SuMSy 512 at every step with a government (511, worst 508, at step 8); package P: debt 499 / 450 / 439 / 481 / 484; SuMSy 512. Step 0 under the realistic set: debt 16 (12), SuMSy 473 (358) — the bare-bones debt village cannot survive contracts and own-market planning without a government. Prices: SuMSy near the base's at steps 8 and 11, the debt village deflating 9–17 % a year under P. The realistic numbers are four seeds on a set frozen this afternoon; say so.

**Step 11, the separating test (22 Oct, 21:30, four seeds, both packages):** the collection floor at two loaves takes the debt village from 390 to **502 (worst 492)** under T and from 425 to **496 (worst 495)** under P; the pro-rata benefit alone to 427 and 444; both together to 503 and 497 — the same as the floor alone. So at step 11 as at step 8 **the deaths are the collection rule's**, and the benefit cliff is a minor contributor (about a fifth of the floor's effect), not the cause. The two step-11 traces (seeds 1 and 2: 124 and 109 dead) say why: 120 of 124 were in debt (59 on average), half had worked about half time, and **the benefit, where paid, covered the meal (5.65 against 5.31)** — they died with a sufficient benefit because collection took it. Bread was not short. The talk's line holds at both steps: today's money puts poor people in interest-bearing debt, and collecting that debt takes their bread. Keep the DGI8 counterpoint: no cliff in debt money is possible too (everyone alive) at 340,000 of debt; what sets SuMSy apart is no debt trap *and* no public debt.

**Why the debt village's debt levels off at step 11 — corrected:** it is step 11's fiscal rules (VAT, the reserve rule), not the deaths. With the floor at two loaves and 502 alive the public debt is 30k under T and 0.7k under P, the same as with 390 alive (25k / 0.1k). The benefit bill does fall as claimants die (the earlier reading below), but the debt's level does not depend on it. Debt per starting villager remains the honest measure.

**The earlier reading (the claimants die), kept for the record:** Under T the yearly benefit bill falls from 10,100 (year 2) to 2,800 (year 10) while 122 people die and the unemployed fall from 94 to 64; under P from 9,900 to 4,100 with 88 dead. Public debt **per starting villager**, which does not shrink with the village, is the honest measure: 48 at step 11 against 238 at step 8 under T (per survivor 63 against 255); under P 35 at step 8, 0 at step 11 (the levy closes the rest). So at step 11 the budget improves *because* of the hunger: the budget and the hunger are not two separate problems there. Say it that way.

**Who dies in the debt village, and of what (step 8, package T, seed 1 — a single run, say so):** 46 died, all in years 2–10, mostly years 5–6. The month before dying, 43 of the 46 were in debt (48.6 on average, against a meal costing about 8 and a benefit of 4.1), 25 had worked a little (1.1 units, a quarter of full time), 24 received the benefit, their cash averaged 4, none owned land, and each had been hungry for two months. Bread was not short that month (none left unsold on average, meaning every loaf sold, and the village baked what it needed): they could not pay. So the mechanism is household debt: people with too little work borrow for bread (the bread credit), the collection on that debt then takes what the benefit and the odd job bring, and once a villager is a loaf short two months running they die. The benefit is two loaves, but the debt service comes first. In the SuMSy village the same people have the income of 5, pay no interest on what they borrowed from each other, and never reach that point. Two corrections to that reading (the talk chat, 22 Oct evening). **The benefit figure was my averaging error:** 4.1 is the mean over all 46 dead, half of whom received nothing; those who received it got a full meal's worth (the benefit is two loaves at the going price). **And the benefit stops at the first hour of work:** it is paid only to a villager who offered labour and sold none (`unemployed(w)`; the pro-rata benefit for the underemployed, `partial_unemployment_fee`, is off on the ladder). Of the 46 dead, 25 had worked about a quarter of full time the month before, earning roughly half a meal and no benefit. So three things combine: (1) interest on household debt — the money's (SuMSy runs the same credit at a negative rate); (2) debt collection that may take a villager's cash down to one loaf (`collection_floor_in_breads` = 1.0) while a meal is two — the same rule in both villages, biting only where people carry debt; (3) the SuMSy villager's other income — 5 a month plus a land dividend of about 4–6.5 at step 8 — which keeps them out of debt, against a benefit that stops at the first hour of work. Only (1) is clearly the money; (3) is the fiscal package as much as the money. **The separating test** (the talk chat's): step 8, both packages, both moneys, four seeds, with the collection floor at two loaves — `run_all(seeds = 4, fiscal = :taxes, rungs = ["8"], variant = FLOOR_TWO_LOAVES, variant_label = "floor2")` and the same with `:parking`, 32 jobs. If the debt village then keeps everyone, the talk says: today's money puts poor people in interest-bearing debt and collecting it takes their bread. If people still die, the claim stands. **The separating test is in (22 Oct, 20:00, four seeds, step 8):** with the collection floor at two loaves the debt village keeps **508.75 (worst 508) under T and 507.75 (worst 505) under P**, against 477 and 480 with the floor at one loaf; its public debt is unchanged (130k under T, 27k under P), its poorest tenth still hold under a meal (0.8 / 0.6) and its wealth Gini is unchanged (0.76 / 0.73). The SuMSy village is 512 either way. **So the deaths at step 8 are the collection rule's doing**: debt collection that may take a villager down to one loaf when a meal is two. The talk's line, as the talk chat wrote it: today's money puts poor people in interest-bearing debt, and collecting that debt takes their bread. The rule is the same in both villages; it bites only where people carry debt, and only one money puts them there. The three or four who still die (508 of 512) are the residue for the Q&A. Everything else the money does — the public debt, the poorest tenth under a meal, the wealth Gini — is untouched by the floor, so those claims stand as they were.

**Steady state, checked (the talk helper's point):** consumption is flat. Bread sold per head per month is 2.10 in the SuMSy village from year 2 to year 10 at steps 8 and 11 under both packages (the two-loaf meal plus the tenth the bakers stock), and 2.0–2.07 in the debt village; tickets 1.25 per head per month in the SuMSy village from year 2 on — every seat (seats are 1.25 × the village per show, demand up to three each, so seats are rationed: "demand above capacity", not "unlimited") — against 0.1 rising to 0.33 in the debt village (0.04–0.28 at step 11 under P). Deflation does not lift SuMSy's consumption because it sits at the ceiling from year 2; the debt village's tickets rise from a low base and never reach it. Nothing physical grows; what can grow is what people own and owe — say so once, it sets up §6.

**Paired tests per folder (22 Oct, four seeds, `results/ladder2_512_<folder>_paired_tests.csv`):** in all four folders, at every step with a government, the SuMSy village keeps more alive in 4 pairs of 4, owes nothing against the debt village's debt in 4 of 4 (3 of 4 at step 11 under P, where the debt village's debt is near zero), and its poorest tenth hold more in 4 of 4 (3 of 4 at step 0 under T, where there is no government). Four pairs cannot be significant (the exact two-sided p is 0.125 at best), so the claim is "in every one of four runs", never "significant"; ten seeds after Sunday.

Not in these folders: the levy rates charged (§3.5) and the deposit interest paid (§3.12); the talk chat should ask for them by name.

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
