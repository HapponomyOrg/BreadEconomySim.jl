# The Bread Economy

*What happens to a village when you change its money*

Version 4 — 13 October 2026 · published at https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm

← Previous report: [version 3, 21 September 2026](https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) (https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) · Next report: none yet

*This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred and twenty rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where it matters the worst run is mentioned as well. A round is best thought of as a month. There are five hundred and twelve villagers. "Alive" means alive at the end of the hundred and twenty rounds. All figures are from the run of 12 October 2026 (model version `2026-10-12`, 1,360 runs); where a single run is cited, the text says so.
\]

**What changed since version 3.** The village grew from sixty-four to five hundred and twelve people, so that the gap between rich and poor could be measured on a tenth of the village rather than on six people. Firms send invoices and pay them a month later, and a firm that cannot pay its bills is wound up. Land has a market, and the SuMSy village has a levy on it whose proceeds are paid out to everyone. Prices and wages move by rules calibrated to what we see around us, and the villagers work the way people do: for the work the village needs, for what they themselves need, and for the same employer month after month. And four questions were put to the village that version 3 could not answer: what the debt village's debt is the cost of; what happens to each money when prices are allowed to move; what full employment does; and whether a money that is created as debt can live in a village that has enough.

## 1. A village, twice

Imagine a village. Five hundred and twelve people live there. Some own land, most do not. Four farms grow grain, four bakeries turn it into bread, and later on four theatres give people something to do in the evening. Everyone needs two loaves a month. Go three months without any bread at all and you die.

Now imagine the same village built twice, with the same people, the same fields, the same ovens, the same habits, and one difference: where its money comes from.

In the first village, money is what it is for us today. It comes into being when a bank makes a loan and disappears again when the loan is paid back. Every euro in someone's pocket is a euro that someone else owes. The government pays for a few public jobs and a benefit of two loaves a month for people without work, and it pays for them by borrowing.

In the second village, every person receives a fixed sum of new money every month, whether they work or not. Money that sits idle above a modest cushion pays a parking fee: a small percentage each month simply disappears. On top of the fee, a smaller percentage of the same idle money goes to the government, which pays a few public jobs with it and a benefit of one loaf for people without work, half what the debt village pays, because the monthly income covers the other half. Once land is owned and traded, the government also levies a charge on land and pays the whole of it out, equally, to every villager. Nobody owes anyone for the money in their pocket.

The report builds the village up one piece at a time, and at every step asks the only question the village cares about: who still has bread? Then it does four things to the village that no step does. It holds every price still and asks whether the village can live without anyone ever raising a price. It lets prices move and watches what each money does with them. It makes the village productive enough to employ almost everyone, to see what the debt village's debt was for. And it has the government build something that pays back late, to see which money can wait.

## 2. Two kinds of money, in plain words

A loan creates money. When a bank lends a baker a thousand, it writes a thousand into the baker's account and a thousand into its own books as a debt owed to it. Nothing was there before. When the baker repays, both entries vanish. The money supply of the debt village is the sum of its outstanding loans, and it can only grow if someone, somewhere, borrows more.

A guaranteed income creates money too, but without the debt. Each month five new units appear in every villager's account. What keeps that from growing without end is the parking fee: whatever sits idle above the cushion loses two percent a month. A villager who holds a hundred and sixty above the cushion loses about as much to the fee each month as the income brings in, so there the balance settles. Add up all the villagers and you have the money supply of the SuMSy village, about a hundred and thirty thousand, fixed by two numbers that nobody borrowed.

One asymmetry between the villages is chosen, and it matters later. The debt village's benefit is two loaves at whatever bread costs; the SuMSy income is five units whatever bread costs, with one loaf of benefit on top for those without work. The first is protected against rising prices and feeds them; the second is not and cannot. (An earlier version of this village gave the SuMSy villagers the income alone. That kept everyone alive only as long as the village shared its work around; once employers kept their workers, as real employers do, the same people stayed out of work for years and an income of half a meal did not keep them alive. The one-loaf benefit is what it took, and a parking tax of 1.5 % pays for it.)

\[ KADER  
**The numbers.** Bank loans at 0.5 % a month to start, rising to at most 1.5 %; the government borrows at 0.5 %. Guaranteed income 5 a month; cushion 30; parking fee 2 % a month on money above the cushion; parking tax 1.5 % on the same base, on top of the fee; a benefit of one loaf a month for the unemployed; from step 8, a levy on land of the cost of holding money plus 0.25 % a month of the land's value, paid out per head. Starting prices: bread 5, grain 5.2, a unit of labour 3.92, a theatre ticket 2, a month's rent on a plot 0.75. A full-time worker (three units a month) earns 11.76 before tax; a month's bread costs 10.
\]

## 3. Who lives there

Five hundred and twelve villagers, of whom a hundred and twenty-eight own land, a plot and a half each. Four farms, four bakeries, two banks, and from step 4 on, theatres. Each firm is founded by four villagers who put up its working reserve from their savings, borrowing what they lack on business terms: a five-year loan, and only what they can carry. Nobody founds more than one firm, so the village has forty-eight owners.

The government hires up to a tenth of the village's capacity from whoever is left after the private markets, and pays the benefit: two loaves in the debt village, one in the SuMSy village. The banks lend, keep eight percent of their private loans as a reserve, and pay interest on deposits only out of what lending has earned them. In the SuMSy village the banks create no money at all: they lend their depositors' idle balances to whoever needs them, the government included, at a rate below zero, because lending beats the fee.

## 4. A month in the village

Each month the farms hire labour and grow grain; the bakeries buy grain, hire labour and bake; the villagers buy bread, and a ticket if they can afford one. Firms send each other invoices and pay them the following month. At the end of the month everyone's bills are settled against everyone else's, and whoever is short borrows, if a bank will lend, or sells land, or goes without.

A firm whose overdue bills reach a tenth of its monthly turnover and that can no longer borrow is wound up: its loans pass to its owners under their guarantee, its unpaid invoices are written off, and its ovens stand idle until someone with spare cash starts it again. When a whole kind of firm has gone, the last bakery say, the villagers with the most savings try to found a new one.

## 5. How the villagers decide

A villager works for three reasons, and the model holds all three. For the village: everyone offers at least their share of the labour the village's employers wanted last month, so that the bread gets made, and when last month's bread ran short, or employers could not find the hands they wanted, everyone offers everything they have until the ovens are staffed. No village starves for want of hands. For themselves: a villager who can afford it offers no more than a meal, the cushion and a night out require, with the income they receive without working counted in. And for the work itself: everyone offers at least half their capacity for paid work whatever their needs, and the hours they offer and nobody takes are given, unpaid, to the village as volunteer hours.

A seller who sold everything raises the price a little, one who sold too little lowers it, but only when the shortfall or the surplus is worth reacting to: a twentieth of the market, not a single loaf. A hungry buyer will pay up to a fifth over last month's price for bread, and no more than two loaves' worth for a seat at the theatre. An employer short of hands will bid up to a fifth over the wage paid last month. A worker in work will not take a cut of more than half a percent a month; a worker who lost the job bargains freely. Employers take on last month's workers before strangers, and a worker who has been with the same employer for six months cannot simply be dropped: the employer owes three months' notice, and pays for them. And when the village's bread ran short last month, nobody holds a floor: whatever keeps the ovens going is agreed.

Every one of these is a choice made by people in a context, and every one of them was once set wrongly in this model. Version 3 let hungry buyers pay double and let a full theatre pay its workers whatever its tickets brought in; an earlier draft of this version let every villager offer all their labour every month, whatever they needed, and hid for a week what that did to the people nobody hired. Every one of them is also the same in both villages: the same willingness to overpay, the same wish for a night out, the same reluctance to take a cut. That is a decision of this study, not a finding of it, and §16 says what it costs.

\[ KADER  
**The behavioural rules, with their values.** Prices move 6 % on a signal; the signal is 5 % of the market unserved or unsold. Buyers overpay up to 1.2×. A ticket is worth at most 2 loaves. Employers bid up to 1.2× the wage paid last month. The agreed wage of a worker in work last month falls at most 0.5 % a month; the floor lapses a month after a job and is suspended when last month's bread fell below 90 % of a meal each. Employers rehire their own workers first; three months' notice after six months' service. Firms hire at up to 10 % above what a unit of labour brings in. Each villager offers at least their share of last month's labour wanted plus 10 %, at least half their capacity, and everything when bread or hands fell short. Villagers aim for a meal, the cushion and one ticket a month.
\]

## 6. Why the rules matter more than the money — at first

Before the money system does anything at all, three rules decide whether the village lives: that bakers plan a margin above last month's sales, that a government exists to hire the idle and feed the rest, and that the work gets shared. The third is new to this version and it is the one that bites first. Feeding five hundred and twelve people takes about a thousand units of labour a month, a third less than the village can supply, and who does the work decides who eats.

Without a government the debt village keeps 150 people alive of five hundred and twelve, and the SuMSy village 458. The debt village's dead had no work and no money; the SuMSy village's had no work and half a meal of income, which lasts a cushion's worth of months. How much the village shares its work is a dial, and §7 turns it. From step 2, when a benefit exists, the SuMSy village keeps every one of its people at every step, in every run of ten. The debt village never does again: it keeps 509 at step 2, 482 at step 8, and 420 at step 11.

## 7. The ladder

The village is built up in twelve steps. Both villages climb the same ladder, and at every step we look at who is alive, what bread costs, what the government owes, and how far apart the richest and poorest tenth stand, measured in meals. Each step is named once for both villages; where a step adds something only the debt village can have (interest on deposits at step 3, the bond market at step 5), the SuMSy village is simply run again unchanged, so that the two stay side by side.

\[ KADER  
**The steps.** 0 bare bones · 1 planning ahead · 2 a government · 3 interest on savings · 4 theatres · 5 government bonds · 6 a charge on firms' idle reserves · 7 four theatres · 8 owners and a stock market, and in the SuMSy village the levy on land and its dividend · 9 (a side step) cooperatives · 10 a public reserve · 11 a tax policy and a tax on bread. Version 3's step 10, "prices that respond", is gone: the price rules are how people behave, not a policy, and from this version they apply from step 0.
\]

### Step 0. Bare bones

Fields, ovens, and no one to help. In the debt village most people find no work, and without work there is no money and without money no bread: 150 of five hundred and twelve are alive after ten years. In the SuMSy village 458 live. The ones who die are the ones the work does not reach: each villager offers their share of last month's labour and a tenth more, the tenth is what employers take from the people they already know, and about twenty villagers are left with half a meal of income and no job until their cushion runs out.

Turn the dial the other way and the village shares its work exactly: everyone offers their share and nothing over. Then 510 live and nobody is unemployed, and the labour market is tight every month, so that prices rise 5 % a year. Give the villagers a fifth over their share instead, and 424 live. A village that shares its work has no outsiders and no slack; a village with slack has outsiders. That is the whole of step 0, and it is the argument for what step 2 adds.

\[ KADER  
**Step 0, ten-run means.** Alive: debt 150, SuMSy 458 (worst run 453). The sharing margin, SuMSy: 0 % → 510 alive, bread 8.2 (+5.3 % a year), nobody unemployed; 5 % → 478; 10 % (the ladder) → 458, bread 5.3; 20 % → 424. Unemployed at month 120: debt 18, SuMSy 22. The rich–poor gap at this step is land without a levy and is not quoted (§12).
\]

### Step 1. Planning ahead

The bakers plan a margin above last month's sales. It helps a little and changes nothing that step 2 does not change more.

### Step 2. A government

Public jobs for a tenth of the village, and a benefit: two loaves in the debt village, one in the SuMSy village. Now the SuMSy village keeps everyone, and keeps everyone in work: with the benefit counted as income and the work shared, every villager offers what the village needs and finds it taken. The debt village keeps 509; 152 of them, three in ten, have no work.

In the debt village that costs the government about a thousand a month more than it collects, every month, for ten years; it borrows the difference, and by year ten owes 200,000. The SuMSy government borrows too, once. While its money is still filling up the village, the parking tax brings in little, and it borrows its citizens' savings: about 4,800 at the worst point, in the fifth month. Then it pays every unit back, by month 32 in every run of ten. A startup cost, paid once; the debt village's deficit is paid every month.

\[ KADER  
**Step 2, ten-run means.** Alive: debt 509, SuMSy 512. Unemployed: 152 / 0. Public debt at year 5 → year 10: debt 96,000 → 200,000; SuMSy 0 (peak 4,850 in month 5, repaid by month 32 in 10 runs of 10). Taxes against spending in the last year: debt 11,300 / 23,300; SuMSy 13,600 / 1,300. Bread at month 120: 4.5 / 1.8.
\]

### Steps 3 to 7. Interest, theatres, bonds, a charge on idle reserves

Interest on savings, two theatres, then four; bonds so that the debt village's government can borrow from its citizens instead of its bank; a monthly charge on firms' idle reserves in both villages. None of it changes who eats. Two things do change. The bonds move the debt village's public debt from the bank's books to the villagers' savings and shrink its money supply by more than half; the debt itself grows as before, to 169,000 at step 5. And the theatres in the debt village keep failing, 33 windings-up in ten years at step 5 against none in the SuMSy village, and what happens to a failed firm's loans turns out to matter more than the theatres (§11). The SuMSy village sells 634 tickets a month at step 5 to the debt village's 269.

### Step 8. Owners and a stock market, and the land dividend

Firms get owners, and shares that trade; and in the SuMSy village the levy on land arrives with its dividend. The debt village keeps 482 and owes 140,000; 113 villagers have no work. The SuMSy village keeps 512, owes nothing, has nobody out of work, and pays every villager about seven a month from the levy on top of the income, more than the income itself.

This is the step on which the two villages are compared throughout the rest of the report, and the comparison is in the frame. One number in it needs its context: the debt village's bread costs 3.5 at year ten and the SuMSy village's 2.0. Both villages deflate; the SuMSy village deflates faster, 9 % a year, because its people work two units in three and spend no more than they need. A village that has enough, and knows it, lets its prices fall. What that does to a debt is in §9.

\[ KADER  
**Step 8, ten-run means.** Alive: debt 482 (worst 469), SuMSy 512. Unemployed: 113 / 0. Bread: 3.5 (−3.7 % a year) / 2.0 (−9.2 %). Public debt at year 5 → 10: 83,000 → 140,000 / 0. Firms wound up: 32 / 0. Rich–poor gap, poorest tenth: 571 meals, 0.9 / 242 meals, 16.3. Tickets a month: 160 / 640. The dividend: 3,650 a month, 7.1 a villager. Land: a plot trades at 350 in the debt village and 43 in the SuMSy village, against a monthly rent of 1 in both (§12).
\]

### Step 9, a side step. Cooperatives

Half the firms as cooperatives, open to anyone at par, with the same dividend for every member. In the SuMSy village they take the gap from 242 to 166 meals and lift the poorest tenth to 20 meals, and cost nobody their bread. In the debt village they change almost nothing.

### Step 10. A public reserve

The government keeps a reserve and cuts taxes when it has more than it needs. In the SuMSy village the surplus is paid out as the dividend instead, so this step is step 8 again; in the debt village there is never a surplus to keep.

### Step 11. A tax policy and a tax on bread

The government raises every tax when it is short and lowers them when it is not, and a tax on bread and tickets is among them. In the debt village the tax on bread does what no other rule in this report does: it kills. 420 of five hundred and twelve are alive after ten years, 366 in the worst run, and the poorest tenth is under water by four and a half meals. The public debt is a fifth of what it was, which is the point of the policy, and it has been paid in people. The SuMSy village, where the parking tax is the only tax and it is never short, is unchanged: 512 alive, nobody out of work, the poorest tenth holding eighteen meals.

### What the ladder says

Two villages, the same at every step but one. The debt village lives from step 2 on because its government borrows, every month, and never stops; a third of its people have no work at every step; and the one policy that brings its debt down costs it ninety lives. The SuMSy village lives from step 2, borrows once, repays within three years, and from step 2 on has no unemployment at all. Everything else on the ladder, the theatres, the bonds, the shares, the reserve, moves the figures a little and the story not at all. What moves the story is in the next five sections, and none of it is a step: it is what happens when prices are allowed to move, when they are not, and when the village finds work for its idle third.

\[ KADER  
**The ladder, ten-run means, alive / unemployed / public debt / poorest tenth in meals.** Step 2: debt 509 / 152 / 200,000 / 1.1; SuMSy 512 / 0 / 0 / 28. Step 5: 502 / 108 / 169,000 / 0.8; 512 / 0 / 0 / 3.9. Step 8: 482 / 113 / 140,000 / 0.9; 512 / 0 / 0 / 16.3. Step 11: 420 / 77 / 39,000 / −4.6; 512 / 0 / 0 / 18.5. Co-ops (B): 491 / 112 / 148,000 / 2.7; 512 / 0 / 0 / 20.2. The SuMSy poorest tenth at steps 2–7 is measured before the levy, when land is hoarded; it is quoted, the gap is not.
\]

## 8. What the debt is for

Hold every price in the village still. Not one baker raises the price of a loaf, not one worker asks for more, for ten years; only the amounts change. Can the village live? It can, in both moneys: 509 live in the debt village and everyone in the SuMSy village, and the SuMSy village has nobody out of work.

And the debt village's government still borrows about 1,500 a month, every month, for the whole ten years. With no inflation whatsoever its debt grows in a straight line, from 94,000 at year five to 186,000 at year ten. The SuMSy government owes nothing. So the deficit is not a price phenomenon. It is the money needed to feed the third of the village that has no work, 135 people at this step, and in a village whose money is someone's debt that money has to be borrowed into existence every month. In the SuMSy village the same people are in work, because the work is shared and the income counts, and what they still lack is paid as the dividend. Nobody borrows it.

\[ KADER  
**Fixed prices, step 8 (P8), ten-run means.** Alive: debt 509, SuMSy 512. Unemployed: 135 / 0. Public debt at year 5 → year 10: debt 94,000 → 186,000; SuMSy 0. Money supply: debt 52,000, SuMSy 130,000. Rich–poor gap, poorest tenth: 281 meals, 0.7 / 44 meals, 11.7.
\]

## 9. What prices do with the debt

Now let prices move, by the rules of §5. The same deficit shows a different face, and which face depends on things people choose: how much they will overpay when bread is short, and how the labour market treats the people in it.

**When people can overpay and nothing holds them back,** the borrowed money chases the same bread. Version 3's village, where a hungry buyer paid double and a full theatre paid any wage, ran at fifteen percent a year and more. This version's village overpays by a fifth at most, and the dial still shows: at step 2 the debt village's debt is 170,000 if buyers will pay a tenth over, 200,000 at a fifth, 234,000 at double.

**When wages fall where work is scarce,** the debt village deflates. A fifth of its people idle, wages that fall each time someone loses a job, bread that goes unsold: prices drop 3.7 % a year at step 8 and 12 % at step 11. The debt does not fall with them. Every unit of it weighs more as prices fall, and by year ten the village owes, in loaves of bread, thirteen times what it owed at the end of the first year. That is the debt deflation Irving Fisher described in 1933, and the village walks into it with its books in better order every year.

**The SuMSy village deflates faster**, 9 % a year at every step from 2 on, and owes nothing, so the fall costs it nothing. Its people are all in work, work two units in three, and want no more; the bread they do not want goes down in price until the bakers plan for less of it. A village that has enough lets its prices fall, and a money that is not a debt can afford to let them.

Three labour rules decide the sign, and none of them is the money's. Take the notice period away, so that a worker can be dropped the month a cheaper one appears, and the SuMSy village *inflates*, 10 % a year, to a bread price of 12: the wage level is renegotiated every month in a market where everyone is wanted, and it climbs. Let the villagers offer exactly their share of the work and no more, and it inflates 4 % a year, because the market is tight every month. Let employers take the cheapest hands instead of their own, so that every job is renegotiated from scratch, and it inflates 17 % a year, with nobody hungry and nobody idle through all of it. With the notice period and a tenth of slack, wages are held and prices fall. The rules meant as realism turn out to decide whether a sufficiency village deflates or inflates, and the report leaves it at that: the sign is the labour market's, the stability of the village is the money's, since nobody dies and nobody is idle either way. Every price in this report is quoted under the ladder's settings, a tenth of slack and the notice period.

\[ KADER  
**Prices a year, ten-run means.** Overpay up to 1.1× / 1.2× / 2× at step 2 (debt): bread 3.5 / 4.5 / 5.4 at year ten, debt 170,000 / 200,000 / 234,000. Step 8: debt −3.7 %, SuMSy −9.2 %; step 11: −12 % / −9.7 %. Without the notice period (Y8): debt −1.3 %, SuMSy +9.1 % (bread 11.2, gap 69 meals). Without employers' loyalty, every job up for grabs each month (Y8): debt 501 alive, −5.4 %, public debt 103,000; SuMSy +17 % a year (bread 22), nobody unemployed or hungry. With the sharing margin at 0 instead of 10 % (M8-0): SuMSy +3.8 % a year (bread 7.5), gap 126 meals. The wage floor lasting three months instead of one (Y8): no change in either village. The debt village's public debt in loaves at year 10 against year 1: 13.4× at step 8, 16.6× at step 11.
\]

## 10. Full employment

The debt village has work for two thirds of its people, because the villagers want a meal, a cushion and a night out, and once bread takes half the labour there is nothing more they ask the village to make. To employ the rest we gave it what every real economy that employs its people has: bread cheap enough to leave money over, a service that absorbs labour and covers its costs, people who want two nights out a month instead of one, and firms that come back when they fail.

The SuMSy village then employs everyone, as it did before, and sells 850 tickets a month. The debt village employs 72 % of its people, no more than at step 8: the theatres it needs for the rest fail 138 times in ten years, because their audience cannot pay, and each failure leaves a written-off loan and a bailout behind (§11). Its budget comes nearer to balance, taxes covering four fifths of spending in the last year, and its debt levels off at 73,000. That is as close as the debt village comes to living within its means, and it has a hungry month in year ten with fifteen people in it and a poorest tenth three meals under water.

Give the debt village full employment through public jobs instead, forty percent of the village on the public payroll at fixed prices, and nobody is unemployed and the debt grows faster than ever, 205,000 at year ten. Make the government raise taxes until that budget balances, and 197 of five hundred and twelve are alive. The SuMSy village under the same rule keeps everyone and owes nothing. A job the government cannot pay for feeds no one.

\[ KADER  
**The productive village (V8): four loaves a grain, bread at 3, theatres needing a worker per customer at a ticket of 5, two tickets a month wanted, failed theatres restarted. Fixed prices, ten-run means:** alive debt 492 / SuMSy 512; unemployed 141 / 0; public debt 40,000 → 73,000 / 0; firms wound up 138 / 0; taxes against spending 12,000 / 14,800; poorest tenth −3.0 / 4.9 meals. **Public jobs 40 % at fixed prices (U8, UP8):** debt 512 alive and 205,000 of debt; with taxes raised until the budget balances, 197 alive (147,000 of loans written off), SuMSy 512, no debt, gap 42 meals, poorest tenth 12.1.
\]

## 11. Where the debt village's money comes from when no one borrows

Why do the debt village's theatres keep failing, and why does it matter? A theatre that cannot cover its wages goes under; its loans are written off; the money those loans created stays in circulation with no debt behind it; and the bank's loss is made good by a government that borrows to do so. Then someone with savings starts the theatre again, and the cycle repeats. At step 8 the debt village writes off 34,500 of loans in ten years, bails out its banks for 3,400, winds up 32 firms and restarts 21; in the productive village 138 firms are wound up and 43 restarted. In the SuMSy village the same theatres never fail: every villager has the income and the dividend to spend on a seat, and the theatres sell four seats where the debt village's sell one. No loan creates money there, so no default creates any either, and there is nothing to bail out.

Three rules were tried on the banks because of this, and the report keeps all three: banks pay interest on deposits only from what lending has earned, above an eight percent reserve; a failed firm's bank loans pass to its owners, who are written off after six months if they can pay nothing; and the government stands behind the banks only where there is a government. The second changed almost nothing: the owners have no more than the firm had.

\[ KADER  
**Bailouts and write-offs, ten-run means, month 120.** Step 5: debt bailouts 22,400, loans written off 32,800, firms wound up 33, restarted 22; SuMSy 0 / 0 / 0 / 0. Step 8: 3,400 / 34,500 / 32 / 21; SuMSy 0 / 0 / 0 / 0. V8: 1,100 / 13,100 / 138 / 43; SuMSy 0. UP8: 147,000 written off. Tickets a month at step 8: 160 / 640.
\]

## 12. Land

Land is the one thing money does not price the same way in the two villages. In the debt village a plot is worth its rent capitalised at what a deposit earns: about 350 at step 8, against a rent of 1 a month, and it changes hands at that. In the SuMSy village money that loses value is never a reason to sell land, so nobody sells, and the rare plot that comes to market goes for whatever the richest bidder has: 6,200 at step 8 without a levy, some 9,000 months' rent, with every plot in household hands. Silvio Gesell saw this a century ago and paired his melting money with a levy on land. The village confirms him. With a levy on land set to the cost of holding money plus a small margin, and the proceeds paid out to every villager as a dividend, land trades at 43, a fifth of the debt village's price, a fifth of it moves to the farms that work it, the government owes nothing, and the dividend is larger than the income itself.

Three things follow. Without the levy, the SuMSy village's rich–poor gap in meals measures the land price and nothing else (10,000 meals at step 8 against 242 with the levy), and this report quotes the SuMSy gap only where the levy is in place; before step 8 it quotes the poorest tenth alone. The levy must never be cut: three different rules in this model's history cut it when the government had a surplus, and each time land froze within months. And the levy and the dividend together answer a question the SuMSy village had: with them paid out, the long-term unemployed need no benefit at all, which is what the dividend is.

\[ KADER  
**Land, month 120, ten-run means.** A plot's price, debt / SuMSy with levy and dividend / SuMSy without: 350 / 43 / 6,200, against rents of 1.0 / 1.0 / 0.7. Land held by households: 100 / 80 / 100 %. Rich–poor gap, poorest tenth: 571, 0.9 / 242, 16.3 / 9,997, 3.9. With the levy and dividend from step 2 (L2): gap 73, poorest tenth 21. The levy: parking fee + parking tax + 0.25 % a month of the land's value; the dividend: the whole surplus, paid per head.
\]

## 13. Three policies, tried

**Austerity.** From year five the debt village's benefit falls from two loaves to one over six months. The debt grows at half its pace, 30,000 over the last five years instead of 57,000, and in the last year taxes cover the spending. Thirty-eight more villagers die, sixty-one are hungry at the worst month after the cut, and the poorest tenth ends under water. Prices fall faster, so the debt that remains weighs more. The books look better; the village is poorer in every real measure.

**A ceiling on public debt.** The government cuts its spending whenever its debt exceeds a year's output. At one year's output 390 of five hundred and twelve are alive and the debt still grows; at half a year's, 295. A debt ceiling in a village whose debt is the cost of its unemployment is a rule to starve the unemployed.

**The parking fee as a lever.** A higher fee lowers the money each SuMSy villager settles at, and with it the price level, so that the same guaranteed income buys more bread. At three or four percent, with starting prices to match, the money supply falls from 135,000 to 75,000, the gap from 283 to 161 meals, and nobody dies at any setting. It is the SuMSy village's monetary policy, and it works on the distribution without touching anyone's bread.

\[ KADER  
**Austerity (A8), ten-run means:** alive 444 against 482; public debt at year 5 → 10: 82,000 → 112,000 against 83,000 → 140,000; hungry at the worst month after year 5: 61 against 7; poorest tenth −0.8; prices −5.4 % a year against −3.7 %. **The debt ceiling (D8):** at 1× yearly output 390 alive, debt 105,000, 73 hungry at the worst month; at 0.5× 295 alive, debt 63,000. **The fee (F8), SuMSy village started at its full money stock, 2 / 3 / 4 %:** 512 alive at each; money 135,000 / 95,000 / 75,000; gap 283 / 196 / 161 meals; poorest tenth 16 / 12 / 11.
\]

## 14. A public investment

Governments build things that pay back late or never, and the village was given one: a public transport line. For five years, five percent of the village's labour works on it at the public wage, and nothing comes back. Then the same workers run it, and every villager wants one ride a month, bought if there is money left after bread, at half a loaf a ride. The fares are the government's.

The villages build it at a similar cost. What they earn from it differs by the same thing that runs through this report: who can pay. In the SuMSy village 489 villagers ride each month and 23 cannot afford to, and within five years of opening the line has paid for itself with half as much again to spare. The government borrowed its citizens' savings to build it and paid them back within the first year. In the debt village 161 ride and 320 cannot afford to, and the line has earned back seven tenths of its cost by year ten. Its government's debt ends lower than without the line all the same, 106,000 against 140,000, because the line's jobs cost it less than the idle cost it in benefits, and 30 fewer villagers are out of work. In both villages the line employs people; only in one can they ride it.

A public service earns its keep where the public can pay. That is a sentence about demand, and in this village the guaranteed income and the dividend are what give the public the means.

\[ KADER  
**The public transport line (T8), ten-run means.** Building and running cost over ten years: debt 30,600, SuMSy 20,000. Fares by month 120: 22,100 / 31,400. Rides a month at the end: 161 / 489; villagers unable to afford one: 320 / 23. Unemployment with and without the line: debt 83 / 113, SuMSy 0 / 0. Public debt at month 120 with and without: debt 106,000 / 140,000, SuMSy 0 / 0 (655 borrowed in the first months, repaid by month 9). Settings: 5 % of capacity for 60 months at the public wage, then operating; fare half a loaf; one ride a month wanted per villager.
\]

## 15. Greed, hoarding, and the people who do not work

Make a quarter of the villagers greedy and the SuMSy village still feeds everyone; make all of them greedy and the whole village dies, in ten runs of ten, by year seven on average: greedy buyers bid land to six times its price in the first month and the village's money ends in the hands of those who hold it. That is what the stress test is for, and it is the one SuMSy result on the ladder with mass death after step 2. The debt village under the same greed keeps 255. Make one villager in a hundred a hoarder, and nothing measurable happens in either village: the gap and the poorest tenth are as at step 8.

Give the village gold, a hundred grams a head, held at the start by the richest tenth, yielding nothing and costing nothing to keep, and the two moneys answer differently. Under debt money a gram ends at 68, twenty loaves; under SuMSy, where idle money loses value and gold does not, at 1,750, nine hundred loaves, twenty-five times as much, and the richest tenth still hold all of it. That is where a SuMSy village's spare money goes when it can go nowhere else. It changes nobody's bread: gold feeds no one and turns into bread only if someone pays money for it, which is why this report keeps gold out of its measures of wealth and reports it beside them. Land is different, because land yields; gold is a bet on the next buyer, and the village can let those who want it have it.

Make five villagers in a hundred people who do not work, for reasons the model does not ask about, care, illness, art, or choice, who take paid work only to eat, and some only once hungry. In the SuMSy village all twenty-six live, on the income and the dividend, without working. In the debt village twenty-four of them die: they are outsiders in a labour market where employers keep their own, and the benefit, which falls over time to one loaf, does not carry them. A money that pays everyone carries those who do not work; a money that does not lets them starve.

Lastly, a premium loaf: the same bread at five times the price, for whoever has money to spare, baked with extra hands. It is the village's version of what real economies do when their people want no more things, which is to sell them dearer ones. In the debt village a few are sold each month and the debt is *higher* for it, 161,000 against 140,000, because the extra wages are borrowed like all the rest and few can pay the price. In the SuMSy village none are sold at all: the villagers keep a month's bread in the cupboard and buy ahead, and a dearer loaf finds no one in need of one. Growth in value without growth in volume needs a public with spare money and an empty cupboard, and neither village has both.

\[ KADER  
**Ten-run means.** Greed: a quarter greedy (S1) SuMSy 512 alive; everyone greedy (S3) SuMSy 0 alive in 10 runs of 10 (mean death in month 84), debt 255. The 1 % hoarders (H8): debt 485 alive, gap 524, poorest tenth 0.8; SuMSy 512, 243, 15.5 — as step 8. Gold (R8): price 68 / 1,751, holders 226 / 173 of whom the richest tenth hold 100 % of the grams in both; without the levy (RZ8) 2,685. Not working (Q8): debt 458 alive against 482; SuMSy 512. The premium loaf (K8): debt 492 alive, 16 premium loaves a month, debt 161,000; SuMSy none sold. In the productive village (KV8): debt 73,000 either way.
\]

## 16. What this shows, and what it cannot

It shows a village in which the money that feeds the idle third is borrowed every month, and what that borrowing becomes when prices can move: inflation if people will overpay and no one holds them back, deflation under a fixed debt if they will not and wages fall. It shows another village in which the same money is paid as an income and a dividend, owes nothing in steady state, repays the one debt it incurs within three years, and from the moment it has a benefit has no unemployment at all, because its people work for the village, for themselves and for the work, and the money lets them stop when there is enough. It shows that the debt village balances its books only with prices held still and its people made to want more, and loses people whenever it tries to balance them otherwise: by tax, by austerity, by a ceiling. It shows that a public investment pays for itself where the public can pay, that a theatre survives where its audience can afford a seat, and that a dearer loaf is no way out. It shows which rules killed: the tax on bread, the debt ceiling, the full-house theatre allowed to set the village's wage, a labour market that keeps insiders and forgets the rest.

It cannot show what a real economy does, with a thousand goods, foreign trade, a central bank, and people who want more than two nights out. And it rests on one assumption that runs through every comparison in it: that people behave the same way under SuMSy as they do under the money we have. The villagers of both villages overpay the same when bread is short, hoard the same when they have spare money, want the same night out, and refuse the same wage cut. They may not. A person whose income arrives every month without fail, and whose savings melt if left idle, may hoard less, lend more freely, work for other reasons, or price what they sell differently; nobody knows, because no such village exists to ask. This report holds behaviour fixed so that whatever differs between the villages can be laid at the money's door. Where behaviour would differ, the comparison is only a starting point.

One more thing it cannot show is how much of what it shows is the labour market's rather than the money's. The village's people work for the village, for themselves and for the work; take any of the three away and the results move, in both villages. An earlier draft of this report, with villagers who offered all their labour whatever they needed, had a SuMSy village with a fifth of its people out of work and a debt village with a third. The money did not change between the drafts; the rule did. The reader should take the differences *between* the villages as the money's, and the levels in either as the village's.

## 17. The ladder's answer, for policy makers

Most of what governments argue about, tax rates, interest rates, the coupon on their bonds, the reserve their banks must hold, moved this village very little. What moved it was the plumbing: whether money is a loan or an income, whether land can be hoarded, whether the idle can be customers, whether the work is shared. A debt-money village can balance its books at full employment and fixed prices, and only there, and it gets to full employment only by making its people want more than they need. The rest of the time it chooses between a debt that grows, prices that fall under it, and people left without income. A village whose money is paid as income has none of those choices to make, and what it has instead is a labour market to design: who works, for whom, and for how long, which this report has only begun to turn.

## Glossary

**Bailout.** The government putting money into a bank whose losses have eaten its equity, so that depositors are not hurt. In the debt village the government borrows to do it.

**Benefit.** Two loaves a month, at the going price of bread, paid by the debt village's government to anyone without work; one loaf in the SuMSy village, on top of the income.

**Capital reserve.** The eight percent of its private loans a bank keeps as its own money, as the Basel accords require. Loans to the government need none.

**Cooperative.** A firm owned by its members, who join by buying one share at par and receive the same dividend each.

**Cushion.** The thirty units every villager keeps before spending on anything beyond bread. Under SuMSy, money up to the cushion pays no parking fee.

**Debt ceiling.** A rule that cuts public spending whenever the public debt exceeds a set multiple of the village's yearly output.

**Deflation.** Prices falling across the village, year after year. The debt it leaves behind is fixed in money, so it grows heavier in bread.

**Guaranteed income.** Five units of new money a month, paid to every villager in the SuMSy village whether they work or not.

**Invoice.** A firm's bill to another firm, paid the following month. A firm whose overdue invoices reach a tenth of its monthly turnover, and that can no longer borrow, is wound up.

**Land dividend.** What the SuMSy government pays out to every villager, equally, from the levy on land: the whole of it, every month.

**Levy on land.** A monthly charge on the value of land, set at the cost of holding money plus a small margin, so that land is no better a store of value than money.

**Money that someone owes.** In the debt village every unit of money was created by a loan and is matched by a debt; repaying the loan destroys the money.

**Notice.** Three months' pay owed to a worker who has been with the same employer for six months and is no longer wanted.

**Owners' guarantee.** When a firm is wound up, its bank loans pass to its owners in proportion to their shares. An owner who pays nothing for six months is written off.

**Parking fee.** Two percent a month of a SuMSy villager's money above the cushion, which simply disappears. It is not a tax: nobody receives it.

**Parking tax.** One and a half percent a month on the same money, paid to the SuMSy government. Its only tax.

**Rich–poor gap.** The holdings of the richest tenth of villagers less those of the poorest tenth, measured in the meals they would buy, with land and shares counted and gold left out. It is always given with the poorest tenth's own holding, because a small gap can mean that the poor have something or that nobody has anything.

**Sharing margin.** How much labour a villager offers over their share of what the village's employers wanted last month: a tenth on the ladder, and the dial of step 0.

**Startup cost.** The SuMSy government's one debt: what it borrows from its citizens while the new money is still filling up the village, and repays once the parking tax covers its spending.

**Volunteer hours.** The labour a villager offered and nobody took, given unpaid to the village. In the SuMSy village from step 2 on there are none, because every offered hour is taken.

**Winding up.** What happens to a firm that cannot pay its bills: its assets are sold, its loans pass to its owners, its unpaid invoices are written off, and its ovens stand idle until someone starts it again.
