# The Bread Economy

*What happens to a village when you change its money*

Version 4 — 13 October 2026 · published at https://claude.ai/artifact/SmdB6uUn41n8SLyrWMqiXm

← Previous report: [version 3, 21 September 2026](https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) (https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) · Next report: none yet

*This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred and twenty rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where it matters the worst run is mentioned as well. A round is best thought of as a month. There are five hundred and twelve villagers. "Alive" means alive at the end of the hundred and twenty rounds. All figures are from the run of 17 October 2026 (model version `2026-10-17.0`, 1,910 runs); where a single run or an earlier run is cited, the text says so.
\]

**What changed since version 3.** The village grew from sixty-four to five hundred and twelve people, so that the gap between rich and poor could be measured on a tenth of the village rather than on six people. Firms send invoices and pay them a month later, and a firm that cannot pay its bills is wound up. Land has a market, and the SuMSy village has a levy on it whose proceeds are paid out to everyone. Prices and wages move by rules calibrated to what we see around us, and the villagers work the way people do: for the work the village needs, for what they themselves need, and for the same employer month after month. And four questions were put to the village that version 3 could not answer: what the debt village's debt is the cost of; what happens to each money when prices are allowed to move; what full employment does; and whether a money that is created as debt can live in a village that has enough. And a reader asked a fifth, which §16 answers: whether it is the money that keeps the SuMSy village alive, or what the money pays for.

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

Every one of these is a choice made by people in a context, and every one of them was once set wrongly in this model. Version 3 let hungry buyers pay double and let a full theatre pay its workers whatever its tickets brought in; an earlier draft of this version let every villager offer all their labour every month, whatever they needed, and hid for a week what that did to the people nobody hired. Every one of them is also the same in both villages: the same willingness to overpay, the same wish for a night out, the same reluctance to take a cut. That is a decision of this study, not a finding of it, and §17 says what it costs.

\[ KADER  
**The behavioural rules, with their values.** Prices move 6 % on a signal; the signal is 5 % of the market unserved or unsold. Buyers overpay up to 1.2×. A ticket is worth at most 2 loaves. Employers bid up to 1.2× the wage paid last month. The agreed wage of a worker in work last month falls at most 0.5 % a month; the floor lapses a month after a job and is suspended when last month's bread fell below 90 % of a meal each. Employers rehire their own workers first; three months' notice after six months' service. Firms hire at up to 10 % above what a unit of labour brings in. A firm near failure with goods left unsold cuts next month's production to what it sold. A firm whose owners are greedy prices on a sell-out at what buyers will pay; a firm whose overdue bills reach half of what would wind it up abandons the step limit and prices to clear them. Each villager offers at least their share of last month's labour wanted plus 10 %, at least half their capacity, and everything when bread or hands fell short. Villagers aim for a meal, the cushion and one ticket a month.
\]

## 6. Why the rules matter more than the money — at first

Before the money system does anything at all, three rules decide whether the village lives: that bakers plan a margin above last month's sales, that a government exists to hire the idle and feed the rest, and that the work gets shared. The third is new to this version and it is the one that bites first. Feeding five hundred and twelve people takes about a thousand units of labour a month, a third less than the village can supply, and who does the work decides who eats.

Without a government the debt village keeps 153 people alive of five hundred and twelve, and the SuMSy village 458. The debt village's dead had no work and no money; the SuMSy village's had no work and half a meal of income, which lasts a cushion's worth of months. How much the village shares its work is a dial, and §7 turns it. From step 2, when a benefit exists, the SuMSy village keeps every one of its people at every step, in every run of ten. The debt village never does again: it keeps 510 at step 2, 488 at step 8, and 437 at step 11.

## 7. The ladder

The village is built up in twelve steps. Both villages climb the same ladder, and at every step we look at who is alive, what bread costs, what the government owes, and how far apart the richest and poorest tenth stand, measured in meals. Each step is named once for both villages; where a step adds something only the debt village can have (interest on deposits at step 3, the bond market at step 5), the SuMSy village is simply run again unchanged, so that the two stay side by side.

\[ KADER  
**The steps.** 0 bare bones · 1 planning ahead · 2 a government · 3 interest on savings · 4 theatres · 5 government bonds · 6 a charge on firms' idle reserves · 7 four theatres · 8 owners and a stock market, and in the SuMSy village the levy on land and its dividend · 9 (a side step) cooperatives · 10 a public reserve · 11 a tax policy and a tax on bread. Version 3's step 10, "prices that respond", is gone: the price rules are how people behave, not a policy, and from this version they apply from step 0.
\]

### Step 0. Bare bones

Fields, ovens, and no one to help. In the debt village most people find no work, and without work there is no money and without money no bread: 153 of five hundred and twelve are alive after ten years. In the SuMSy village 458 live. The ones who die are the ones the work does not reach: each villager offers their share of last month's labour and a tenth more, the tenth is what employers take from the people they already know, and about twenty villagers are left with half a meal of income and no job until their cushion runs out.

Turn the dial the other way and the village shares its work exactly: everyone offers their share and nothing over. Then 510 live and nobody is unemployed, and the labour market is tight every month, so that prices rise 5 % a year. Give the villagers a fifth over their share instead, and 424 live. A village that shares its work has no outsiders and no slack; a village with slack has outsiders. That is the whole of step 0, and it is the argument for what step 2 adds.

\[ KADER  
**Step 0, ten-run means.** Alive: debt 153, SuMSy 455 (worst run 453). The sharing margin, SuMSy: 0 % → 510 alive, bread 8.2 (+5.3 % a year), nobody unemployed; 5 % → 478; 10 % (the ladder) → 458, bread 5.3; 20 % → 424. Unemployed at month 120: debt 18, SuMSy 22. The rich–poor gap at this step is land without a levy and is not quoted (§12).
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

Interest on savings, two theatres, then four; bonds so that the debt village's government can borrow from its citizens instead of its bank; a monthly charge on firms' idle reserves in both villages. None of it changes who eats. Two things do change. The bonds move the debt village's public debt from the bank's books to the villagers' savings and shrink its money supply by more than half; the debt itself grows as before, to 167,000 at step 5. And the theatres in the debt village keep failing, 32 windings-up in ten years at step 5 against none in the SuMSy village, and what happens to a failed firm's loans turns out to matter more than the theatres (§11). The SuMSy village sells 634 tickets a month at step 5 to the debt village's 285.

### Step 8. Owners and a stock market, and the land dividend

Firms get owners, and shares that trade; and in the SuMSy village the levy on land arrives with its dividend. The debt village keeps 488 and owes 144,000; 116 villagers have no work. The SuMSy village keeps 512, owes nothing, has nobody out of work, and pays every villager about seven a month from the levy on top of the income, more than the income itself.

This is the step on which the two villages are compared throughout the rest of the report, and the comparison is in the frame. One number in it needs its context: the debt village's bread costs 3.5 at year ten and the SuMSy village's 2.0. Both villages deflate; the SuMSy village deflates faster, 9 % a year, because its people work two units in three and spend no more than they need. A village that has enough, and knows it, lets its prices fall. What that does to a debt is in §9.

\[ KADER  
**Step 8, ten-run means.** Alive: debt 488 (worst 475), SuMSy 512. Unemployed: 116 / 0. Bread: 3.5 (−3.7 % a year) / 2.0 (−9.2 %). Public debt at year 5 → 10: 83,000 → 144,000 / 0. Firms wound up: 34 / 0. Rich–poor gap, poorest tenth: 538 meals, 0.8 / 241 meals, 16.0. Tickets a month: 160 / 640. The dividend: 3,650 a month, 7.1 a villager. Land: a plot trades at 340 in the debt village and 39 in the SuMSy village, against a monthly rent of 1 in both (§12).
\]

### Step 9, a side step. Cooperatives

Half the firms as cooperatives, open to anyone at par, with the same dividend for every member. In the SuMSy village they take the gap from 242 to 166 meals and lift the poorest tenth to 20 meals, and cost nobody their bread. In the debt village they change almost nothing.

### Step 10. A public reserve

The government keeps a reserve and cuts taxes when it has more than it needs. In the SuMSy village the surplus is paid out as the dividend instead, so this step is step 8 again; in the debt village there is never a surplus to keep.

### Step 11. A tax policy and a tax on bread

The government raises every tax when it is short and lowers them when it is not, and a tax on bread and tickets is among them. In the debt village the tax on bread does what no other rule in this report does: it kills. 437 of five hundred and twelve are alive after ten years, 408 in the worst run, and the poorest tenth is under water by five meals. The public debt is a fifth of what it was, which is the point of the policy, and it has been paid in people. The SuMSy village, where the parking tax is the only tax and it is never short, is unchanged: 512 alive, nobody out of work, the poorest tenth holding eighteen meals.

### What the ladder says

Two villages, the same at every step but one. The debt village lives from step 2 on because its government borrows, every month, and never stops; a third of its people have no work at every step; and the one policy that brings its debt down costs it seventy-five lives. The SuMSy village lives from step 2, borrows once, repays within three years, and from step 2 on has no unemployment at all. Everything else on the ladder, the theatres, the bonds, the shares, the reserve, moves the figures a little and the story not at all. What moves the story is in the next five sections, and none of it is a step: it is what happens when prices are allowed to move, when they are not, and when the village finds work for its idle third.

\[ KADER  
**The ladder, ten-run means, alive / unemployed / public debt / poorest tenth in meals.** Step 2: debt 509 / 152 / 200,000 / 1.1; SuMSy 512 / 0 / 0 / 28. Step 5: 503 / 108 / 167,000 / 0.8; 512 / 0 / 0 / 3.9. Step 8: 488 / 116 / 144,000 / 0.8; 512 / 0 / 0 / 16.0. Step 11: 437 / 82 / 42,000 / −4.7; 512 / 0 / 0 / 15.9. Co-ops (B): 494 / 117 / 152,000 / 2.7; 512 / 0 / 0 / 20.2. The SuMSy poorest tenth at steps 2–7 is measured before the levy, when land is hoarded; it is quoted, the gap is not.
\]

## 8. What the debt is for

Hold every price in the village still. Not one baker raises the price of a loaf, not one worker asks for more, for ten years; only the amounts change. Can the village live? It can, in both moneys: 509 live in the debt village and everyone in the SuMSy village, and the SuMSy village has nobody out of work.

And the debt village's government still borrows about 1,500 a month, every month, for the whole ten years. With no inflation whatsoever its debt grows in a straight line, from 95,000 at year five to 190,000 at year ten. The SuMSy government owes nothing. So the deficit is not a price phenomenon. It is the money needed to feed the third of the village that has no work, 134 people at this step, and in a village whose money is someone's debt that money has to be borrowed into existence every month. In the SuMSy village the same people are in work, because the work is shared and the income counts, and what they still lack is paid as the dividend. Nobody borrows it.

\[ KADER  
**Fixed prices, step 8 (P8), ten-run means.** Alive: debt 509, SuMSy 512. Unemployed: 134 / 0. Public debt at year 5 → year 10: debt 95,000 → 190,000; SuMSy 0. Money supply: debt 52,000, SuMSy 130,000. Rich–poor gap, poorest tenth: 291 meals, 0.9 / 42 meals, 11.7.
\]

## 9. What prices do with the debt

Now let prices move, by the rules of §5. The same deficit shows a different face, and which face depends on things people choose: how much they will overpay when bread is short, and how the labour market treats the people in it.

**When people can overpay and nothing holds them back,** the borrowed money chases the same bread. Version 3's village, where a hungry buyer paid double and a full theatre paid any wage, ran at fifteen percent a year and more. This version's village overpays by a fifth at most, and the dial still shows: at step 2 the debt village's debt is 170,000 if buyers will pay a tenth over, 200,000 at a fifth, 234,000 at double.

**When wages fall where work is scarce,** the debt village deflates. A fifth of its people idle, wages that fall each time someone loses a job, bread that goes unsold: prices drop 3.4 % a year at step 8 and 11 % at step 11. The debt does not fall with them. Every unit of it weighs more as prices fall, and by year ten the village owes, in loaves of bread, thirteen times what it owed at the end of the first year. That is the debt deflation Irving Fisher described in 1933, and the village walks into it with its books in better order every year.

**The SuMSy village deflates faster**, 9 % a year at every step from 2 on, and owes nothing, so the fall costs it nothing. Its people are all in work, work two units in three, and want no more; the bread they do not want goes down in price until the bakers plan for less of it. A village that has enough lets its prices fall, and a money that is not a debt can afford to let them.

Three labour rules decide the sign, and none of them is the money's. Take the notice period away, so that a worker can be dropped the month a cheaper one appears, and the SuMSy village *inflates*, 10 % a year, to a bread price of 12: the wage level is renegotiated every month in a market where everyone is wanted, and it climbs. Let the villagers offer exactly their share of the work and no more, and it inflates 4 % a year, because the market is tight every month. Let employers take the cheapest hands instead of their own, so that every job is renegotiated from scratch, and it inflates 17 % a year, with nobody hungry and nobody idle through all of it. With the notice period and a tenth of slack, wages are held and prices fall. The rules meant as realism turn out to decide whether a sufficiency village deflates or inflates, and the report leaves it at that: the sign is the labour market's, the stability of the village is the money's, since nobody dies and nobody is idle either way. Every price in this report is quoted under the ladder's settings, a tenth of slack and the notice period.

Labour contracts settle the matter from the other side. Give employers contracts, a worker who has worked three months running kept on at an indexed wage with notice on both sides, and the SuMSy village's deflation stops: with half the hands on contract prices rise 1 % a year, with all of them they fall 1 %, against 8 % without contracts. Experience alone, workers who build skill in one kind of work and are hired first for it, does nearly the same, 2 % a year. The price trend is the labour market's: hands that are kept do not bid their wage down each month, and the wage holds the price. What the village pays for the steady price is its poor: the poorest tenth hold five meals instead of sixteen, because the contracted keep the work and the wage, and the gap between richest and poorest tenth narrows from 241 meals to about 170, since the rich hold money whose price rises less. In the debt village contracts change little: 481 to 492 alive, the debt 132,000 to 144,000, prices falling 3½ to 4 % a year as before.

\[ KADER  
**Prices a year, ten-run means.** Overpay up to 1.1× / 1.2× / 2× at step 2 (debt): bread 3.5 / 4.5 / 5.4 at year ten, debt 170,000 / 200,000 / 234,000. Step 8: debt −3.4 %, SuMSy −8.3 %; step 11: −11.4 % / −8.7 %. Without the notice period (Y8): debt −1.3 %, SuMSy +9.1 % (bread 11.2, gap 69 meals). Without employers' loyalty, every job up for grabs each month (Y8): debt 501 alive, −5.4 %, public debt 103,000; SuMSy +17 % a year (bread 22), nobody unemployed or hungry. With the sharing margin at 0 instead of 10 % (M8-0): SuMSy +3.8 % a year (bread 7.5), gap 126 meals. The wage floor lasting three months instead of one (Y8): no change in either village. The debt village's public debt in loaves at year 10 against year 1: 12.7× at step 8, 14.0× at step 11.
Contracts and experience, step 8 (J8-50, J8-100, XP8, XPJ8), prices a year / alive / poorest tenth: SuMSy +1.1 % / 512 / 4.8 with half the hands on contract; −1.1 % / 512 / 5.1 with all; −1.8 % / 512 / 5.7 with experience; −1.7 % / 512 / 5.3 with both; debt −3.5 % / 492 / 1.0; −4.2 % / 481 / 1.0; −2.7 % / 488 / 0.9; −4.7 % / 487 / 1.0.
\]

## 10. Full employment

The debt village has work for two thirds of its people, because the villagers want a meal, a cushion and a night out, and once bread takes half the labour there is nothing more they ask the village to make. To employ the rest we gave it what every real economy that employs its people has: bread cheap enough to leave money over, a service that absorbs labour and covers its costs, people who want two nights out a month instead of one, and firms that come back when they fail.

The SuMSy village then employs everyone, as it did before, and sells a thousand tickets a month; its bread falls to a third of a loaf's old price, 17 % a year, and its poorest tenth hold thirty-seven meals. The debt village employs four fifths of its people, better than the two thirds of step 8, and for once its budget balances: taxes cover its spending in the last year and the debt levels off at 22,000. It pays for that in two ways. Its firms fail 101 times in ten years, farms and theatres alike, because at these prices neither can keep four of its kind in business, and each failure leaves a written-off loan and a bailout behind (§11). And its prices fall 11 % a year, to a loaf at 0.8, which is good for the eater and bad for the debtor: the poorest tenth end four meals under water, and in its last five years it still has a hungry month with ten people in it.

Holding prices fixed, the test this report ran first, changes the picture rather than the diagnosis. The fixed-price debt village keeps 509 and employs only three fifths, 194 out of work, with a debt of 119,000 and 153 failed firms: full employment at fixed prices is bought with public money, and at free prices with falling prices. The SuMSy village is full employed either way.

Give the debt village full employment through public jobs instead, forty percent of the village on the public payroll, and nobody is unemployed and the debt grows faster than ever, 153,000 at year ten (207,000 at fixed prices). Make the government raise taxes until that budget balances, and at fixed prices 203 of five hundred and twelve are alive; at free prices the village dies out entirely, in every run, by a route this report has not yet traced and does not interpret. The SuMSy village under the same rule keeps everyone and owes nothing. A job the government cannot pay for feeds no one.

\[ KADER  
**The productive village (V8): four loaves a grain, theatres needing a worker per customer, two tickets a month wanted, failed firms restarted, prices free. Ten-run means:** alive debt 478 / SuMSy 512; unemployed 101 / 0; bread 0.8 (−10.8 % a year) / 0.4 (−16.6 %); public debt 16,000 → 22,000 / 0; firms wound up 101 / 0; taxes against spending 3,800 / 3,300 and 38,100 / 500; rich–poor gap and poorest tenth 412, −4.2 / 570, 37.3. **With prices fixed (V8-P):** debt 509 alive, 194 unemployed, debt 61,000 → 119,000, 153 firms wound up, poorest tenth 2.0; SuMSy 512, gap 196, poorest tenth 5.3. **Public jobs 40 % (U8, UP8):** debt 498 alive and 153,000 of debt (fixed prices: 512 and 207,000); with taxes raised until the budget balances, 203 alive at fixed prices (133,000 of loans written off), none at free prices; SuMSy 512, no debt, gap 227 meals, poorest tenth 15.5.
\]


## 11. Where the debt village's money comes from when no one borrows

Why do the debt village's firms keep failing, and why does it matter? A firm that cannot cover its bills goes under; its loans are written off; the money those loans created stays in circulation with no debt behind it; and the bank's loss is made good by a government that borrows to do so. Then someone with savings starts the theatre again, and the cycle repeats. At step 8 the debt village writes off 34,500 of loans in ten years, bails out its banks for 2,800, winds up 34 firms and restarts 20; in the productive village 101 firms, farms and theatres alike, are wound up and 50 restarted. In the SuMSy village the same theatres never fail: every villager has the income and the dividend to spend on a seat, and the theatres sell four seats where the debt village's sell one. No loan creates money there, so no default creates any either, and there is nothing to bail out.

Three rules were tried on the banks because of this, and the report keeps all three: banks pay interest on deposits only from what lending has earned, above an eight percent reserve; a failed firm's bank loans pass to its owners, who are written off after six months if they can pay nothing; and the government stands behind the banks only where there is a government. The second changed almost nothing: the owners have no more than the firm had.

\[ KADER  
**Bailouts and write-offs, ten-run means, month 120.** Step 5: debt bailouts 22,700, loans written off 32,500, firms wound up 32, restarted 21; SuMSy 0 / 0 / 0 / 0. Step 8: 2,800 / 35,700 / 34 / 20; SuMSy 0 / 0 / 0 / 0. V8: 5,500 / 13,900 / 101 / 50; SuMSy 0. UP8-P: 133,000 written off; UP8 at free prices 200,000. Tickets a month at step 8: 160 / 640.
\]

## 12. Land

Land is the one thing money does not price the same way in the two villages. In the debt village a plot is worth its rent capitalised at what a deposit earns: about 340 at step 8, against a rent of 1 a month, and it changes hands at that. In the SuMSy village money that loses value is never a reason to sell land, so nobody sells, and the rare plot that comes to market goes for whatever the richest bidder has: 6,200 at step 8 without a levy, some 9,000 months' rent, with every plot in household hands. Silvio Gesell saw this a century ago. His answer was to take land out of private hands: the state would buy it with bonds, lease it to the highest bidder, and repay the bonds from the rent. He rejected Henry George's answer, a tax on land, because he feared that owners would pass it on to their tenants. The village tries George's answer: a levy on land set to the cost of holding money plus a small margin, with the proceeds paid out to every villager as a dividend. Then land trades at 39, a ninth of the debt village's price, a fifth of it moves to the farms that work it, the government owes nothing, and the dividend is larger than the income itself.

Three things follow. Without the levy, the SuMSy village's rich–poor gap in meals measures the land price and nothing else (10,000 meals at step 8 against 242 with the levy), and this report quotes the SuMSy gap only where the levy is in place; before step 8 it quotes the poorest tenth alone. The levy must never be cut: three different rules in this model's history cut it when the government had a surplus, and each time land froze within months. And the levy and the dividend together answer a question the SuMSy village had: with them paid out, the long-term unemployed need no benefit at all, which is what the dividend is. Gesell's objection was tested directly: landowners who ask the levy on top of the going rent, and tenants whose bids decide whether it sticks. It sticks. Rent triples, from 0.9 to 2.7; grain doubles and so does bread, from 2.2 to 4.5; everyone is still alive and employed, and the dividend, which the higher land values swell, is larger than before; but the poorest tenth hold ten meals instead of sixteen. Gesell was right that owners can pass a land tax on, and the village shows what that does: the levy is paid in the price of bread, by those who hold the fewest meals, dividend notwithstanding. In the debt-money twin with the levy (§16) the same pass-through doubles bread as well, and there the larger dividend leaves the poorest tenth better off than without it, five meals against three, because they had so little to begin with. Which way it falls depends on how much of the levy comes back as dividend and how much goes out in the price of bread.

Gesell's own answer was tried as well: the land in public hands, farms renting the plots they work, bakeries and theatres paying for their ground, every villager a quarter of a loaf a month for the ground they live on, the rents going to the government like a tax and, under SuMSy, out again as the dividend. In the SuMSy village it does what the levy does, and a little better for the poor: everyone alive and in work, the dividend 3,000 a month against the levy's 3,700, the poorest tenth holding twenty meals against sixteen. In the debt village the outcome turns on one rent. With the land public and no rent charged, the village keeps 494, its gap collapses from 538 meals to 38, because the land that made the rich rich is nobody's, and its debt is lower, 110,000 against 144,000. Charge the rents, and 239 are left after ten years, with the poorest tenth fourteen meals under water. The farms' and firms' rents are not what kills; the quarter loaf is. The benefit in the debt village is exactly two loaves, and a quarter loaf taken from it every month leaves the unemployed short of a meal, slowly, for ten years. A rent on the ground people live on must spare those who live on the benefit, or the benefit must cover it. The SuMSy dividend covers it without being asked.

\[ KADER  
**Land, month 120, ten-run means.** A plot's price, debt / SuMSy with levy and dividend / SuMSy without: 340 / 39 / 6,300, against rents of 1.0 / 1.0 / 0.7. Land held by households: 100 / 80 / 100 %. Rich–poor gap, poorest tenth: 538, 0.8 / 241, 16.0 / 8,508, 3.9. Public land (PL8, PL8-0), alive / gap / poorest tenth / public debt or dividend: debt with rents 239 / 21 / −14.2 / 16,000, without 494 / 38 / 1.0 / 110,000; SuMSy with rents 512 / 207 / 19.7 / a dividend of 3,000 a month, without 512 / 314 / 9.0 / 1,600; the SuMSy village with the levy 512 / 241 / 16.0 / 3,700. With the levy and dividend from step 2 (L2): gap 73, poorest tenth 21. The levy: parking fee + parking tax + 0.25 % a month of the land's value; the dividend: the whole surplus, paid per head.
\]

## 13. Three policies, tried

**Austerity.** From year five the debt village's benefit falls from two loaves to one over six months. The debt grows at half its pace, 30,000 over the last five years instead of 57,000, and in the last year taxes cover the spending. Forty-three more villagers die, sixty are hungry at the worst month after the cut, and the poorest tenth ends under water. Prices fall faster, so the debt that remains weighs more. The books look better; the village is poorer in every real measure.

**A ceiling on public debt.** The government cuts its spending whenever its debt exceeds a year's output. At one year's output 407 of five hundred and twelve are alive and the debt still grows; at 60 % of a year's output, the reference value of the euro area's fiscal rules, 313; at half a year's, 287. A debt ceiling in a village whose debt is the cost of its unemployment is a rule to starve the unemployed.

**The parking fee as a lever.** A higher fee lowers the money each SuMSy villager settles at, and with it the price level, so that the same guaranteed income buys more bread. At three or four percent, with starting prices to match, the money supply falls from 135,000 to 75,000, the gap from 283 to 161 meals, and nobody dies at any setting. It is the SuMSy village's monetary policy, and it works on the distribution without touching anyone's bread.

\[ KADER  
**Austerity (A8), ten-run means:** alive 446 against 488; public debt at year 5 → 10: 82,000 → 118,000 against 83,000 → 144,000; hungry at the worst month after year 5: 60 against 5; poorest tenth −0.9; prices −5.1 % a year against −3.4 %. **The debt ceiling (D8):** at 1× yearly output 407 alive, debt 108,000, 79 hungry at the worst month; at 0.6× 313 alive, debt 76,000, 83 hungry; at 0.5× 287 alive, debt 65,000. **The fee (F8), SuMSy village started at its full money stock, 2 / 3 / 4 %:** 512 alive at each; money 135,000 / 95,000 / 75,000; gap 283 / 196 / 161 meals; poorest tenth 16 / 12 / 11.
\]

## 14. A public investment

Governments build things that pay back late or never, and the village was given one: a public transport line. For five years, five percent of the village's labour works on it at the public wage, and nothing comes back. Then the same workers run it, and every villager wants one ride a month, bought if there is money left after bread, at half a loaf a ride. The fares are the government's.

The villages build it at a similar cost. What they earn from it differs by the same thing that runs through this report: who can pay. In the SuMSy village 489 villagers ride each month and 23 cannot afford to, and within five years of opening the line has paid for itself with half as much again to spare. The government borrowed its citizens' savings to build it and paid them back within the first year. In the debt village 176 ride and 321 cannot afford to, and the line has earned back seven tenths of its cost by year ten. Its government's debt ends lower than without the line all the same, 111,000 against 144,000, because the line's jobs cost it less than the idle cost it in benefits, and 26 fewer villagers are out of work. In both villages the line employs people; only in one can they ride it.

A public service earns its keep where the public can pay. That is a sentence about demand, and in this village the guaranteed income and the dividend are what give the public the means.

\[ KADER  
**The public transport line (T8), ten-run means.** Building and running cost over ten years: debt 31,200, SuMSy 22,100. Fares by month 120: 23,800 / 35,200. Rides a month at the end: 176 / 467; villagers unable to afford one: 321 / 45. Unemployment with and without the line: debt 90 / 116, SuMSy 0 / 0. Public debt at month 120 with and without: debt 111,000 / 144,000, SuMSy 0 / 0 (655 borrowed in the first months, repaid by month 9). Settings: 5 % of capacity for 60 months at the public wage, then operating; fare half a loaf; one ride a month wanted per villager.
\]

## 15. Greed, hoarding, and the people who do not work

Make a quarter of the villagers greedy, or all of them, and the SuMSy village feeds everyone: 512 alive in every run of ten, four bakeries open for ten years, and with everyone greedy the smallest gap on the ladder, 54 meals, with the poorest tenth holding twenty-eight. The debt village under universal greed keeps 505, and borrows 222,000 to do it, with a fifth of its people out of work.

It was not always so, and the reason is worth telling. In an earlier run of this version the greedy SuMSy village died in every run of ten, and for three days the cause was sought in greed itself: in bread that spoiled, in prices that could not keep up, in greedy bakers, in bakers who would not raise prices when failure loomed. Each was tried as a rule and changed nothing. The bakeries' books gave the answer. The bakers planned for greedy demand from what the greedy villagers *could* afford, and in a village where everyone has money to spare that is a great deal; so each bakery bought grain for three times what its ovens could bake, paid for it, and went under with a full storeroom while bread was getting cheaper. Let the bakers plan on what the greedy actually bought, within what their ovens can bake, and the village lives. It is the one rule in this report that killed a village on its own, and it was a bookkeeping rule. The rules tried before it stay on the ladder as the controls that ruled them out.

One thing still kills the greedy village, in both moneys: buyers who will pay double for bread when it is short. Then every greedy villager outbids every other, and both villages die, the debt village owing twelve million. That is a panic, and no money in this report survives one.

Make the richest hundredth greedy, spending or investing every surplus, and little changes in either village: the debt village's public debt ends at 149,000 against 144,000. Make one villager in a hundred, or one in ten, a cash hoarder instead, buying bread and nothing else and lending nothing, and nothing changes at all. In this village no one holds enough money for hoarding it to matter: the ten percent chosen for having the most money hold 3,500 of 43,000 between them, and the SuMSy parking fee melts what its hoarders keep. A money can be hoarded into a shortage, but not by a tenth of a village whose money is spread this thin.

Give the village gold, a hundred grams a head, held at the start by the richest tenth, yielding nothing and costing nothing to keep, and the two moneys answer differently. Under debt money a gram ends at 68, twenty loaves; under SuMSy, where idle money loses value and gold does not, at 1,750, nine hundred loaves, twenty-five times as much, and the richest tenth still hold all of it. That is where a SuMSy village's spare money goes when it can go nowhere else. It changes nobody's bread: gold feeds no one and turns into bread only if someone pays money for it, which is why this report keeps gold out of its measures of wealth and reports it beside them. Land is different, because land yields; gold is a bet on the next buyer, and the village can let those who want it have it.

Make five villagers in a hundred people who do not work, for reasons the model does not ask about, care, illness, art, or choice, who take paid work only to eat, and some only once hungry. In the SuMSy village all twenty-six live, on the income and the dividend, without working. In the debt village twenty-four of them die: they are outsiders in a labour market where employers keep their own, and the benefit, which falls over time to one loaf, does not carry them. A money that pays everyone carries those who do not work; a money that does not lets them starve.

Lastly, a premium loaf: the same bread at five times the price, for whoever has money to spare, baked with extra hands. It is the village's version of what real economies do when their people want no more things, which is to sell them dearer ones. In the debt village a few are sold each month and the debt is *higher* for it, 159,000 against 144,000, because the extra wages are borrowed like all the rest and few can pay the price. In the SuMSy village none are sold at all: the villagers keep a month's bread in the cupboard and buy ahead, and a dearer loaf finds no one in need of one. Growth in value without growth in volume needs a public with spare money and an empty cupboard, and neither village has both.

\[ KADER  
**Ten-run means.** Greed: a quarter greedy (S1) SuMSy 512 alive, debt 498; everyone greedy (S3) SuMSy 512 in every run, gap 54 meals, poorest tenth 28.3; debt 505, public debt 222,000. With cooperatives (SB2): SuMSy 512, gap 49, poorest tenth 27.8. The controls on the greedy SuMSy village, alive: spoilage acceptance 10 / 100 / 300 %: 512 / 512 / 512; firms on the step rule: 512; no distress pricing: 512; overpay 1.1× / 1.3×: 512 / 512; 2×: SuMSy 4, debt 0. The same village under the earlier planner (run of 13 October): SuMSy 57 alive, worst run 0. The richest 1 % greedy (H8): debt 488 alive, public debt 149,000, gap 543; SuMSy 512, 243, 15.5. Gold (R8): price 68 / 1,751, the richest tenth hold all of it in both; without the levy (RZ8) 2,685. Cash hoarders, 1 % / 10 % of the village (HC8, HC8-10): debt 487 / 482 alive, public debt 144,000 / 146,000; SuMSy 512 / 512. Not working (Q8): debt 457 alive against 488; SuMSy 512. A volunteer-run theatre, seats at a quarter loaf (CT8): in the debt village it ends as the only theatre, with 134 out of work against 116 and a public debt of 175,000 against 144,000, because it takes the paid theatres' audience and their staff's wages with it; in the SuMSy village the paid theatres keep 480 of their 640 seats and nothing else changes. The premium loaf (K8): debt 492 alive, public debt 159,000; SuMSy none sold. In the productive village (KV8): debt 73,000 either way.
\]

## 16. The money or the transfers?

A reader of an earlier version asked the question every banker will ask. The two villages differ in more than their money: the SuMSy village pays everyone an income, pays out a levy on land, and taxes idle money instead of wages. Would a debt-money village with the same arrangement do as well?

So the debt village was given SuMSy's arrangement, piece by piece, with its money left as it is. A tax on idle money instead of the tax on wages, at the same rate as the SuMSy village's parking tax, paid to the government; nothing is destroyed, because a bank deposit has a loan on the other side of the bank's books and cannot simply vanish. A levy on land at the cost of holding money plus a little, paid out to everyone. An income of five a month for every villager, paid by the government as it pays the benefit, from its taxes and, where they fall short, by borrowing.

With all of it the debt village keeps everyone alive and has nobody out of work, as the SuMSy village does. The income alone does the same. So the answer to the reader is plain: in this village it is the income and the dividend that keep people alive and in work, in either money.

What the money changes is who pays for them. In ten years the debt village with an income borrows 340,000, two and a half times its debt without one, because every unit it pays out it must first borrow. The borrowed money ends in the villagers' pockets: the poorest tenth hold 81 meals, five times what the SuMSy village's poorest hold. In effect the debt village creates new money just as the SuMSy village does, and books every unit of it as a debt of the government. The SuMSy village pays the same income as money that nobody owes, and its government ends the ten years owing nothing.

Two smaller findings come with it. A tax on idle money shrinks debt money: firms escape it by repaying their loans, and the money stock falls by half, by two thirds with the levy beside it, with prices falling six to ten percent a year. SuMSy's money has no such escape, because nobody owes it to a bank. And as soon as holding cash costs something, the land runaway of §12 appears in debt money too: with the tax alone and no levy, land rises to 700 and the gap to twelve hundred meals. The land problem Gesell saw follows the cost of holding money, whatever the money is made of.

An earlier run of these villages had a hungry month, some two hundred villagers in month 6 of the debt village with the income alone. It took both things only that village had: firms that fail, as in any debt-money village, and villagers whose income covers their needs, so that they offered only their share of the work, sized on one month in which four failed firms had taken their part of the plan with them. Villagers now size their share on the most employers have wanted in three months, and the hungry month is gone.

\[ KADER  
**The debt village with SuMSy's arrangement, step 8, ten-run means.** Alive / unemployed / public debt / money stock / a plot's price / poorest tenth in meals. The debt village as it is: 488 / 116 / 144,000 / 44,000 / 340 / 0.8. With an income of 5 a month (DGI8): 512 / 0 / 340,000 / 61,000 / 457 / 23.1. A tax of 1.5 % a month on idle money instead of the tax on wages (DD8): 504 / 74 / 98,000 / 22,000 / 692 / 1.0. With the levy on land and its dividend (DDL8): 502 / 20 / 50,000 / 14,000 / 272 / 2.9; the dividend 960 a month; with the levy passed on (DDL8-PT): 497 / 8 / 58,000 / 25,000 / 347 / 4.8, bread 3.6 against 1.8. SuMSy's whole arrangement, tax, levy, dividend, income and the one-loaf benefit (DDGL8): 511 / 0 / 355,000 / 48,000 / 408 / 81.1; with the tax at 3.5 % (DDGL8-35): 511 / 0 / 314,000 / 41,000 / 414 / 69.5. The SuMSy village: 512 / 0 / 0 / 128,000 / 39 / 16.0; with the levy passed on (LPT8): 512 / 0 / 0 / 130,000 / 131 / 10.3, rent 2.7 and bread 4.5 against 0.9 and 2.2. Taxes against spending in the last year: debt village 11,000 / 15,300; with SuMSy's arrangement 36,100 / 60,500; the SuMSy village 45,800 / 1,800.
\]

## 17. What this shows, and what it cannot

It shows a village in which the money that feeds the idle third is borrowed every month, and what that borrowing becomes when prices can move: inflation if people will overpay and no one holds them back, deflation under a fixed debt if they will not and wages fall. It shows another village in which the same money is paid as an income and a dividend, owes nothing in steady state, repays the one debt it incurs within three years, and from the moment it has a benefit has no unemployment at all, because its people work for the village, for themselves and for the work, and the money lets them stop when there is enough. It shows, from a third village, the debt village given the same income and dividend, that the income and the dividend are what keep the village alive and in work, in either money, and that what the SuMSy money adds is that nobody has to borrow them: the debt village does as well and owes a third of a million for it. It shows that the debt village balances its books only with prices held still and its people made to want more, and loses people whenever it tries to balance them otherwise: by tax, by austerity, by a ceiling. It shows that a public investment pays for itself where the public can pay, that a theatre survives where its audience can afford a seat, and that a dearer loaf is no way out. It shows which rules killed: the tax on bread, the debt ceiling, the full-house theatre allowed to set the village's wage, a labour market that keeps insiders and forgets the rest, and bakers who read their customers' money as their demand; and a ground rent charged to people whose benefit is their bread.

It cannot show what a real economy does, with a thousand goods, foreign trade, a central bank, and people who want more than two nights out. And it rests on one assumption that runs through every comparison in it: that people behave the same way under SuMSy as they do under the money we have. The villagers of both villages overpay the same when bread is short, hoard the same when they have spare money, want the same night out, and refuse the same wage cut. They may not. A person whose income arrives every month without fail, and whose savings melt if left idle, may hoard less, lend more freely, work for other reasons, or price what they sell differently; nobody knows, because no such village exists to ask. This report holds behaviour fixed so that whatever differs between the villages can be laid at the money's door. Where behaviour would differ, the comparison is only a starting point.

One more thing it cannot show is how much of what it shows is the labour market's rather than the money's. The village's people work for the village, for themselves and for the work; take any of the three away and the results move, in both villages. An earlier draft of this report, with villagers who offered all their labour whatever they needed, had a SuMSy village with a fifth of its people out of work and a debt village with a third. The money did not change between the drafts; the rule did. The reader should take the differences *between* the villages as the money's, and the levels in either as the village's.

## 18. The ladder's answer, for policy makers

Readers who hold that a government's debt in its own currency is no burden will say the twins of §16 settle the matter: let the government borrow the income. The model gives three reasons to hesitate, all of them about incentives rather than law. The debt is not free here: at any positive rate its interest flows to whoever holds it, which in this village means the banks and their owners. A debt that keeps growing is a standing invitation to the policies of §13, and those cost lives. And the twins show what such a policy does once it is applied. Halve the income in the sixth year and nobody dies in either money, though the poorest tenth lose about two thirds of what they hold, in both: sixteen meals to five under SuMSy, twenty-three to ten in the debt village. Put the debt village under a rule that caps its debt at 60 % of a year's output, the reference value of the euro area's fiscal rules, and the rule cuts the income to a fifth as soon as it binds; eighteen villagers die in the second five years, forty are hungry at the worst month, and the poorest tenth end two meals under water. How much the objection weighs therefore depends on whether a government borrows in a money it issues or in one it does not; under a debt rule, the income is undone by the rule rather than by a vote. An income paid as new money triggers no such rule, because nothing about it is owed.

\[ KADER  
**The income reversed and the euro rule, ten-run means.** The income halved from month 60 (RV8): debt village 512 alive, nobody unemployed, public debt 270,000 (340,000 unhalved), poorest tenth 10.4 (23.1); SuMSy 512, poorest tenth 5.3 (16.0). The debt village with a basic income under a debt ceiling at 60 % of a year's output (EU8): 494 alive (488 in the worst run), the income cut to a fifth when the rule binds, 84 unemployed, 40 hungry at the worst month after year 5, public debt 147,000, poorest tenth −2.1. The same ceiling without the income (D8-60): 313 alive — the ceiling cuts the benefit and the public jobs, which without the income are all the poor have.
\]

Most of what governments argue about, tax rates, interest rates, the coupon on their bonds, the reserve their banks must hold, moved this village very little. What moved it was the plumbing: whether money is a loan or an income, whether land can be hoarded, whether the idle can be customers, whether the work is shared. A debt-money village can balance its books at full employment and fixed prices, and only there, and it gets to full employment only by making its people want more than they need. The rest of the time it chooses between a debt that grows, prices that fall under it, and people left without income. A basic income and a land dividend keep a village alive in either money; under debt money they are paid for with a debt that grows by their full amount, and under SuMSy with money that nobody owes. A village whose money is paid as income has none of those choices to make, and what it has instead is a labour market to design: who works, for whom, and for how long, which this report has only begun to turn.

## Glossary

**Bailout.** The government putting money into a bank whose losses have eaten its equity, so that depositors are not hurt. In the debt village the government borrows to do it.

**Benefit.** Two loaves a month, at the going price of bread, paid by the debt village's government to anyone without work; one loaf in the SuMSy village, on top of the income.

**Capital reserve.** The eight percent of its private loans a bank keeps as its own money, as the Basel accords require. Loans to the government need none.

**Cooperative.** A firm owned by its members, who join by buying one share at par and receive the same dividend each.

**Cushion.** The thirty units every villager keeps before spending on anything beyond bread. Under SuMSy, money up to the cushion pays no parking fee.

**Debt ceiling.** A rule that cuts public spending whenever the public debt exceeds a set multiple of the village's yearly output.

**Demurrage tax.** In the debt village's twins of §16, a tax on idle money above the cushion, paid to the government, instead of the tax on wages. Unlike the SuMSy parking fee, nothing is destroyed.

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
