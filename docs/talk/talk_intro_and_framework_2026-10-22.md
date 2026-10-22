# A simulated economy: what it takes to survive

*Introduction (rewritten) and framework for the rest of the talk. Draft of 22 October 2026, for Sunday 25 October.*

*Target length: 11 minutes, with one minute of slack before the 12-minute limit. At about 140 spoken words a minute, the whole talk is roughly 1,500 words.*

*Numbers updated 22 October evening from the common-package runs (version 2026-10-22.12, four seeds, base labour market unless marked). They are **provisional until the `:own` regression check passes**: the new runs come from the same code. Remaining estimates are in [square brackets]. "T" = income taxes on both villages; "P" = a tax on balances on both villages.*

---

## 1. Introduction (0:00 – 2:00, about 280 words)

> Can the money we use today carry an economy that no longer grows, with a public debt that stays manageable and nobody going hungry?
>
> I had a career in IT before I came to economics, and I love complex simulation games. So I built one.
>
> Two villages. Each has 512 people, two banks, four farms and four bakeries. A quarter of the villagers own the land. Everyone needs two loaves a month, and nobody wants more than a few. There are enough hands and enough land to feed everyone twice over. And nothing grows: the same people, the same land and the same appetite, year after year. Economists call that a steady state. What can grow is what people own, and what they owe.
>
> The first village uses the money we have today. Banks create it when they lend, and it disappears again when the loan is repaid. The banks earn their living from the interest.
>
> The second village uses the Sustainable Money System I'm researching for my PhD. Every month, everyone receives the same amount of new money. At the end of the month a small parking fee is taken from whatever is left above a cushion, and that fee disappears. The banks lend out what savers bring in, and they earn on the difference.
>
> Everything else is the same in both villages: how people behave, how the markets work, and the taxes. I even tried two different tax systems, each on both villages.
>
> A village passes if it does three things at once. It feeds everyone. It lets prices find their own level. And its government doesn't need a debt that grows forever, because no government accepts that, and in an economy that doesn't grow, a growing debt is a growing burden.
>
> This is work in progress. Some results are solid, some are still moving. I'll show you both.

**Notes on the introduction**

- **The tax sentence depends on the common-package runs.** If those runs are not in by Friday, replace it with: *"Each village has the tax system that fits its money. I swapped the two systems to check, and the outcome followed the money."* That fallback rests on X1 and X2, which are not clean cross-checks (see the instructions file, §1). If you use it, say "roughly".
- **Optional sentence**, if the second village's description can take a fourth line: *"Because the fee grows with what you hold, the money can never pile up without limit."*
- **The steady state is checked:** consumption is flat from year 2 to year 10 in both villages (bread 2.0–2.1 loaves a head a month). The last sentence of that paragraph sets up section 6.
- **"The same appetite"** stands for the model's caps on what each person consumes: two loaves needed, a third now and then, at most a few in stock (bread spoils in three months), and one to three theatre tickets a month once theatres exist. The greedy are capped too, only higher (ten). The leisure the village can supply is capped as well: one show a month with seats for the village plus a quarter.
- **"Nobody going hungry" replaces "everyone can have a good life".** The three conditions measure survival, so the question now asks what the talk answers.
- **"Everything else is the same"** is true under D1, which counts the bank fees, the absence of deposit interest, and how the government borrows as part of the money. The sentence about the banks earning "on the difference" carries that boundary for the audience.
- **Slides:**
  - Slide 1: the title and the question.
  - Slide 2: two village icons. Terracotta for today's money; teal for SuMSy. Under each, one line of icons: bank, farm, bakery, land.
  - Slide 3: three ticks with three words: *fed · free prices · no endless debt*.

---

## 2. Bare bones: money alone (2:00 – 3:00, about 140 words)

**What happens:** no government, only the market. Both villages lose people.

- Debt village: **149 of 512** alive after ten years.
- SuMSy: **453**.

**Why SuMSy loses people too:** when bread is dear, the monthly income of 5 buys less than a meal, and nobody else steps in.

**Message:** money matters a great deal, but neither money keeps everyone alive on its own. A village needs rules.

**Bridge:** "So let's give both villages a government."

**Slide:** two survival curves over ten years, with one number at the end of each line.

**Source:** step 0, `ladder2_512_fiscal_taxes`. There is no government, so the package makes no difference. The 20.4 numbers (153 / 455) agree.

**Optional line, if section 7 has room for it:** with realistic contracts and firms planning on their own sales, the debt village without a government nearly dies out (16 alive). SuMSy keeps 473, but its worst seed keeps only 358. Four seeds, so a wide spread; say "in one test".

---

## 3. Add a government (3:00 – 4:30, about 210 words)

**What the government does:** pays a benefit of two loaves to those without work, employs a tenth of the village, and collects taxes. Both villages get exactly the same rules.

**Outcome (step 2, income taxes):**

- Both villages feed nearly everyone: **510 and 512**.
- The debt village's government borrows every month. Its debt reaches **198,000 after ten years** and is still climbing.
- The SuMSy government borrows once, at the start, while the money builds up: **7,230, repaid by month 22**. Then never again.

**With a tax on balances instead (P):** the debt village borrows half as much, **99,000**, and still climbing. The SuMSy village borrows **8,200, repaid by month 36**.

*The coder's month numbers (22, 36) differ from the summaries' means (24.0, 38.0). Ask which measure each is; quote one consistently.*

**This is the cleanest comparison in the talk.** Step 2 has no land levy, so nothing but the money and one identical tax system differs. If time forces cuts, cut elsewhere.

**Message:** both villages are fed. One of them manages it only by borrowing year after year.

**Slide:** public debt over ten years, two lines. The terracotta line climbs; the teal line is a small hump that returns to zero.

**Source:** step 2, `fiscal_taxes` and `fiscal_parking`.

**Expected question:** "Why does the SuMSy government repay so fast?" In that money, lenders accept a slightly negative rate, because lending loses less than holding money. The government is paid a little to borrow.

---

## 4. Can the debt village stop borrowing? (4:30 – 6:00, about 210 words)

**Changed twice with the new runs.** "The debt is what feeds people" does not survive them, and neither does "a tax on balances closes the budget".

**What closes the debt village's budget.** The answer is the land levy, whose rate follows the cost of holding money (coder, step 8):

| Item, per year | Debt village, T | Debt village, P |
|---|---|---|
| Tax on balances | none | 400–1,400 |
| Land levy | 3,400–4,000 | **5,500–9,700** |
| Cost of the benefit | 3,500–8,300 (both) | |

- The tax on balances raises the cost of holding money.
- The levy rule follows that cost, so the levy rises.
- The levy funds the budget.

**Outcome:**

- Under P the debt is 18,000 and falling at step 8, and about zero at step 11.
- Under T, at step 11, the debt levels off at 20,000–30,000 once fiscal policy kicks in.

**But the village still loses people:**

| | Step 8 | Step 11 |
|---|---|---|
| Debt village, P | 480 alive | 425 alive |
| Debt village, T | 477 alive | 390 alive |
| SuMSy, either package | 512 | 512 |

**Cutting spending to force the debt down** (debt village against itself, 20.4, own tax package):

- A 60 % debt ceiling: **313** alive against 488 without one.
- Austerity: **446**.

**Why the debt levels off at step 11 under T: the claimants die.** The benefit bill falls from 10,100 a year (year 2) to 2,800 (year 10) as 122 people die. Measured per starting villager, the debt at step 11 is 48 against 238 at step 8. **At step 11 the budget improves because of the hunger.** The two problems are connected there; at step 8 under P, the levy closes the budget while about the same number die.

**Who dies, and of what** (step 8, T, one run; say "in one run we traced"):

- 46 died, mostly in years 5–6.
- The month before dying, 43 of the 46 were in debt, 48.6 on average, against a loaf at about 4 (a meal about 8).
- About half had a little work; about half received the benefit. Their cash averaged 4, none owned land, and each had been short of bread for two months.
- Bread was not scarce. They could not pay for it.
- **Check first:** the trace gives their benefit as 4.1 against a meal of about 8. A two-loaf benefit should buy a meal. Until that is explained, don't say "the benefit is paid".
- **The mechanism:** people with too little work buy bread on credit. Collecting that debt then takes what the benefit and the odd job bring.

**Message, in plain words:** in the debt village, the people who die are people in debt. The bread is there, the benefit is paid, and the repayments come first. Making holding money cost something closes the budget through the land tax, but it doesn't save them.

**Peer-review note before you say "it is the money's doing"** (the handoff says this). Three things combine in that mechanism, and only one is clearly the money:

1. **Debt that carries interest.** This is the money. In SuMSy the same credit runs at a negative rate.
2. **The collection floor.** `collection_floor_in_breads = 1.0` means repayments and garnishment may take a person's cash down to one loaf, while survival needs two. The rule is identical on both sides, and it modestly mirrors the legal protected minimum on garnishment. But it is set at half of what a person needs to live, and it only bites where people carry debt.
3. **SuMSy's other income.** At step 8, SuMSy villagers receive the income of 5 plus a land dividend of roughly 4–6.5 a month. That keeps them out of debt in the first place. The income is the money; the dividend's size follows from it under D5.

**One test settles which of these carries the deaths:** step 8, both packages, both moneys, four seeds, with `collection_floor_in_breads = 2.0` (one meal protected). That is 32 jobs.

- If the debt village then keeps everyone alive, the deaths come from the collection rule acting on interest-bearing debt. The money's role is creating that debt, and the talk should say exactly that.
- If people still die, the money claim stands as it is.

Step 2 is a consistency check: no dividend there, and the debt village loses only 2.

**Slide:** two panels. Left: the debt village's public debt under T and under P. Right: alive at year ten (T, P, debt ceiling, austerity), with a dashed line at 512.

---

## 5. A more complex village: the grid (6:00 – 7:10, about 165 words)

**What is added:** shareholders and a share market, a land levy with a dividend, a government reserve, then VAT and an active fiscal policy.

**The grid:** two moneys by two tax systems. Each cell shows the three conditions: fed · free prices · no endless debt.

| | Income taxes (T) | Tax on balances (P) |
|---|---|---|
| **Debt money** | ✗ fed (390–477) · ✓ · ✗ debt at steps 2 and 8 (climbing to 198,000 and 122,000); levels off at 20–30k at step 11, because the claimants die (122) | ✗ fed (425–480) · ✓ · ✓ from step 8 (✗ at step 2) |
| **SuMSy** | ✓ (512) · ✓ · ✓ (one start-up loan, repaid in 2 years) | ✓ · ✓ · ✓ |

**Message:** whether the debt village's budget closes depends on the tax system and on the cost of holding its money. Whether everyone eats depends on the money. Only one money ticked all three boxes, under either tax system.

**Slide:** the grid, with ticks only.

**Source:** steps 8, 11 and V8, `fiscal_taxes` and `fiscal_parking`.

**Realistic set:** the same pattern holds. The debt village keeps 410–499 alive, SuMSy 511–512. One sentence: "With more realistic firms and contracts, the pattern holds, after a single test of four runs."

---

## 6. Who owns what (7:10 – 8:20, about 165 words)

**What happens:** survival is one question; how the village shares out is another.

**Step 8, same rules on both sides (T / P):**

| Measure | Debt village | SuMSy |
|---|---|---|
| Inequality of **cash** (Gini) | 0.33 / 0.35 | **higher:** 0.45 / 0.62 |
| Inequality of **wealth** (Gini) | 0.78 / 0.70 | **lower:** 0.53 / 0.52 |
| Poorest tenth (meals) | 0.5 / 0.7 | **21 / 17** |

- At step 2 the wealth Gini is equal in both villages (0.74). The gap opens with shares, land and the levy.
- In the productive village the wealth Gini is 0.66 / 0.60 (debt) against **0.22 / 0.25** (SuMSy).

**A confound to state:** from step 8, the same levy rule brings the SuMSy village **23,000–40,000 a year** (coder), paid out per head. That is roughly 4–6.5 a person a month, about as much as the guaranteed income of 5. The debt village's levy brings 3,400–9,700, and it goes to the budget.

- So SuMSy's lower wealth inequality and its well-off poorest tenth from step 8 on are partly the land dividend.
- The rule is the same in both villages. The amount differs because the levy follows the cost of holding each money.
- Say this in one sentence, because someone will find it: "Part of what spreads wealth in the SuMSy village is a tax on land that its money makes much higher."
- Two checks before the talk:
  - **D10 is no longer a detail.** Should the SuMSy levy follow the cost of holding cash (3.5 % a month) or of lending it (1.5 %)? The choice could roughly halve the 23–40k.
  - **Step 2 has no levy.** At step 2 the wealth Gini is equal (0.74 both) and the SuMSy poorest tenth still hold 16–18 meals against about 1.

**The limit:** with normal profit margins in every sector, SuMSy's wealth inequality rises [from about 0.45 to about 0.75]. That figure comes from the 20.4 strategy runs, comparing SuMSy with itself; label it so.

**A measure of "a pleasant life"** (your original question): theatre tickets per head per month, steps 8 and 11. SuMSy: **1.25**, every seat in the house from year 2. Debt village: **0.1 rising to 0.33**. One slide, two bars: the SuMSy village fills its theatre; the debt village's stays mostly empty. It carries the same confound as above, the dividend, so keep the claim to what people do, not why.

**Message:** SuMSy spreads money; it does not by itself spread ownership. Dividend taxes, co-operatives and the levy are the levers.

**Slide:** two pairs of bars (cash, wealth) per village. One line beneath: "Money ≠ ownership".

---

## 7. The struggle (8:20 – 10:00, about 235 words)

The work-in-progress part, told as a story about how results are made and unmade.

**1. A claim that had to be narrowed (new, from this week):**

- For weeks the comparison ran the two villages on different tax systems. Put on the same rules, the main result held.
- But one claim had to be narrowed: "today's money needs a debt that grows forever". Make holding money cost something, and a land tax that follows that cost closes the debt village's budget. The hunger stays.

**2. Greed against sufficiency** (realistic set):

- A firm that prices to cover its costs outlives one that prices for a margin, wherever customers can walk away. This holds in both moneys.
- Where demand is unlimited, both strategies survive.
- Stef's line: *a margin target never has enough; a reserve target does.*

**3. What doesn't work yet:**

- In the debt village, the farms that price only to cover their costs fail every time, even on the stable version. Every attempt to fix this through the price set off inflation.
- Candidate reading, said as a conjecture: under debt money, a firm that only covers its costs cannot carry a founding loan. The money itself asks for a margin. Under SuMSy it doesn't.

**4. What was built and thrown away:**

- four rules, each built, tested and dropped on the data;
- a comment bug that silently switched off eighteen rules and voided two days of runs;
- a bug that charged SuMSy firms' idle money twice, at one step.

**Message:** a simulation is only as honest as the checks on it. Every rule is public and open to challenge.

**Slide:** a "graveyard" of four tombstones, one word each. Then the claim before and after narrowing, as two lines of text.

**Source:** handoff §5 (versions .9 and .11), strategy runs.

---

## 8. Close (10:00 – 11:00, about 140 words)

**Back to the question:** can today's money carry an economy that doesn't grow?

**In these villages:**

- Today's money never fed everyone, whichever tax system it had.
- With income taxes, its government kept borrowing until fiscal policy cut spending, and then more people died. When holding money cost something, the budget closed, but the hunger didn't.
- The Sustainable Money System fed everyone under both tax systems and repaid its one loan within three years.

**The limits:** two small villages, not Belgium. Four runs per cell on the newest numbers. One step of the ladder is one configuration, not a forecast.

**The point:** the rules of money are choices. They can be simulated, tested and argued about.

**Invitation:** "The whole village is public. Come and break it."

**Slide:** the grid again, plus the repository address.

---

## Questions to prepare for (not in the talk)

1. **"SuMSy's prices fall several percent a year. Isn't the income just getting worth more?"**
   - Partly. The falls are 4–8 % a year at most steps and 13–16 % in the productive village.
   - But with more realistic contracts, SuMSy prices hold (about −1 % a year at step 8), and still 511 of 512 survive.
   - In the 20.4 runs, halving the income from year five kept everyone alive (RV8).
2. **"Why do people die in the debt village if there's a benefit?"** They are in debt, and the repayments take the benefit (section 4). Have the collection-floor test result ready.
3. **"You put the bank fees and borrowing rules into 'the money'. Isn't that convenient?"** They follow from two rules: banks don't create money, and holding money has a cost.
4. **"How many runs is this?"** Four per cell on the new numbers, ten on the older ones. Say "in every one of four runs", never "significant": with four pairs the best possible p is 0.125. The spread is wide in places; the worst debt-village run at step 8 under P kept 448.
5. **"Is this calibrated to a real economy?"** No. It is a village built to isolate one question.

---

## Still needed from the simulation chat

| For | What | Why |
|---|---|---|
| All | **The `:own` regression result** (not in the handoff) | Every number in this file depends on it |
| Section 4 | **The collection-floor test:** step 8, T and P, both moneys, four seeds, `collection_floor_in_breads = 2.0` | Decides whether the talk can say the deaths are the money's doing |
| Section 4 | The death trace's other seeds, or the same counts from the 4-seed summaries (deaths in debt / not in debt) | One run is thin for the only causal story in the talk |
| Section 6 | Land dividend per head per month in both villages at step 8 (T, P); D10 decision | The SuMSy levy (23–40k a year) is about as large as the guaranteed income |
| Section 4 | The trace gives the benefit as **4.1 against a meal of about 8**. A two-loaf benefit should cover a meal. Is the benefit priced at a lagged or starting loaf price, cut, or paid in part? | If the benefit covers only half a meal, "the benefit is paid" is misleading, and the cause shifts again |
| Section 3 | Repaid month: median or mean (coder: 22 and 36; summaries: 24.0 and 38.0) | Quote one measure consistently |

Answered on 22 October: §4b start-up borrowing; levy against tax on balances; step 11 under T (levelled off, because the claimants die); who dies (one run); consumption is flat; paired tests per folder (4 of 4 everywhere with a government).
