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
> Two villages. Each has 512 people, two banks, four farms and four bakeries. A quarter of the villagers own the land. There are enough hands and enough land to feed everyone twice over. And nothing grows: the same people and the same land, year after year. Economists call that a steady state.
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
- The SuMSy government borrows once, at the start, while the money builds up: **7,200, repaid by month 24**. Then never again.

**With a tax on balances instead (P):** the debt village borrows half as much, **99,000**, and still climbing. The SuMSy village borrows **8,200, repaid by month 38**.

**Message:** both villages are fed. One of them manages it only by borrowing year after year.

**Slide:** public debt over ten years, two lines. The terracotta line climbs; the teal line is a small hump that returns to zero.

**Source:** step 2, `fiscal_taxes` and `fiscal_parking`.

**Expected question:** "Why does the SuMSy government repay so fast?" In that money, lenders accept a slightly negative rate, because lending loses less than holding money. The government is paid a little to borrow.

---

## 4. Can the debt village stop borrowing? (4:30 – 6:00, about 210 words)

**This section changed with the new runs.** The old message, "the debt is what feeds people", does not survive them.

**Route 1: tax balances instead of incomes** (P, same rules on both sides). From step 8 the debt village's borrowing stops:

- Step 8: debt **18,000 and falling** (peak 21,000).
- Step 11: **about zero** (peak 3,900).

But the village still loses people:

| | Step 8 | Step 11 |
|---|---|---|
| Debt village, P | 480 alive | 425 alive |
| Debt village, T | 477 alive | 390 alive |
| SuMSy, either package | 512 | 512 |

**Route 2: cut spending to force the debt down** (debt village against itself, 20.4):

- A 60 % debt ceiling: **313** alive against 488 without one.
- Austerity: **446**.

**Message:** in the debt village, the debt and the hunger are two separate problems. A tax on balances solves the first. Nothing tried so far solves the second. Cutting spending makes the second worse.

**Slide:** two panels. Left: the debt village's public debt under T and under P. Right: alive at year ten for T, P, the debt ceiling and austerity, with a dashed line at 512.

**Before writing this section, the talk needs one answer from the simulation chat:** why do people die in the debt village while a two-loaf benefit is paid? The poorest tenth hold negative wealth (−5 to +1 meals), which points to household debt, but that is a guess. Without the mechanism, this section can show the deaths but not explain them, and the audience will ask.

**Source:** `fiscal_parking` and `fiscal_taxes`, steps 8 and 11; 20.4 cells D8-60 and A8. The latter are labelled "own tax package", because they compare the debt village with itself.

---

## 5. A more complex village: the grid (6:00 – 7:10, about 165 words)

**What is added:** shareholders and a share market, a land levy with a dividend, a government reserve, then VAT and an active fiscal policy.

**The grid:** two moneys by two tax systems. Each cell shows the three conditions: fed · free prices · no endless debt.

| | Income taxes (T) | Tax on balances (P) |
|---|---|---|
| **Debt money** | ✗ fed (390–477) · ✓ · ✗ debt (25,000–122,000, climbing) | ✗ fed (425–480) · ✓ · ✓ from step 8 (✗ at step 2) |
| **SuMSy** | ✓ (512) · ✓ · ✓ (one start-up loan, repaid in 2 years) | ✓ · ✓ · ✓ |

**Message (sharper than "it follows the money"):** the tax system decides whether the debt village's budget can close. The money decides whether everyone eats. Only one money ticked all three boxes, under either tax system.

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

**The limit:** with normal profit margins in every sector, SuMSy's wealth inequality rises [from about 0.45 to about 0.75]. That figure comes from the 20.4 strategy runs, comparing SuMSy with itself; label it so.

**Message:** SuMSy spreads money; it does not by itself spread ownership. Dividend taxes, co-operatives and the levy are the levers.

**Slide:** two pairs of bars (cash, wealth) per village. One line beneath: "Money ≠ ownership".

---

## 7. The struggle (8:20 – 10:00, about 235 words)

The work-in-progress part, told as a story about how results are made and unmade.

**1. A claim that had to be narrowed (new, from this week):**

- For weeks the comparison ran the two villages on different tax systems. Put on the same rules, the main result held.
- But one claim had to be narrowed: "today's money needs a debt that grows forever". A tax on balances closes the debt village's budget. The hunger stays.

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
- With income taxes, its government borrowed forever. With a tax on balances, the budget closed, but the hunger didn't.
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
2. **"Why do people die in the debt village if there's a benefit?"** The answer is needed from the simulation chat (section 4).
3. **"You put the bank fees and borrowing rules into 'the money'. Isn't that convenient?"** They follow from two rules: banks don't create money, and holding money has a cost.
4. **"How many runs is this?"** Four per cell on the new numbers, ten on the older ones. The spread is wide in places; the worst debt-village run at step 8 under P kept 448.
5. **"Is this calibrated to a real economy?"** No. It is a village built to isolate one question.

---

## Still needed from the simulation chat

| For | What | Why |
|---|---|---|
| Section 4 | Why people die in the debt village with a two-loaf benefit paid: who dies, and of what (no work and no benefit, household debt service, bread unavailable) | The section's message rests on it |
| Section 4 | Under P at step 8: how much of the debt village's budget closing comes from the land levy and how much from the tax on balances | Under P, the levy rate in the debt village rises with the cost of holding money. The tax on balances may not be doing the work alone |
| Handoff §4b | Correct point (2): the SuMSy government does borrow once at the start (step 2: 7,200 under T, 8,200 under P; step 8: about 1,300; all repaid by months 22–38) | §4b says it never borrows; the summaries' `public_debt_peak` say otherwise |
| Section 5 | Is the debt village's debt under T at step 11 still rising at month 120? | Its peak equals its end value |
| All | Paired tests per folder | The grid claims "every seed" |
| All | The `:own` regression result | Everything above depends on it |
