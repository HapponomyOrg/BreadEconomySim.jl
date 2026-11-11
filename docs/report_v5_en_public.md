# The Bread Economy

*What happens to a village when you change its money*

Version 5 — 11 November 2026

← Previous report: [version 4, 13 October 2026](https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm) (https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm) · Next report: none yet

*This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred and twenty rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where it matters the worst run is mentioned as well. A round is best thought of as a month. There are five hundred and twelve villagers. "Alive" means alive at the end of the hundred and twenty rounds. All figures are from the runs of 10 November 2026 (model version `2026-11-10.1` on EconoSim 0.3.1): two ladders of 208 villages each, 4,160 runs, and 120 further runs for the comparison of §5. Unless the text says otherwise, the figures are from the *realistic* ladder, explained in §3.
\]

**What changed since version 4.** Version 4 ended on a list of things the village could not yet do, and most of this version is that list worked off. The villagers now live in a month that looks more like ours: shops post their prices, wages do not fall, a day has twenty-four hours, bread goes stale, and a firm fails when it cannot pay rather than when its books look bad. Each of those rules was tried on its own before it was kept, and three were thrown out again. The two villages were then compared under identical taxes for the first time, which answers the question version 4 left open in its sixteenth section: is it the money, or the transfers? And two results of version 4 did not survive. The SuMSy village is less equal than it looked, and the debt village's missing work turns out to be something else than missing jobs. Both are told below as what they are.

## 1. A village, twice

Picture a village of five hundred and twelve people who live on bread. Farms grow grain, bakeries bake it, and since this version a third kind of business sells everything that is not bread: a haircut, a meal out, an evening's music. We call them services. Everyone needs two loaves a month to get by. Whoever goes without for too long dies, and the village is smaller the month after.

We build this village twice, with the same people, the same land and the same dice, and give each copy a different kind of money. Then we let ten years pass and look at who is still there, who owes what, and who owns what. Because the two copies start identical, whatever differs at the end comes from the money and from the rules around it. Telling those two apart is the hard part, and it is what the report is organised around.

## 2. Two kinds of money, in plain words

In the **debt village**, money is made the way it is made around us. A bank creates it when someone borrows, and it disappears again when the loan is paid back. The interest does not disappear: it is the bank's income, and the bank spends it like anyone else. A government taxes, pays a benefit to those without work, and borrows when its taxes fall short.

In the **SuMSy village**, nobody borrows money into existence. Every villager receives a guaranteed income each month, newly made, and every account pays a small parking fee on what sits in it above a free amount. The fee takes out roughly what the income puts in, so the amount of money settles at a level and stays there. The government has no need to borrow, and on the whole ladder it does not.

\[ KADER  
**The two systems, as run.** Debt money: bank loans at interest; a repayment destroys the principal and leaves the interest with the bank as its own money. Unemployment benefit of two loaves a month from step 2. SuMSy: guaranteed income of 4 a month for persons, a parking fee (demurrage) of 1 % a month above a free buffer; no benefit; from step 8 a levy on land whose proceeds are paid out to everyone. The fiscal asymmetries are deliberate at this stage (each village under the rules its money was designed with) and are removed in §5.
\]

## 3. A month more like ours

The village of version 4 had habits no real village has. Its shoppers haggled over every loaf. Its wages could halve in a year. Its villagers bought bread only once they were hungry. Its landowners sold a field for less than a year of its rent, and bought it back the same afternoon. Each habit left a mark on the results, and a reader was right to ask whether a finding belonged to the money or to the habit.

So the habits were replaced, one at a time, with what we see around us. Bread and services are sold at the price on the shelf. People buy this month's bread before they are hungry. A wage, once agreed, is not cut, though a newcomer may start lower. A day has its hours: sleep, the household, work, and what is left for an evening out. A farm sells most of its harvest to a bakery under a contract of six months. Land is bought for the rent it will bring. A firm is closed when it cannot pay what it owes, and one that can pay an overdue bill from its cash simply pays it.

Bread now ages. It sells at full price in the month it is baked, at seven tenths the month after, and in its third month the bakery gives it away. People who can afford fresh bread take the freshest. People who cannot take yesterday's at the lower price, and the free bread goes to those who have least, two loaves each at most.

\[ KADER  
**Two ladders, and how a rule earned its place.** The *standard* ladder keeps the simpler labour market of version 4 (anyone may be hired each month at the going wage). The *realistic* ladder adds contracts between a worker and an employer, wages that do not fall, and firms that plan on their own sales. Both run every village; they agree on every finding reported here unless the text says so.  
Rules were adopted on evidence from paired runs with the rule on and off (three steps of the ladder, both villages, four runs each), never on a single run. Kept: the wage floor, a year of storage for grain, the supply contracts, prices set against expected sales, bread priced by age. Rejected after testing: smaller price steps, a wider tolerance before a price moves, planning production on expected sales (it made output swing up and down from month to month), and charging the cost of stale bread to the price of fresh (with the rule in place a fifth of one village died).
\]

## 4. The ladder

As before, the village is built up one institution at a time, so that each step shows what one thing adds. The public reserve, step 10 of version 4, turned out to change nothing and was dropped; its number is left empty.

### Step 0. Bare bones

Farms, bakeries, a labour market and money. No government, no benefit, no rules beyond the market. In the debt village thirty-four people are alive after ten years. In the SuMSy village, four hundred and eighty-seven.

This is the harshest number in the report, and it is harsher than in earlier versions. The reason is the realism. With wages that do not fall and prices on the shelf, a villager without work has nothing to bargain with. In a village with no institutions at all, that is fatal. The SuMSy village survives on its guaranteed income, though one run in ten loses a third of its people.

\[ KADER  
**Step 0, ten-run means.** Alive: debt 34 (worst 25), SuMSy 487 (worst 323). On the standard ladder: 114 (88) and 468 (463). No public debt in either: there is no government.
\]

### Steps 1 and 2. Planning ahead, then a government

Let firms plan a month ahead and little changes: seventy-eight survive in the debt village. Add a government that taxes, pays a benefit and may borrow, and nearly everyone lives: five hundred and five. The benefit is what keeps them alive, and the government pays for it by borrowing, a hundred and ten thousand over the ten years. One villager in four is without work.

The SuMSy village keeps everyone and owes nothing. Its wealth is spread no more evenly than the debt village's at this step. Land is the reason, and §9 returns to it.

\[ KADER  
**Step 2, ten-run means.** Alive: debt 505 (worst 495), SuMSy 512. Public debt: 110,000 / 0. Without work: 124 / 12. Wealth Gini: 0.73 / 0.74. Bread: 5.98 / 7.21.
\]

### Steps 3 to 7. Interest, services, bonds

Interest on savings, the services sector, government bonds and a charge on the banks' idle reserves arrive in turn. None of them moves the picture much. The debt village keeps about five hundred and eight people and a public debt near a hundred thousand; the SuMSy village keeps everyone and owes nothing.

### Step 8. Owners, a stock market, and the land levy

Firms get owners and shares that trade. In the SuMSy village a levy on land arrives, and what it raises is paid out to every villager in equal parts. This is the step at which the two villages come apart, and the one on which they are compared in the rest of the report.

The debt village keeps five hundred and eight people and owes eighty-nine thousand. A hundred and twenty have no work. Its poorest tenth own nothing: on average a tenth of a meal each. The SuMSy village keeps everyone, owes nothing, has nobody without work, and its poorest tenth own twelve meals each. Wealth there is spread about twice as evenly.

\[ KADER  
**Step 8, ten-run means (realistic ladder).** Alive: debt 508 (worst 501), SuMSy 512. Public debt: 89,000 / 0. Without work: 120 / 0. Labour sold a villager a month: 2.65 / 2.69 units. Poorest tenth: 0.1 / 11.8 meals; gap between the richest and the poorest tenth: 288 / 72 meals. Wealth Gini: 0.76 / 0.36. Bread at year ten: 5.61 (+0.6 % a year) / 7.26 (+4.2 %). Firms wound up in ten years: 32 / 58. Services bought a villager a month: 5.4 / 24.9 hours. Dividends paid a month: 14 / 523. Land: 13 / 3.3 years of rent.  
**Standard ladder:** alive 510 / 512; public debt 77,000 / 0; without work 142 / 0; wealth Gini 0.81 / 0.34; poorest tenth −0.6 / 33.3 meals.
\]

### Step 9. Cooperatives

Turn the bakeries and farms into cooperatives owned by their workers and customers. The debt village hardly notices. The SuMSy village becomes the most equal of the ladder's main steps: its poorest tenth own thirteen meals, and the gap to the richest tenth is fifty-four.

\[ KADER  
**Step 9, ten-run means.** Alive: 508 / 512. Public debt: 88,000 / 0. Wealth Gini: 0.74 / 0.30. Poorest tenth: 0.6 / 13.1 meals; gap 265 / 54 meals. Without work: 122 / 0.
\]

### Step 11. A tax policy and a tax on bread

Give the government a rule that raises taxes when its debt grows, and a sales tax collected in the shop: six per cent on bread and twenty-one on services, as in Belgium. The debt village's public debt falls to fifty-two thousand, the lowest on its ladder. The cost falls on the people at the bottom: the poorest tenth now owe more than they own.

\[ KADER  
**Step 11, ten-run means.** Alive: debt 504 (worst 494), SuMSy 512. Public debt: 52,000 / 0. Poorest tenth: −1.6 / 11.3 meals. Wealth Gini: 0.81 / 0.35. Without work: 88 / 1.
\]

### A side step. The productive village

Suppose the village were three times as good at making things. In the SuMSy village the output of a villager rises to ten loaves' worth a month, the poorest tenth own sixty-four meals, and bread falls to a ninth of what it cost: a village that has enough lets its prices fall. In the debt village output a villager barely moves, from 2.3 to 2.8. The capacity is there and the money to buy what it could make is not.

The productive village is also where the SuMSy village is least equal, and where one of this version's rules does harm. Both are taken up below.

\[ KADER  
**The productive village, ten-run means.** Alive: 507 / 512. Output a villager: 2.84 / 10.08 loaves' worth a month. Public debt: 42,000 / 0. Poorest tenth: −1.8 / 63.8 meals. Wealth Gini: 0.79 / 0.54. Without work: 96 / 21. Bread: 0.88 / 0.82, falling about 10 % a year in both.
\]

### What the ladder says

Three things hold on every step from the second on, and on both ladders.

The SuMSy village carries no public debt. The debt village carries between forty and a hundred and thirty thousand, between half a year and a year and a half of everything it produces, and every policy that lowers it takes something from the people at the bottom.

Nearly everyone survives in both villages once there is a government. Survival is the debt village's benefit at work, paid for by borrowing.

From step 8 on, wealth is spread far more evenly in the SuMSy village. Before step 8 it is not. The money alone does not do it; the levy on land does, in a village whose money lets the levy be paid out rather than kept.

## 5. The same taxes in both villages

Version 4 asked whether the SuMSy village does better because of its money or because of the transfers that come with it, and could not answer. The fair test is to give both villages the same taxes and the same payments and see what difference is left.

Two packages were tried. In the first, both villages tax income, profits and dividends the way a European country does, and pay a benefit to those without work. In the second, both villages take the SuMSy route: a fee on money that sits idle, and a payment to everyone of what a meal costs.

Under either package, at steps 8 and 9, the SuMSy village is still far more equal. The gap between the villages barely narrows. Under the second package both villages improve, and the debt village improves a great deal: its poorest tenth go from nothing to seven meals each, and almost nobody is without work. It pays for that by borrowing more.

So the answer to version 4's question is: both, and they can be told apart. The transfers do a large part of the work, and a debt village can copy them. What it cannot copy is doing so without debt.

The productive village is the exception. There the second package brings the debt village almost level with the SuMSy village, whose own figure no package moves.

\[ KADER  
**Same rules in both villages, wealth Gini (ten-run means, realistic ladder).** Own rules → income-tax package → parking-tax package.  
Step 8: debt 0.76 → 0.60 → 0.52; SuMSy 0.36 → 0.22 → 0.17. Difference under the same rules: 0.38 and 0.35.  
Step 9: debt 0.74 → 0.48 → 0.49; SuMSy 0.30 → 0.18 → 0.13. Difference: 0.30 and 0.36.  
Productive village: debt 0.79 → 0.81 → 0.61; SuMSy 0.54 → 0.53 → 0.55. Difference: 0.28 and 0.06.  
**Debt village under the parking-tax package:** poorest tenth 6.9 meals at step 8 (0.1 under its own rules), 10.6 at step 9; without work 9 and 13 (120 and 122); public debt 92,000 and 122,000 (89,000 and 88,000). Under the income-tax package: public debt 29,000 and 40,000; without work 85 and 83; poorest tenth −1.8 and 0.2 meals. The SuMSy village owes nothing under any of the three.
\]

## 6. Work, and wanting work

A hundred and twenty people in the debt village have no work at step 8, and nobody in the SuMSy village. Version 4 read that as the SuMSy village creating jobs. It is not what happens.

Count the work that is actually done and the two villages are almost level: each villager sells about two and two-thirds units of labour a month, in both. The difference is in how much work people *offer*. In the debt village villagers offer nearly all the hours they have, because what they earn barely covers their bread. In the SuMSy village they offer two thirds, because the guaranteed income covers the bread and they work for the rest. The same number of jobs is shared among people who need them less.

The proof is in §5. Give the debt village a payment the size of a meal, and its people without work fall from a hundred and twenty to nine, with no more work being done than before.

There is one place where jobs really are missing. Villagers in the debt village buy five hours of services a month, and in the SuMSy village twenty-five. People who have nothing left after bread do not go out, and the businesses that would have served them are small.

\[ KADER  
**Work at step 8, ten-run means.** Labour offered as a share of capacity: debt 92 %, SuMSy 68 %. Labour sold a villager a month: 2.65 / 2.69 units. Villagers who offered work and sold none: 120 / 0. Services bought a villager a month: 5.4 / 24.9 hours. Under the parking-tax package the debt village has 9 without work at 2.55 units sold a villager.
\]

## 7. Who gets the profit

Earlier versions reported the SuMSy village at step 8 as considerably more equal than it is here. The difference is a correction, and an instructive one.

In the earlier village firms planned badly. They baked more than they sold, month after month, and what they wasted was their margin. When the planning was repaired, the waste stopped and the firms began to make a profit. A profit goes to the owners. In the SuMSy village at step 8 the firms pay out more than five hundred a month in dividends, against fourteen in the debt village, and the owners are the villagers who were already the best off.

So part of the earlier equality was firms throwing their margins away. The figure reported now, wealth spread about twice as evenly as in the debt village, is the one that holds when firms are run properly. It also shows something a design for money has to face: a parking fee on money does not reach the income from owning a business. A tax on dividends does, and under the first package of §5 the SuMSy village is about as equal as the earlier versions reported.

The productive village makes the same point from the other side. Where there is three times as much to earn, the owners earn it, and no package tried here changes that.

## 8. Prices, and a floor under wages

In version 4 both villages deflated, the SuMSy village by nine per cent a year. A reader asked what kind of village lets its wages fall by a tenth every year, and the honest answer was: none.

With wages that are not cut, the debt village's prices are steady, rising about half a per cent a year at step 8. The SuMSy village's rise by about four per cent a year. That is inflation, and it has to be said plainly: where version 4 found a village whose prices fell, this version finds one whose prices rise faster than a central bank would like. The floor under wages holds the price level up but does nothing else. With it or without it, the same people own the same share.

The productive village is the exception again: prices fall by a tenth a year in both villages, because a village that makes three times what it needs has to sell it somehow.

\[ KADER  
**Bread at year ten and its yearly change, ten-run means.** Step 2: 5.98 (+0.7 %) / 7.21 (+4.1 %). Step 8: 5.61 (+0.6 %) / 7.26 (+4.2 %). Step 11: 4.54 (−1.7 %) / 7.41 (+4.6 %). Productive village: 0.88 (−10.8 %) / 0.82 (−10.1 %). On the standard ladder, where wages may still be bargained down each month, the SuMSy village deflates 5 to 6 % a year. Two variants of the SuMSy village inflate by more than 20 % a year and are named in §12.
\]

## 9. Land

Land is where the two kinds of money differ most sharply, and where the SuMSy village needs its levy.

A field brings its owner a rent. What someone will pay for the field depends on what else they could do with the money. In the debt village money can be lent at interest, and a field sells for thirteen to twenty-six years of its rent, in the range land costs around us. In the SuMSy village money in an account loses a little every month, so anything that holds its value is worth more than it would be elsewhere. Without a levy, a field there sells for a hundred years of its rent. People flee from money into land, as Silvio Gesell warned a century ago that they would.

The levy ends that. With it, a field sells for three years of its rent, land stops being a place to hide wealth, and the proceeds, paid out to everyone, are the largest single reason the SuMSy village is more equal from step 8 on. A design that charges a fee on money and leaves land untaxed moves the hoarding from one to the other.

\[ KADER  
**Land, last-year means over ten runs.** Price of a plot in years of its rent: step 2, debt 26, SuMSy 100; step 8, debt 13, SuMSy 3.3. Plots sold a month: about one in the debt village, two in the SuMSy village at step 8. Land is bought for the rent it is expected to bring, each buyer with their own view of it; the chains of resale within a month that version 4's land market produced are gone.
\]

## 10. Yesterday's bread

Bread that is given away rather than thrown away is a small rule with a telling result. In the debt village the bakeries give away about twelve loaves a month at step 8, and none are thrown out: there is always someone who needs them. In the productive SuMSy village the bakeries throw away forty loaves a month and give away almost none. The rule is the same in both. In the SuMSy village almost nobody is poor enough to qualify.

The rule has a cost, and it is recorded here because it was adopted knowing it. In the productive debt village, the well-off take the freshest loaves, the bakeries see their older bread lose its value and bake a little less, and in a village where bread is already short for some, a few more go without. In four paired runs, seven fewer people were alive at the end on average, and in the worst of them thirty-three fewer. That is how stale bread is sold in the world, and the report keeps the rule and its cost together.

\[ KADER  
**Bread by age.** Full price in the month baked, 70 % the month after, given away in the third month, thrown away after that; grain loses 1 % of its value a month in storage. A villager buys fresh when, after paying, their money stays above two thirds of the cushion they aim for, or still ends the month higher than it began. Free bread goes to those who fail that test and lack a meal, poorest first, two loaves each at most. Last-year means, loaves a month: step 8, debt 12 given and 0 thrown away, SuMSy 8 and 8; productive village, debt 12 and 0, SuMSy 0 and 40. No tax is due on bread given away, as in Belgium since 2013 for food given to food banks.
\]

## 11. When the land belongs to everyone

One question was put to the village that version 4 only touched: what if the land is owned in common and the farms and households rent it from the village?

In the SuMSy village it works. Everyone survives and wealth is spread more evenly than on any step of the main ladder. In the debt village it kills. A hundred and forty people are alive after ten years. The ground rent takes between a fifth and a half of a household's income and goes into the government's account, where it pays off debt and comes back to no one. Hand the rent back to the villagers in equal parts and four hundred and eighty-five survive.

It is the clearest case in the report of a rule that is neither good nor bad in itself. The same public ownership feeds one village and starves the other, and the difference is whether the money that is collected goes round again.

\[ KADER  
**Land in public hands, ten-run means.** Ground rent kept by the government: debt 140 alive (worst 83), SuMSy 512. Rent handed back in full: debt 485 (worst 381), public debt 83,000. Half handed back: 473 (worst 430), public debt 17,000. No ground rent charged: 486 (worst 419). In the SuMSy village the wealth Gini with public land is 0.22.
\]

## 12. What this shows, and what it cannot

A village of five hundred and twelve people is not a country, and several things in this one are still wrong.

The debt village has far too many people without work: a quarter of the village, where Belgium has one in eighteen. §6 explains what the number means, and it remains a number no real economy shows.

Firms fail too often. In the SuMSy village at step 8 a firm is wound up every other month, mostly small firms that are refounded at once. None of the rules tried reduces it, and its cause is not yet known.

The debt village's output still swings a little from one month to the next in a way real economies do not. One cause was found and removed; a second remains.

Two variants of the SuMSy village inflate by more than twenty per cent a year: the one in which landowners pass the levy on to their tenants, and one other. A levy that is passed on in rents feeds prices, which feed rents. That is a real weakness of the design under that behaviour, not yet traced to its end. One variant of the greed tests runs to hyperinflation in both villages.

The tests of greed, hoarding and people who do not work for reasons of their own, which filled three sections of version 4, were run again and are not reported here. They need the same care the rest received and will come in a later version.

The numbers for Belgium that the village is tuned to are partly confirmed and partly provisional: the tax rates and the shares of spending are from official statistics; how much a household spends on services as its income rises is not yet.

And every finding here is a finding about these rules. Three of this version's conclusions overturned the last version's. The reader should expect the next version to do the same to some of these.

## 13. The ladder's answer, for policy makers

**The public debt is the debt village's price for keeping people alive.** Once there is a government, almost nobody starves in either village. The debt village borrows to achieve that; the SuMSy village does not. Every measure that cuts the debt, on this ladder, is paid for by the poorest tenth.

**Transfers do much of the work, and they can be copied.** A debt village that pays everyone the price of a meal has almost nobody without work and a poorest tenth who own something. It also owes more. The SuMSy village's advantage that remains under identical rules is that it gets there without debt, and with wealth spread about twice as evenly.

**Money that loses value needs a levy on land.** Without one, wealth moves from money into land, and a field costs a hundred years of its rent. With one, paid out to everyone, the SuMSy village becomes the more equal village. The levy is part of the design.

**A fee on money does not reach profits.** Where firms are run well, their owners gain, in either village. A tax on dividends closes most of that; nothing tried here closes it in a village three times as productive.

**The count of people without work measures need as much as jobs.** Both villages do the same amount of work. Before counting the unemployed, count the work done.

**Collected money has to go round again.** Ground rent that disappears into a government's account starves the village that pays it. The same rent, handed back, does not.

## Glossary

**Guaranteed income.** The monthly payment every SuMSy villager receives, newly made each month.

**Parking fee (demurrage).** The small monthly charge on money held in an account above a free amount, which takes out of the SuMSy village roughly what the guaranteed income puts in.

**Parking tax.** A further one per cent on the same money, on top of the fee, paid to the government; used in the second package of §5.

**Cushion (buffer).** The money a villager tries to keep in reserve before spending on anything but bread.

**Shortfall.** What a government spends beyond what it collects in a month; in the debt village it is borrowed and adds to the public debt.

**Public debt (government debt).** Everything the government has borrowed and not yet paid back.

**Step (rung).** One stage of the ladder: the village with one more institution than the step before.

**Land levy.** The SuMSy village's yearly charge on land, whose proceeds are paid out to all villagers in equal parts.

**Meal.** Two loaves at that month's price; the measure in which wealth is compared between villages whose prices differ.

**Services.** Everything the village sells that is not bread, bought with the hours a villager has free; the theatre of earlier versions.

**Settlement (clearing).** The moment each month at which invoices, wages, rents and taxes are paid.

**Wealth Gini.** A number between 0 and 1 for how unevenly wealth is spread: 0 if everyone owns the same, 1 if one person owns everything. Used only in the frames.
