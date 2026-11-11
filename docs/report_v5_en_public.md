# The Bread Economy

*What happens to a village when you change its money*

Version 5 — 11 November 2026

← Previous report: [version 4, 13 October 2026](https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm) (https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm) · Next report: none yet

*This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred and twenty rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where it matters the worst run is mentioned as well. A round is best thought of as a month. There are five hundred and twelve villagers. "Alive" means alive at the end of the hundred and twenty rounds. The figures are from the runs of 10 and 11 November 2026 (model versions `2026-11-10.1` and, for the villages with greedy villagers, `2026-11-11.0`, on EconoSim 0.3.1): 208 villages on each of two ladders, ten runs each, and a further 120 runs for the comparison of §7. Unless a frame says otherwise, the figures are from the *realistic* ladder, explained in §5.
\]

This report can be read on its own. Readers who know the earlier versions will find several of their findings changed; §16 lists them.

## 1. A village, twice

Imagine a village. Five hundred and twelve people live there. Some own land, most do not. Four farms grow grain, four bakeries turn it into bread, and four businesses sell everything that is not bread: a haircut, a meal out, an evening's music. We call those services. Everyone needs two loaves a month. Go three months without any bread at all and you die.

Now imagine the same village built twice, with the same people, the same fields, the same ovens and the same habits, and one difference: where its money comes from. Let ten years pass in both, and look at who is still there, who owes what, and who owns what. Because the two copies start out identical, whatever differs at the end comes from the money and from the rules that go with it. Telling those two apart is the hard part, and the report is organised around it.

## 2. Who lives there

Of the five hundred and twelve villagers, a hundred and twenty-eight own land, a plot and a half each. Everyone else rents a place to live and works for a wage. A villager can sell up to three units of work a month, which is a full-time job.

Each firm is founded by four villagers who put up its working money from their savings and borrow what they lack. When a kind of business is doing unusually well, or customers are being turned away, someone with savings may open another. Two banks take deposits and lend.

From the second step of the story there is a government. It hires up to a tenth of the village's workers for public jobs, taxes, and pays a benefit to people who look for work and find none.

## 3. Two kinds of money, in plain words

In the **debt village**, money is made the way it is made around us. When a bank lends a baker a thousand, it writes a thousand into the baker's account. Nothing was there before. When the baker repays, the thousand disappears again. The interest does not disappear: it is the bank's income, and the bank spends it like anyone else. All the money in the debt village is money somebody owes, and there is only more of it when somebody borrows more. The government pays a benefit of two loaves a month to people without work, and borrows when its taxes fall short.

In the **SuMSy village**, nobody borrows money into existence. Every villager receives a guaranteed income each month, newly made, whether they work or not. Money that sits in an account above a modest cushion pays a parking fee: a small part of it disappears each month. The fee takes out roughly what the income puts in, so the amount of money settles at a level and stays there. The banks create nothing; they lend out what their depositors leave idle. The government takes a further small share of idle money as a tax, pays its public jobs from it, and pays a benefit of one loaf, half the debt village's, because the income covers the other half.

\[ KADER  
**The two systems, as run.** Debt money: bank loans at interest; a repayment destroys the principal and leaves the interest with the bank as its own money; the government borrows what its taxes do not cover; unemployment benefit of two loaves a month from step 2. SuMSy: guaranteed income of 5 a month (one loaf at the starting price) for every person; a parking fee (demurrage) of 2 % a month on money above a cushion of 30; a parking tax on the same money, on top of the fee, for the government; unemployment benefit of one loaf; from step 8 a levy on land, paid out to every villager in equal parts. These differences between the villages are deliberate (each village runs under the rules its money was designed with) and are removed in §7.
\]

## 4. A month in the village

Each month the farms hire workers and grow grain. The bakeries buy grain, most of it under a six-month contract with a farm, hire workers and bake. The service businesses hire and open their doors. Then the villagers shop: bread first, at the price on the shelf, and services with whatever money and free hours they have left.

Bread does not keep. It sells at full price in the month it is baked and at seven tenths the month after. In its third month the bakery gives it away, and after that it is thrown out. Grain keeps for a year.

At the end of the month the bills are settled: wages and rents first, then taxes, then what firms owe each other. Whoever is short borrows, if a bank will lend, or sells land, or goes without. A firm that cannot pay what it owes for months on end, and can no longer borrow, is wound up. Its debts pass to its owners, and its ovens stand idle until someone with savings starts it again.

## 5. How the villagers decide

The villagers follow simple rules, the same in both villages, and each was chosen to look like what people around us do.

**Work.** A villager works to eat, to keep a cushion of savings, and to afford an evening out. Whoever has other income, from rent, dividends or the guaranteed income, offers less work. Whoever has nothing offers every hour they have.

**Wages.** A wage, once agreed, is not cut. It rises with the price of bread. Someone newly hired may start lower than the people already there.

**Shopping.** People buy this month's bread before they are hungry. Those who can afford fresh bread take the freshest. Those who cannot take last month's at the lower price, and the free bread goes to the people who have least, two loaves each at most. Services take time as well as money: a day has twenty-four hours, most of them spoken for by sleep, the household and work, and nobody spends more than about an hour and a quarter a day being served.

**Land.** A field is bought for the rent it will bring. Each buyer has their own view of what that is worth.

**Firms.** A firm makes about what it sold last month and a little more. It raises its price when it sells out and lowers it when stock is left over. It does not sell below what the goods cost to make.

\[ KADER  
**Two ladders, and how a rule earned its place.** The village is run under two sets of labour rules. On the *standard* ladder anyone may be hired each month at the going wage. On the *realistic* ladder a worker and an employer are bound by a contract, employers take back last month's workers first, and each firm plans on its own sales. Both ladders run every village; they agree on every finding reported here unless the text says otherwise.  
The rules of §4 and §5 were adopted on evidence from paired runs with the rule on and off (three steps of the ladder, both villages, four runs each), never on a single run. Kept: the floor under wages, a year of storage for grain, the supply contracts, prices set against expected sales, bread priced by age. Rejected after testing: smaller price steps; a wider tolerance before a price moves; planning production on expected rather than actual sales (output then swung up and down from month to month); and charging the cost of stale bread to the price of fresh (a fifth of one village died).
\]

## 6. The ladder

The village is built up one institution at a time, so that each step shows what one thing adds. At every step the same question is asked of both villages: who still has bread, who owes what, and who owns what?

### Step 0. Bare bones

Farms, bakeries, a labour market and money. No government, no benefit, no rules beyond the market. In the debt village thirty-four people are alive after ten years. In the SuMSy village, four hundred and eighty-seven.

This is the harshest number in the report. With wages that do not fall and prices fixed on the shelf, a villager without work has nothing to bargain with, and in a village with no institutions at all that is fatal. The SuMSy village survives on its guaranteed income, though one run in ten loses a third of its people.

\[ KADER  
**Step 0, ten-run means.** Alive: debt 34 (worst 25), SuMSy 487 (worst 323). On the standard ladder: 114 (88) and 468 (463). No public debt in either: there is no government.
\]

### Steps 1 and 2. Planning ahead, then a government

Let firms plan a month ahead and little changes: seventy-eight survive in the debt village. Add a government that taxes, hires, pays a benefit and may borrow, and nearly everyone lives: five hundred and five. The benefit is what keeps them alive, and the government pays for it by borrowing, a hundred and ten thousand over the ten years. One villager in four is looking for work and finding none.

The SuMSy village keeps everyone and its government owes nothing. Its wealth is spread no more evenly than the debt village's at this step. Land is the reason, and §11 returns to it.

\[ KADER  
**Step 2, ten-run means.** Alive: debt 505 (worst 495), SuMSy 512. Public debt: 110,000 / 0. Without work: 124 / 12. Wealth Gini: 0.73 / 0.74. Bread at year ten: 5.98 / 7.21.
\]

### Steps 3 to 7. Interest, services, bonds

Interest on savings, the service businesses, government bonds, a charge on the banks' idle reserves, and a few refinements arrive in turn. None of them moves the picture much. The debt village keeps about five hundred and eight people and a public debt near a hundred thousand. The SuMSy village keeps everyone and owes nothing.

### Step 8. Owners, a stock market, and the land levy

Firms get owners, and their shares trade. In the SuMSy village a levy on land arrives, and what it raises is paid out to every villager in equal parts. This is the step at which the two villages come apart, and most of the rest of the report compares them here.

The debt village keeps five hundred and eight people and owes eighty-nine thousand. A hundred and twenty have no work. Its poorest tenth own nothing: a tenth of a meal each. The SuMSy village keeps everyone, owes nothing, has nobody without work, and its poorest tenth own twelve meals each. Wealth there is spread about twice as evenly.

\[ KADER  
**Step 8, ten-run means (realistic ladder).** Alive: debt 508 (worst 501), SuMSy 512. Public debt: 89,000 / 0. Without work: 120 / 0. Work sold a villager a month: 2.65 / 2.69 units. Poorest tenth: 0.1 / 11.8 meals; gap between the richest and the poorest tenth: 288 / 72 meals. Wealth Gini: 0.76 / 0.36. Bread at year ten: 5.61 (+0.6 % a year) / 7.26 (+4.2 %). Firms wound up in ten years: 32 / 58. Services bought a villager a month: 5.4 / 24.9 hours. Dividends paid a month: 14 / 523. A plot of land: 13 / 3.3 years of its rent.  
**Standard ladder:** alive 510 / 512; public debt 77,000 / 0; without work 142 / 0; wealth Gini 0.81 / 0.34; poorest tenth −0.6 / 33.3 meals.
\]

### Step 9. Cooperatives

Turn the bakeries and farms into cooperatives owned by their workers and customers. The debt village hardly notices. The SuMSy village becomes the most equal of the ladder's main steps: its poorest tenth own thirteen meals, and the gap to the richest tenth is fifty-four.

\[ KADER  
**Step 9, ten-run means.** Alive: 508 / 512. Public debt: 88,000 / 0. Wealth Gini: 0.74 / 0.30. Poorest tenth: 0.6 / 13.1 meals; gap 265 / 54 meals. Without work: 122 / 0.
\]

### Step 11. A tax policy, and a tax on bread

Give the government a rule that raises taxes when its debt grows, and a sales tax collected in the shop: six per cent on bread and twenty-one on services, as in Belgium. The debt village's public debt falls to fifty-two thousand, the lowest on its ladder. The cost falls on the people at the bottom: the poorest tenth now owe more than they own.

(There is no step 10. An earlier design had one, a public reserve, which turned out to change nothing; its number is left empty so that the steps keep their names.)

\[ KADER  
**Step 11, ten-run means.** Alive: debt 504 (worst 494), SuMSy 512. Public debt: 52,000 / 0. Poorest tenth: −1.6 / 11.3 meals. Wealth Gini: 0.81 / 0.35. Without work: 88 / 1.
\]

### A side step. The productive village

Suppose the village were three times as good at making things. In the SuMSy village what a villager produces rises to ten loaves' worth a month, the poorest tenth own sixty-four meals, and bread falls to a ninth of what it cost: a village that has enough lets its prices fall. In the debt village what a villager produces barely moves, from 2.3 to 2.8. The capacity is there, and the money to buy what it could make is not.

The productive village is also where the SuMSy village is least equal, and where one of the rules of §5 does harm. Both are taken up below.

\[ KADER  
**The productive village, ten-run means.** Alive: 507 / 512. Output a villager: 2.84 / 10.08 loaves' worth a month. Public debt: 42,000 / 0. Poorest tenth: −1.8 / 63.8 meals. Wealth Gini: 0.79 / 0.54. Without work: 96 / 21. Bread: 0.88 / 0.82, falling about 10 % a year in both.
\]

### What the ladder says

Three things hold on every step from the second on, and on both ladders.

The SuMSy government carries no debt. The debt village's carries between forty and a hundred and thirty thousand, between half a year and a year and a half of everything the village produces, and every policy that lowers it takes something from the people at the bottom.

Nearly everyone survives in both villages once there is a government. In the debt village that is the benefit at work, paid for by borrowing.

From step 8 on, wealth is spread far more evenly in the SuMSy village. Before step 8 it is not. The money alone does not do it. The levy on land does, in a village whose money lets the levy be paid out rather than kept.

## 7. The same taxes in both villages

Up to here each village ran under its own rules: the debt village with income taxes and a benefit, the SuMSy village with its fee, its income and its levy. So a reader may fairly ask whether the SuMSy village does better because of its money or because of the payments that come with it. The fair test is to give both villages the same taxes and the same payments, and see what difference is left.

Two packages were tried. In the first, both villages tax income, profits and dividends the way a European country does, and pay a benefit to those without work. In the second, both take the SuMSy route: a tax on money that sits idle, and a payment to everyone of what a meal costs.

Under either package, at steps 8 and 9, the SuMSy village is still far more equal. The gap between the villages barely narrows. Under the second package both villages improve, and the debt village improves a great deal: its poorest tenth go from nothing to seven meals each, and almost nobody is without work. It pays for that by borrowing more.

So the answer is: both, and they can be told apart. The payments do a large part of the work, and a debt village can copy them. What it cannot copy is doing so without debt.

The productive village is the exception. There the second package brings the debt village almost level with the SuMSy village, whose own figure no package moves.

\[ KADER  
**Same rules in both villages, wealth Gini (ten-run means, realistic ladder).** Own rules → income-tax package → parking-tax package.  
Step 8: debt 0.76 → 0.60 → 0.52; SuMSy 0.36 → 0.22 → 0.17. Difference under the same rules: 0.38 and 0.35.  
Step 9: debt 0.74 → 0.48 → 0.49; SuMSy 0.30 → 0.18 → 0.13. Difference: 0.30 and 0.36.  
Productive village: debt 0.79 → 0.81 → 0.61; SuMSy 0.54 → 0.53 → 0.55. Difference: 0.28 and 0.06.  
**Debt village under the parking-tax package:** poorest tenth 6.9 meals at step 8 (0.1 under its own rules), 10.6 at step 9; without work 9 and 13 (120 and 122); public debt 92,000 and 122,000 (89,000 and 88,000). Under the income-tax package: public debt 29,000 and 40,000; without work 85 and 83; poorest tenth −1.8 and 0.2 meals. The SuMSy government owes nothing under any of the three.
\]

## 8. Work, and wanting work

A hundred and twenty people in the debt village have no work at step 8, and nobody in the SuMSy village. It looks as if the SuMSy village creates jobs. It does not.

Count the work that is actually done and the two villages are almost level: each villager sells about two and two-thirds units of work a month, in both. The difference is in how much work people *offer*. In the debt village villagers offer nearly all the hours they have, because what they earn barely covers their bread. In the SuMSy village they offer two thirds, because the guaranteed income covers the bread and they work for the rest. The same amount of work is shared among people who need it less.

The proof is in §7. Give the debt village a payment the size of a meal, and its people without work fall from a hundred and twenty to nine, with no more work being done than before.

There is one place where jobs really are missing. Villagers in the debt village buy five hours of services a month, and in the SuMSy village twenty-five. People who have nothing left after bread do not go out, and the businesses that would have served them stay small.

\[ KADER  
**Work at step 8, ten-run means.** Work offered as a share of what villagers could do: debt 92 %, SuMSy 68 %. Work sold a villager a month: 2.65 / 2.69 units. Villagers who offered work and sold none: 120 / 0. Services bought a villager a month: 5.4 / 24.9 hours. Under the parking-tax package the debt village has 9 without work at 2.55 units sold a villager.
\]

## 9. Who gets the profit

When firms are run well, they make a profit, and a profit goes to the owners. In the SuMSy village at step 8 the firms pay out more than five hundred a month in dividends, against fourteen in the debt village, where customers have little to spend and margins are thin. The owners are the villagers who were already the best off.

That is why the SuMSy village, for all its guaranteed income, is not an equal village: its wealth is spread about twice as evenly as the debt village's, and no more. A parking fee on money does not reach the income from owning a business. A tax on dividends does. Under the first package of §7 the uneven part of the SuMSy village's wealth falls by more than a third.

The productive village makes the same point from the other side. Where there is three times as much to earn, the owners earn it, and no package tried here changes that.

## 10. Prices, and a floor under wages

In a village where a wage is never cut, prices have something to stand on. The debt village's prices are steady: at step 8 they rise by about half a per cent a year. The SuMSy village's rise by about four per cent a year. That is inflation, faster than a central bank would like, and it has to be said plainly. Why it rises at that rate has not been traced.

The floor under wages holds the price level up and does nothing else. With it or without it, the same people own the same share. On the standard ladder, where wages are still bargained each month, the SuMSy village's prices fall by five or six per cent a year instead of rising. Which of the two a real SuMSy economy would show depends on how wages are set, and this model cannot settle that.

In the productive village prices fall by a tenth a year in both villages, because a village that makes three times what it needs has to sell it somehow.

\[ KADER  
**Bread at year ten and its yearly change, ten-run means.** Step 2: 5.98 (+0.7 %) / 7.21 (+4.1 %). Step 8: 5.61 (+0.6 %) / 7.26 (+4.2 %). Step 11: 4.54 (−1.7 %) / 7.41 (+4.6 %). Productive village: 0.88 (−10.8 %) / 0.82 (−10.1 %). Standard ladder, step 8: 4.16 (−1.1 %) / 2.63 (−6.2 %). Two variants of the SuMSy village inflate by more than 20 % a year and are named in §15.
\]

## 11. Land

Land is where the two kinds of money differ most sharply, and where the SuMSy village needs its levy.

A field brings its owner a rent. What someone will pay for the field depends on what else they could do with the money. In the debt village money can be lent at interest, and a field sells for thirteen to twenty-six years of its rent, in the range land costs around us. In the SuMSy village money in an account loses a little every month, so anything that holds its value is worth more than it would be elsewhere. Without a levy, a field there sells for a hundred years of its rent. People flee from money into land, as Silvio Gesell warned a century ago that they would.

The levy ends that. With it, a field sells for three years of its rent, land stops being a place to hide wealth, and the proceeds, paid out to everyone, are the largest single reason the SuMSy village is more equal from step 8 on. A design that charges a fee on money and leaves land untaxed moves the hoarding from one to the other.

\[ KADER  
**Land, last-year means over ten runs.** Price of a plot in years of its rent: step 2, debt 26, SuMSy 100; step 8, debt 13, SuMSy 3.3. Plots sold a month: about one in the debt village, two in the SuMSy village at step 8.
\]

## 12. Yesterday's bread

Bread that is given away instead of thrown away is a small rule with a telling result. In the debt village the bakeries give away about twelve loaves a month at step 8, and none are thrown out: there is always someone who needs them. In the productive SuMSy village the bakeries throw away forty loaves a month and give away almost none. The rule is the same in both. In the SuMSy village almost nobody is poor enough to qualify.

The rule has a cost, and it was adopted knowing it. In the productive debt village the well-off take the freshest loaves, the bakeries see their older bread lose its value and bake a little less, and in a village where bread is already short for some, a few more go without. In four paired runs, seven fewer people were alive at the end on average, and in the worst of them thirty-three fewer. That is how stale bread is sold in the world, and the report keeps the rule and its cost together.

\[ KADER  
**Bread by age.** Full price in the month baked, 70 % the month after, given away in the third month, thrown away after that; grain loses 1 % of its value a month in storage. A villager buys fresh when, after paying, their money stays above two thirds of the cushion they aim for, or still ends the month higher than it began. Free bread goes to those who fail that test and lack a meal, poorest first, two loaves each at most. Last-year means, loaves a month: step 8, debt 12 given and 0 thrown away, SuMSy 8 and 8; productive village, debt 12 and 0, SuMSy 0 and 40. No tax is due on bread given away, as in Belgium since 2013 for food given to food banks.
\]

## 13. When the land belongs to everyone

What if the land is owned in common, and the farms and households rent it from the village?

In the SuMSy village it works. Everyone survives, and wealth is spread more evenly than on any step of the main ladder. In the debt village it kills. A hundred and forty people are alive after ten years. The ground rent takes between a fifth and a half of a household's income and goes into the government's account, where it pays off debt and comes back to no one. Hand the rent back to the villagers in equal parts and four hundred and eighty-five survive.

It is the clearest case in the report of a rule that is neither good nor bad in itself. The same public ownership feeds one village and starves the other, and the difference is whether the money that is collected goes round again.

\[ KADER  
**Land in public hands, ten-run means.** Ground rent kept by the government: debt 140 alive (worst 83), SuMSy 512. Rent handed back in full: debt 485 (worst 381), public debt 83,000. Half handed back: 473 (worst 430), public debt 17,000. No ground rent charged: 486 (worst 419). In the SuMSy village the wealth Gini with public land is 0.22.
\]

## 14. Three tests of character

So far every villager has behaved alike. Three tests change that, at step 8.

### Greed

A greedy villager puts every bit of money above their cushion to use: half the time into whatever earns most, land, shares or money lent out, and half the time into more bread and more services. The test was run with the richest hundredth of the village greedy, then the richest quarter, then everyone.

A greedy hundredth changes nothing in either village.

A greedy quarter changes little on the realistic ladder. On the standard ladder it makes the SuMSy village less equal, and makes it produce nearly half as much again, because greedy people work more and buy more. Cooperatives blunt it: in the cooperative village the same greedy quarter leaves the spread of wealth where it was.

With everyone greedy, the SuMSy village is plainly less equal. Its poorest tenth own six meals where they owned twelve, its prices rise faster, by almost seven per cent a year, and it produces a fifth more. Its government still owes nothing and nobody dies. In the debt village greed costs something else: the spread of wealth barely moves, and the public debt rises by nearly half, from eighty-nine to a hundred and twenty-nine thousand.

So greed takes equality and stable prices from the SuMSy village, and solvency from the debt village's government. Neither village loses a life to it.

\[ KADER  
**Greed at step 8, ten-run means (realistic ladder), nobody → richest 1 % → richest quarter → everyone.** SuMSy: wealth Gini 0.36 → 0.35 → 0.33 → 0.45; poorest tenth 11.8 → 11.2 → 11.8 → 6.3 meals; bread +4.2 → +4.3 → +5.1 → +6.7 % a year; output a villager 2.75 → 2.75 → 2.70 → 3.31; work sold a villager 2.69 → 2.68 → 2.73 → 3.42 units. Debt: wealth Gini 0.76 → 0.75 → 0.76 → 0.72; public debt 89,000 → 87,000 → 91,000 → 129,000; without work 120 → 116 → 111 → 118. Alive: 508–512 throughout.  
**Standard ladder, SuMSy:** wealth Gini 0.34 → 0.34 → 0.45 → 0.61; output a villager 3.27 → 3.33 → 4.72 → 4.75.  
**Cooperative village, SuMSy** (realistic / standard): nobody 0.30 / 0.26; richest quarter 0.27 / 0.28; everyone 0.44 / 0.46. Figures for the villages with greedy villagers are from model version `2026-11-11.0`.
\]

### Hoarding

A hoarder keeps every spare coin as money and buys nothing but bread. The test made hoarders of the hundredth, and then the tenth, of the village holding the most money after the first year.

In the SuMSy village nothing happens, with one hoarder in a hundred or one in ten. The parking fee makes sitting on money a losing game, and the money comes back into circulation through the fee and the income. In the debt village one hoarder in a hundred changes nothing either. One in ten halves what the village spends on services and adds a tenth to the public debt.

\[ KADER  
**Hoarding at step 8, ten-run means, nobody → 1 % → 10 %.** SuMSy: wealth Gini 0.36 → 0.35 → 0.32; alive 512; no public debt. Debt: services bought a month 2,743 → 2,585 → 1,429 hours; public debt 89,000 → 86,000 → 98,000; alive 508 → 508 → 509.
\]

### People who do not work

Not everyone can or will take paid work: there is care to give, illness, art, or simply a choice. The test set aside one villager in twenty, twenty-six people, who look for paid work only when they cannot otherwise eat.

In the SuMSy village all twenty-six live. The guaranteed income carries them, and the village pays for it: the poorest tenth own five meals where they owned twelve, prices rise twice as fast, and the village produces an eighth less.

In the debt village all twenty-six die, the first of them within the year. Its benefit is for people who look for work and find none. Someone who stops looking once the benefit covers their bread loses the benefit the month after. In the model they end up with half a benefit, borrow for bread, and starve. A real benefit office would cut such a person off rather than pay them every other month, and the end would be the same. The finding is about a payment with a condition against a payment without one. Whether the debt village with a payment to everyone, the second package of §7, would keep them alive was not tested.

\[ KADER  
**Five per cent not working, step 8, ten-run means.** Alive: debt 486 (508 without them), SuMSy 512. In one run followed person by person (standard ladder), all 26 non-workers of the debt village died, the first in month 9, each with no money and a debt of about 16; one other villager died. SuMSy with them → without: poorest tenth 4.8 → 11.8 meals; bread +9.5 → +4.2 % a year; output a villager 2.40 → 2.75.
\]

## 15. What this shows, and what it cannot

A village of five hundred and twelve people is not a country, and several things in this one are still wrong.

The debt village has far too many people without work: a quarter of the village, where Belgium has about one in eighteen. §8 explains what the number means. It remains a number no real economy shows.

Firms fail too often. In the SuMSy village at step 8 a firm is wound up every other month, mostly small firms that are started again at once. None of the rules tried reduces it, and its cause is not yet known.

The debt village's output still swings a little from one month to the next in a way real economies do not. One cause was found and removed; a second remains.

Two variants of the SuMSy village inflate by more than twenty per cent a year. In one, landowners pass the levy on to their tenants: a levy passed on in rents feeds prices, which feed rents. That is a real weakness of the design under that behaviour, and it has not been traced to its end. One further variant of the test with everyone greedy runs to hyperinflation in both villages.

The two ladders disagree in two places: on whether the SuMSy village's prices rise or fall (§10), and on how much a greedy quarter matters (§14). Where they disagree, both answers are given.

The village is tuned to Belgium where it can be. The tax rates and the shares of spending are from official statistics. How much more a household spends on services as its income rises, how many staff an hour of service takes, and the figure for unemployment are provisional.

The villagers of both villages behave alike. People who received a guaranteed income might well behave differently from people who did not, and nothing here can say how.

And every finding is a finding about these rules. Several of this version's conclusions differ from those of the version before it, as the next section shows. The reader should expect the next version to do the same to some of these.

## 16. For readers of earlier versions

This section is for readers who know version 4. It can be skipped by everyone else.

**Work.** Version 4 read the SuMSy village's full employment as jobs created. Both villages do the same amount of work; the difference is in the work people offer (§8). The reason for the change: work done a villager was not reported before.

**Equality.** Earlier versions reported the SuMSy village at step 8 as considerably more equal than the 0.36 given here. Their firms planned badly and wasted their margins; with planning repaired, firms make profits and pay dividends, which go to the better-off (§9). Under a tax on dividends the SuMSy village is roughly as equal as the earlier versions reported.

**Prices.** Version 4 had both villages deflating, the SuMSy village by nine per cent a year. With wages that are not cut, the debt village's prices are steady and the SuMSy village's rise by four per cent a year (§10).

**The bare village.** The debt village without institutions kept more people in earlier versions. Posted prices and the floor under wages leave the poor of a village with no institutions nothing to bargain with (§6, step 0).

**The steps.** Step 10, the public reserve, is dropped. Theatres are now services, bought with free hours as well as money.

**Interest.** In earlier versions a repaid loan destroyed its interest along with the principal. The interest now stays with the bank as its income, which leaves more money in the debt village and its prices somewhat higher.

**Greed.** The greed tests were run again after a fault was found in how greedy villagers bought services; earlier figures for them should not be used.

**The question of version 4's §16**, whether the SuMSy village's advantage is the money or the transfers, is answered in §7.

## 17. The ladder's answer, for policy makers

**The public debt is the debt village's price for keeping people alive.** Once there is a government, almost nobody starves in either village. The debt village borrows to achieve that; the SuMSy village does not. Every measure that cuts the debt, on this ladder, is paid for by the poorest tenth.

**Payments to everyone do much of the work, and they can be copied.** A debt village that pays everyone the price of a meal has almost nobody without work and a poorest tenth who own something. It also owes more. The SuMSy village's advantage that remains under identical rules is that it gets there without debt, and with wealth spread about twice as evenly.

**A payment with a condition does not reach everyone.** People who do not look for work get nothing from a benefit for jobseekers. Under an unconditional income they live, and the rest of the village carries the cost in higher prices.

**Money that loses value needs a levy on land.** Without one, wealth moves from money into land, and a field costs a hundred years of its rent. With one, paid out to everyone, the SuMSy village becomes the more equal village. The levy is part of the design.

**A fee on money does not reach profits.** Where firms are run well, their owners gain, in either village. A tax on dividends closes much of that. Nothing tried here closes it in a village three times as productive, or in one where everyone is greedy.

**The count of people without work measures need as much as jobs.** Both villages do the same amount of work. Before counting the unemployed, count the work done.

**Collected money has to go round again.** Ground rent that disappears into a government's account starves the village that pays it. The same rent, handed back, does not.

## Glossary

**Guaranteed income.** The monthly payment every SuMSy villager receives, newly made each month, whether they work or not.

**Parking fee (demurrage).** The monthly charge on money held in an account above the cushion. The money it takes disappears, which keeps the amount of money in the SuMSy village level.

**Parking tax.** A further charge on the same money, on top of the fee, paid to the government.

**Cushion (buffer).** The money a villager tries to keep in reserve before spending on anything but bread; in the SuMSy village, also the amount on which no parking fee is due.

**Shortfall.** What a government spends beyond what it collects in a month; in the debt village it is borrowed and adds to the public debt.

**Public debt (government debt).** Everything the government has borrowed and not yet paid back.

**Benefit.** The monthly payment to villagers who looked for work and found none: two loaves in the debt village, one in the SuMSy village.

**Step (rung).** One stage of the ladder: the village with one more institution than the step before.

**Land levy.** The SuMSy village's charge on land, whose proceeds are paid out to all villagers in equal parts.

**Meal.** Two loaves at that month's price; the measure in which wealth is compared between villages whose prices differ.

**Services.** Everything the village sells that is not bread, bought with money and with the hours a villager has free.

**Dividend.** The part of a firm's profit paid out to its owners.

**Settlement (clearing).** The moment each month at which wages, rents, taxes and invoices are paid.

**Wealth Gini.** A number between 0 and 1 for how unevenly wealth is spread: 0 if everyone owns the same, 1 if one person owns everything. Used only in the frames.
