# The Bread Economy

*What happens to a village when you change its money*

Version 4 — DRAFT, October 2026 (numbers from the 11 October run; placeholders marked ⟦ ⟧)

← Previous report: [version 3, 21 September 2026](https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) (https://claude.ai/artifact/2QoeDyc3kT7BSCnso2Jvqt) · Next report: none yet

*This is an AI-generated report. It was written by Claude (Anthropic) in an interactive session with a human researcher, who set the questions, the design of the village and the rules of engagement, and it is supported throughout by the results of the simulations described. The source code of the simulation is public at https://github.com/HapponomyOrg/BreadEconomySim.jl. Read it as a working document: every number in it comes from a run that can be repeated, and every judgement in it is open to challenge.*

**Status of this draft (3 October 2026).** Every figure marked † is from a single run of the current model, made while the rules were being settled (26 September – 3 October); every figure marked ‡ is a ten-run mean from the run of 25 September, under rules that have since changed, and is kept only where the mechanism it illustrates is unchanged. Figures in ⟦ ⟧ wait for the ten-run job of 11 October, which will also replace every † and ‡.

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred and twenty rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where one run went badly wrong the worst one is mentioned as well. A round is best thought of as a month. There are five hundred and twelve villagers. "Alive" means alive at the end of the hundred and twenty rounds. Where a figure comes from a single run, the text says so.
\]

**What changed since version 3.** The village grew from sixty-four to five hundred and twelve people, so that the gap between rich and poor could be measured on a tenth of the village rather than on six people. Firms now send invoices and pay them a month later, and a firm that cannot pay its bills is wound up. Land has a market. Prices and wages move by rules calibrated to what we see around us: a few percent a year. And three questions were put to the village that version 3 could not answer: what the debt village's debt is the cost of; what happens to each money when prices are allowed to move; and what full employment does. Version 3 said the SuMSy village kept its prices steady while the debt village's rose; version 4 says why, and when the opposite happens.

## 1. A village, twice

Imagine a village. Five hundred and twelve people live there. Some own land, most do not. Four farms grow grain, four bakeries turn it into bread, and later on four theatres give people something to do in the evening. Everyone needs two loaves a month. Go three months without any bread at all and you die.

Now imagine the same village built twice, with the same people, the same fields, the same ovens, the same habits, and one difference: where its money comes from.

In the first village, money is what it is for us today. It comes into being when a bank makes a loan and disappears again when the loan is paid back. Every euro in someone's pocket is a euro that someone else owes. The government pays for a few public jobs and a benefit of two loaves a month for people without work, and it pays for them by borrowing.

In the second village, every person receives a fixed sum of new money every month, whether they work or not. Money that sits idle above a modest cushion pays a parking fee: a small percentage each month simply disappears. On top of the fee, a smaller percentage of the same idle money goes to the government, and out of that the government pays a few public jobs and a benefit of one loaf a month to people without work, half what the debt village pays, because the monthly income covers the other half. Nobody owes anyone for the money in their pocket.

The report builds the village up one piece at a time, and at every step asks the only question the village cares about: who still has bread? Then it does four things to the village that no step does. It holds every price still and asks whether the village can live without anyone ever raising a price. It lets prices move and watches what each money does with them. It makes the village productive enough to employ almost everyone, to see what the debt village's debt was for. And it has the government build something that pays back late, to see which money can wait.

## 2. Two kinds of money, in plain words

A loan creates money. When a bank lends a baker a thousand, it writes a thousand into the baker's account and a thousand into its own books as a debt owed to it. Nothing was there before. When the baker repays, both entries vanish. The money supply of the debt village is the sum of its outstanding loans, and it can only grow if someone, somewhere, borrows more.

A guaranteed income creates money too, but without the debt. Each month five new units appear in every villager's account. What keeps that from growing without end is the parking fee: whatever sits idle above the cushion loses two percent a month. A villager who holds a hundred and sixty above the cushion loses about as much to the fee each month as the income brings in, so there the balance settles. Add up all the villagers and you have the money supply of the SuMSy village, fixed by two numbers that nobody borrowed.

One asymmetry between the villages is chosen, and it matters later. The debt village's benefit is two loaves at whatever bread costs; the SuMSy income is five units whatever bread costs, with one loaf of benefit on top for those without work. The first is protected against rising prices and feeds them; the second is not and cannot. (An earlier version of this village gave the SuMSy villagers the income alone. That kept everyone alive only as long as the village shared its work around; once employers kept their workers, as real employers do, the same people stayed out of work for years and an income of half a meal did not keep them alive. The one-loaf benefit is what it took, and the parking tax of 1.5 % pays for it.)

\[ KADER  
**The numbers.** Bank loans at 0.5 % a month to start, rising to at most 1.5 %; the government borrows at 0.5 %. Guaranteed income 5 a month; cushion 30; parking fee 2 % a month on money above the cushion; parking tax 1.5 % on the same base, on top of the fee; a benefit of one loaf a month for the unemployed. Starting prices: bread 5, grain 5.2, a unit of labour 3.92, a theatre ticket 2, a month's rent on a plot 0.75. A full-time worker (three units a month) earns 11.76 before tax; a month's bread costs 10.
\]

## 3. Who lives there

Five hundred and twelve villagers, of whom a hundred and twenty-eight own land, a plot and a half each. Four farms, four bakeries, two banks, and from step 4 on, theatres. Each firm is founded by four villagers who put up its working reserve from their savings, borrowing what they lack on business terms: a five-year loan, and only what they can carry. Nobody founds more than one firm, so the village has forty-eight owners.

The government hires up to a tenth of the village's capacity from whoever is left after the private markets, and pays the benefit: two loaves in the debt village, one in the SuMSy village. The banks lend, keep eight percent of their private loans as a reserve, and pay interest on deposits only out of what lending has earned them.

## 4. A month in the village

Each month the farms hire labour and grow grain; the bakeries buy grain, hire labour and bake; the villagers buy bread, and a ticket if they can afford one. Firms send each other invoices and pay them the following month. At the end of the month everyone's bills are settled against everyone else's, and whoever is short borrows, if a bank will lend, or sells land, or goes without.

A firm whose overdue bills reach a tenth of its monthly turnover and that can no longer borrow is wound up: its loans pass to its owners under their guarantee, its unpaid invoices are written off, and its ovens stand idle until someone with spare cash starts it again. When a whole kind of firm has gone, the last bakery say, the villagers with the most savings try to found a new one.

## 5. How the villagers decide

A villager offers only as much labour as a meal, the cushion and a night out require, and no more. A seller who sold everything raises the price a little, one who sold too little lowers it, but only when the shortfall or the surplus is worth reacting to: a twentieth of the market, not a single loaf. A hungry buyer will pay up to a fifth over last month's price for bread, and no more than two loaves' worth for a seat at the theatre. An employer short of hands will bid up to a fifth over the wage paid last month. A worker in work will not take a cut of more than half a percent a month; a worker who lost the job bargains freely. Employers take on last month's workers before strangers, and a worker who has been with the same employer for six months cannot simply be dropped: the employer owes three months' notice, and pays for them. And when the village's bread ran short last month, nobody holds a floor: whatever keeps the ovens going is agreed.

Every one of these is a choice made by people in a context, and every one of them was once set wrongly in this model. Every one of them is also the same in both villages: the same willingness to overpay, the same wish for a night out, the same reluctance to take a cut. That is a decision of this study, not a finding of it, and §16 says what it costs. Version 3 let hungry buyers pay double and let a full theatre pay its workers whatever its tickets brought in. Both turned out to be the whole difference between a village with a few percent of inflation and one with a third.

\[ KADER  
**The behavioural rules, with their values.** Prices move 6 % on a signal; the signal is 5 % of the market unserved or unsold. Buyers overpay up to 1.2×. A ticket is worth at most 2 loaves. Employers bid up to 1.2× the wage paid last month. The agreed wage of a worker in work last month falls at most 0.5 % a month; the floor lapses a month after a job and is suspended when last month's bread fell below 90 % of a meal each. Employers rehire their own workers first; three months' notice after six months' service. Firms hire at up to 10 % above what a unit of labour brings in. Villagers aim for a meal, the cushion and one ticket a month.
\]

## 6. Why the rules matter more than the money — at first

Before the money system does anything at all, three rules decide whether the village lives: that bakers plan a margin above last month's sales, that a government exists to hire the idle and feed the rest, and that prices can rise when bread runs short so that the bakers bake more. Version 3 showed this on the sixty-four-person village; the five-hundred-person village says the same. Without a government the debt village keeps 14‡ people alive of five hundred and twelve; the SuMSy village keeps 510‡, because five a month is half a meal and the other half is there to be earned.

## 7. The ladder

The village is built up in twelve steps. Both villages climb the same ladder, and at every step we look at who is alive, what bread costs, what the government owes, and how far apart the richest and poorest tenth stand, measured in meals.

\[ KADER  
**The steps.** 0 bare bones · 1 planning ahead · 2 a government · 3 interest on savings · 4 theatres · 5 government bonds · 6 a charge on idle money · 7 four theatres · 8 owners and a stock market · 9 (a side step) cooperatives · 10 a public reserve · 11 a tax policy and a tax on bread. Version 3's step 10, "prices that respond", is gone: the price rules are how people behave, not a policy, and from this version they apply from step 0. Each step is named once for both villages; where a step adds something only the debt village can have (interest on deposits at step 3, the bond market at step 5, a charge on idle money at step 6, which the SuMSy village has from the start), the SuMSy village is simply run again unchanged, so that the two stay side by side.
\]

### Step 0. Bare bones

Fields, ovens, and no one to help. In the debt village most people find no work, and without work there is no money and without money no bread: 14‡ of five hundred and twelve are alive after ten years. In the SuMSy village nearly everyone lives. Five units a month is half a month's bread, and work for the other half is there to be had.

⟦panels "what is there" at every step are generated at build time from the step tables⟧

### Step 1. Planning ahead

The bakers plan a margin above last month's sales. It helps the SuMSy village a little and the debt village not at all.

### Step 2. A government

Public jobs for a tenth of the village, and a benefit of two loaves for the rest. Now everyone lives in both villages. In the debt village that costs the government about 2,000† a month more than it collects, every month, for ten years; it borrows the difference, and by year ten owes about 250,000† (⟦ten-run mean⟧). The SuMSy government runs a surplus.

But the SuMSy government borrows too, once. While its money is still filling up the village, the parking tax brings in little, and it borrows its citizens' savings: about 8‡ a villager at the worst point, around month 17‡. Then it pays every unit back, by month 46‡ in every run (⟦to confirm under the current rules⟧). A startup cost, paid once; the debt village's deficit is paid every month.

\[ KADER  
**Step 2.** Alive: debt 512†, SuMSy 512†. Public debt at month 120: debt 253,000†, SuMSy 0 (peak 4,060‡ in month 17‡, repaid by month 46‡ in 10‡ runs of 10). Prices a year: debt +6.7†, SuMSy ⟦ ⟧. Unemployed: 191† / ⟦ ⟧. ⟦Ten-run means to follow.⟧
\]

### Steps 3 to 7. Interest, theatres, bonds, a charge on idle money

Interest on savings, two theatres, then four; bonds so that the government can borrow from its citizens instead of its bank; a monthly charge on idle balances in the debt village too, for symmetry. None of it changes who eats. Two things do change. The bonds move the debt village's public debt from the bank's books to the villagers' savings, and shrink its money supply by about four fifths†; the debt itself grows as before. And the theatres, in the debt village, keep failing: one† of the four is left at step 8, and what happens to a failed firm's loans turns out to matter more than the theatres (§11).

### Step 8. Owners and a stock market

Firms get owners, and shares that trade. In the SuMSy village the money had been spread almost evenly; with shares it gathers. The gap between the richest tenth and the poorest more than triples, from 23‡ to 78‡ meals, though it stays far below the debt village's 216‡. (⟦Under the current rules, in the levy-and-dividend village — see §12 for why.⟧) The money system is half of the story; ownership is the other half.

### Step 9, a side step. Cooperatives

Half the firms as cooperatives, open to anyone at par, with the same dividend for every member. They take part of the SuMSy gap back, to 63‡ meals, and cost nobody their bread.

### Step 10. A public reserve

The government keeps a reserve and cuts taxes when it has more than it needs. In the SuMSy village this is the step at which the parking tax falls to what the village needs and no further.

### Step 11. A tax policy and a tax on bread

The government raises every tax when it is short and lowers them when it is not, and a tax on bread and tickets is among them. In the debt village the tax on bread does what no other rule in this report does: it kills. 475‡ of five hundred and twelve are alive after ten years, and 310‡ in the version-3 regime of the run before. The parking tax, at every level tried, kills nobody. The difference is between taxing a thing people cannot avoid and a thing they can.

### What the ladder says

Two villages, the same at every step but one. The debt village lives from step 2 on because its government borrows, every month, and never stops. The SuMSy village lives from step 0, borrows once, and repays. Everything else on the ladder, the theatres, the bonds, the shares, the reserve, moves the figures a little and the story not at all. What moves the story is in the next five sections, and none of it is a step: it is what happens when prices are allowed to move, when they are not, and when the village finds work for its idle third.

## 8. What the debt is for

Hold every price in the village still. Not one baker raises the price of a loaf, not one worker asks for more, for ten years; only the amounts change. Can the village live? It can, in both moneys: everyone eats, at step 2, at step 8, at step 10.

And the debt village's government still borrows about 2,500† a month, every month, for the whole ten years. With no inflation whatsoever its debt grows in a straight line, to 287,000† by year ten. The SuMSy government owes nothing. So the deficit is not a price phenomenon. It is the money needed to feed the third of the village that has no work, and in a village whose money is someone's debt, that money has to be borrowed into existence every month. In the SuMSy village the same money is the guaranteed income, and nobody borrows it.

The unemployed third is the same in both villages, at fixed prices and at moving ones. The money does not create the jobs. It decides how the people without one are fed: by a debt that grows, or by an income that does not.

\[ KADER  
**Fixed prices, steps 2, 8 and 10.** Alive: 512 / 512† at every step. Unemployed: debt 176–193†, SuMSy 128–193†. Public debt at year 5 → year 10: debt 136,000 → 287,000†; SuMSy 1,000 → 0†. Money supply: debt 87,000–206,000†, SuMSy 130,000†. (Steps P2, P8, P10 — ⟦ten-run means⟧.)
\]

## 9. What prices do with the debt

Now let prices move, by the rules of §5. The same deficit shows a different face, and which face depends on two things people choose: how much they will overpay when bread is short, and how far they will let their wage fall.

**When people can overpay and nothing holds them back,** the borrowed money chases the same bread. Version 3's village, where a hungry buyer paid double and a full theatre paid any wage, ran at 15‡ percent a year and more, and at 32† where the theatres set the wage. The public debt doubled in nominal terms and the money supply with it.

**When people overpay by a fifth at most and wages fall when work is scarce,** the debt village deflates. A third of its people idle, wages that fall each time someone loses a job, bread that goes unsold: prices drop a percent or two† a year once employers keep their workers, and up to ten† when every job is up for grabs each month and the wage level falls through who is hired rather than through cuts to anyone in work. The debt does not fall with them. Every unit of it weighs more as prices fall, and by year ten the village owes, in bread, ⟦ ⟧ times what it owed at the start. That is the debt deflation Irving Fisher described in 1933, and the village walks into it with its books in better order every year.

**The SuMSy village, on the same rules, holds its level** within a percent or two a year in every configuration tried. The guaranteed income is a floor under spending and the parking fee a ceiling on hoarding; between them the price level has nowhere to run. The one exception is land, and it gets its own section.

\[ KADER  
**Prices a year.** Overpay up to 1.1× / 1.3× / 2× at step 2 (debt): −1 / +6 / +15†, with public debt 201,000 / 282,000 / 500,000† — the dial sets the pace, the debt rises at every setting. Step 8 at 1.2×: debt −10† (floor one month) / −4.5† (three months); SuMSy −1.4† / +4.8†. Three months halves the debt village's deflation and gives the SuMSy village 5 % a year of inflation; the ladder uses one month and reports both. The public debt in loaves of bread at year 10 against year 1: debt ⟦ ⟧. (Steps W2, W8; the floor sweep ⟦to add⟧.)
\]

## 10. Full employment

The village has work for two thirds of its people, whichever money it uses, because the villagers want a meal, a cushion and a night out, and once bread is cheap there is nothing more they ask the village to make. To employ the rest we gave it what every real economy that employs its people has: bread cheap enough to leave money over, a service that absorbs labour and covers its costs, people who want two nights out a month instead of one, and firms that come back when they fail.

Both villages then employ 73 to 85† percent of their people, and the rest is a floor set by what the villagers want. In the debt village, with prices held still, the budget nearly balances: taxes cover 94† percent of spending in the last year, and the debt levels off at about 50,000†. The deficit was the unemployment. In the SuMSy village the government never had a deficit to close.

Then let prices move, and the balance does not hold. The productive village deflates in both moneys, 13† percent a year in the debt village and 9† in the SuMSy village, because plentiful bread and satisfied wants push every price down. The debt village loses 13† villagers, churns through 79† failed firms and ends with its poorest tenth in debt; the SuMSy village keeps everyone, loses no firm, and its poorest tenth holds 53† meals. Give the debt village full employment through public jobs instead, forty percent of the village on the public payroll, and the public wage falls with the deflation to a fraction of a loaf: nobody is unemployed and a quarter† of the village starves. A job at a collapsing wage feeds no one.

\[ KADER  
**The productive village (V8): four loaves a grain, bread at 3, theatres needing a worker per customer at a ticket of 5, two tickets a month wanted, failed theatres restarted. Fixed prices†:** alive debt 511 / SuMSy 512; unemployed 27 % / 15 %; public debt 53,000 / 0; firms failed 132 / 0. **Free prices†:** prices a year −13 / −9; alive 499 / 512; poorest tenth −3.6 / 53 meals. Public jobs 40 % at fixed prices (U8, UP8)†: with each government raising its own taxes until the budget balances, the debt village's taxes reach their ceiling and 192 villagers live; the SuMSy parking tax reaches 4.9 % a month and 512 live. ⟦Ten-run means to follow.⟧
\]

## 11. Where the debt village's money comes from when no one borrows

Why do the debt village's theatres keep failing, and why does it matter? A theatre that cannot cover its wages goes under; its loans are written off; the money those loans created stays in circulation with no debt behind it; and the bank's loss is made good by a government that borrows to do so. Then someone with savings starts the theatre again, and the cycle repeats. In the productive village at fixed prices, under the rules of late September, 58,500† of the 96,000† public debt was bank bailouts, and the hundred failures are not a defect of the theatres but the way the debt village's private sector gets its money.

In the SuMSy village the same theatres never fail. Every villager has the guaranteed income to spend on a seat, so the theatres run on a margin of 27† percent instead of 5†. No loan creates money there, so no default creates any either, and there is nothing to bail out.

Three rules were tried on the banks because of this, and the report keeps all three: banks pay interest on deposits only from what lending has earned, above an eight percent reserve; a failed firm's bank loans pass to its owners, who are written off after six months if they can pay nothing; and the government stands behind the banks only where there is a government. The first cut the debt village's inflation at step 8 from 25† to 9† percent a year in the regime before the theatres were bounded. The second changed almost nothing: the owners have no more than the firm had.

\[ KADER  
**Bailouts and write-offs, month 120.** Step 8†: debt bailouts 0–74,000 depending on the bank rules, loans written off 55,000†, firms failed 19–31†; SuMSy 0 / 0 / 0†. V8 at fixed prices†: debt bailouts 58,500 of public debt 96,000 (late-September rules; 0 of 53,000 under the current ones); theatres' margin 5 % against 27 %. ⟦Ten-run means to follow.⟧
\]

## 12. Land

Land is the one thing money does not price the same way in the two villages. In the debt village a plot is worth its rent capitalised at what a deposit earns: about 44† months' rent, and it changes hands at that. In the SuMSy village money that loses value is never a reason to sell land, so nobody sells, and the rare plot that comes to market, through an inheritance or a move, goes for whatever the richest bidder has: 1,400† months' rent, about 1,700 loaves. Silvio Gesell saw this a century ago and paired his melting money with a levy on land. The village confirms him. With a levy on land set to the cost of holding money plus a small margin, and the proceeds paid out to every villager as a dividend, land trades at the debt village's price, the government owes nothing, and the gap between the richest and poorest tenth is the smallest of any village on the ladder: 54† meals.

Two warnings follow. Without the levy, the SuMSy village's rich–poor gap in meals measures the land runaway and nothing else, and this report quotes the levy-and-dividend village for the SuMSy distribution. And a levy that the government cuts when it does not need the revenue brings the runaway back: the levy must stay and the surplus be paid out, or land is hoarded again.

\[ KADER  
**Land, month 60–120†.** Price in months' rent: debt 44, SuMSy without levy 1,400, with levy and dividend 49. Land held by households: 99 / 97 / 82 %. Rich–poor gap: 83 / 1,560 / 54 meals, poorest tenth 0.3 / −0.6 / 3.1. ⟦Ten-run means at month 120 to follow.⟧ The levy: parking fee + parking tax + 0.25 % a month on the value of land; the dividend: the government's surplus paid out per head. (Steps L, LD.)
\]

## 13. Three policies, tried

**Austerity.** From year five the benefit falls from two loaves to one over six months. The debt grows at half its pace, and the benefit bill comes close to the taxes. Thirty people go hungry at the worst month, the poorest tenth ends under water, and prices fall faster, so that the debt which remains weighs more. The books look better; the village is poorer in every real measure.

**A ceiling on public debt.** The government cuts its spending whenever its debt exceeds a year's output. At one year's output it leaves 136† hungry and the debt still growing; at half a year's, 323† of five hundred and twelve are dead. A debt ceiling in a village whose debt is the cost of its unemployment is a rule to starve the unemployed.

**The parking fee as a lever.** A higher fee lowers the money each villager settles at, and with it the price level, so that the same guaranteed income buys more bread. At three or four percent, with starting prices to match, every villager in the SuMSy village started at its full money stock lives, where at two percent 27† died. It is the SuMSy village's monetary policy, and it is the one lever in this report that moved a result without moving a structure.

\[ KADER  
**Austerity, step 8, from month 60†:** debt growth over the last five years 54,000 against 117,000 without; benefit bill 13,200 against taxes 11,800; 30 hungry at the worst month; poorest tenth −0.6 meals; prices −3.5 % a year against −1.6 %. **The debt ceiling, step 2†:** at 1× yearly output, spending scaled to 55 %, 136 hungry, prices still rising; at 0.5×, 189 alive. **The fee, full-stock SuMSy village at step 8†:** 2 % → 485 alive, 3 % → 512, 4 % → 512, with starting prices scaled to the money stock; without that scaling the higher fee only hurts. ⟦Ten-run means (A8, A10, D, F8, FF8) to follow.⟧
\]

## 14. A public investment

Governments build things that pay back late or never, and the village was given one: a public transport line. For five years, five percent of the village's labour works on it at the public wage, and nothing comes back. Then the same workers run it, and every villager wants one ride a month, bought if there is money left after bread, at half a loaf a ride. The fares are the government's.

The two villages build it at the same cost. What they earn from it differs by the same thing that runs through this report: who can pay. In the SuMSy village, where every villager has the guaranteed income, 340† of them ride each month, and within five years of opening the line has paid for itself with a third to spare. The government borrowed its citizens' savings to build it and paid them back. In the debt village 163† ride and 346† cannot afford to, and the line has earned back barely half its cost by year ten. Its government's debt ends lower than without the line all the same, because the jobs cost it less in wages than the idle cost it in benefits. In both villages the line employs people who had no work: unemployment falls by five to six† points.

A public service earns its keep where the public can pay. That is a sentence about demand, and in this village the guaranteed income is what gives the public the means.

\[ KADER  
**The public transport line (T8, T10), ten-run means.** Building and running cost over ten years†: debt 23,100, SuMSy 24,800. Fares by month 120†: 13,000 / 34,400. Rides a month at the end†: 163 / 340; villagers unable to afford one†: 346 / 172. Unemployment with and without the line†: debt 29 / 34 %, SuMSy 20 / 26 %. Public debt at month 120 with and without†: debt 129,000 / 143,000, SuMSy 0 / 0 (borrowed at month 60: 5,000, repaid). ⟦Ten-run means to follow.⟧ Settings: 5 % of capacity for 60 months at the public wage, then operating; fare half a loaf; one ride a month wanted per villager.
\]

## 15. Greed, and the one percent

Make a quarter of the villagers greedy, or all of them, and the SuMSy village still feeds everyone: its bakeries go bankrupt and are started again, some fifty‡ times in ten years, and everyone eats. Make one villager in a hundred a hoarder, and the two moneys answer differently. In the debt village hoarding does not pay: idle money earns almost nothing and the hoarders end with half the average wealth. In the SuMSy village hoarding pays four times over, because money that melts drives the hoarder into land and shares, and those appreciate. The levy on land is the answer to that too.

Give the village gold, a hundred grams a head, held at the start by the richest tenth, yielding nothing and costing nothing to keep, and the same thing shows from the other side. Under debt money a gram ends at ⟦37⟧ loaves; under SuMSy, where idle money loses value and gold does not, at ⟦430 to 700⟧ loaves, twelve to twenty times as much, and the richest tenth still hold almost all of it. That is where a SuMSy village's spare money goes when it can go nowhere else. It changes nobody's bread: gold feeds no one and turns into bread only if someone pays money for it, which is why this report keeps gold out of its measures of wealth and reports it beside them, in grams and in what it would fetch. Land is different, because land yields; gold is a bet on the next buyer, and the village can let those who want it have it.

\[ KADER  
**The 1 % hoarders (H8, HLD10)†.** Top 1 %'s share of net wealth: debt 7 %, SuMSy 5 %, SuMSy with levy and dividend ⟦ ⟧ %. The hoarders' wealth against the mean: 525 against 1,006 / 17,800 against 4,400 / ⟦ ⟧. ⟦Ten-run means to follow.⟧
\]

## 16. What this shows, and what it cannot

It shows a village in which the money that feeds the idle third is borrowed every month, and what that borrowing becomes when prices can move: inflation if people will overpay and no one holds them back, deflation under a fixed debt if they will not and wages fall. It shows another village in which the same money is paid as an income, owes nothing in steady state, repays the one debt it incurs, and holds its price level in every configuration but one: land, which needs a levy. It shows that unemployment is not the money's doing, and that full employment does not save the debt village once prices move. It shows that a public investment pays for itself where the public can pay, and that the guaranteed income is what makes the public able to. It shows which rules killed: the tax on bread, the debt ceiling, the full-house theatre allowed to set the village's wage.

It cannot show what a real economy does, with a thousand goods, foreign trade, a central bank, and people who want more than two nights out. And it rests on one assumption that runs through every comparison in it: that people behave the same way under SuMSy as they do under the money we have. The villagers of both villages overpay the same when bread is short, hoard the same when they have spare money, want the same night out, and refuse the same wage cut. They may not. A person whose income arrives every month without fail, and whose savings melt if left idle, may hoard less, lend more freely, work for other reasons, or price what they sell differently; nobody knows, because no such village exists to ask. This report holds behaviour fixed so that whatever differs between the villages can be laid at the money's door. Where behaviour would differ, the comparison is only a starting point. Every number here rests on a rule someone chose, and the rules that mattered most were the ones about how people set prices, which this report calibrated to a few percent a year and reports in every alternative. Ten runs of one village are evidence of mechanisms, not forecasts.

## 17. The ladder's answer, for policy makers

Most of what governments argue about, tax rates, interest rates, the coupon on their bonds, the reserve their banks must hold, moved this village very little. What moved it was the plumbing: whether money is a loan or an income, whether land can be hoarded, whether the idle can be customers. A debt-money village can balance its books at full employment and fixed prices, and only there. The rest of the time it chooses between a debt that grows and prices that fall.

## Glossary

**Bailout.** The government putting money into a bank whose losses have eaten its equity, so that depositors are not hurt. In the debt village the government borrows to do it.

**Benefit.** Two loaves a month, at the going price of bread, paid by the debt village's government to anyone without work. The SuMSy village has none; everyone there receives the guaranteed income instead.

**Capital reserve.** The eight percent of its private loans a bank keeps as its own money, as the Basel accords require. Loans to the government need none.

**Cooperative.** A firm owned by its members, who join by buying one share at par and receive the same dividend each.

**Cushion.** The thirty units every villager keeps before spending on anything beyond bread. Under SuMSy, money up to the cushion pays no parking fee.

**Debt ceiling.** A rule that cuts public spending whenever the public debt exceeds a set multiple of the village's yearly output.

**Deflation.** Prices falling across the village, year after year. The debt it leaves behind is fixed in money, so it grows heavier in bread.

**Guaranteed income.** Five units of new money a month, paid to every villager in the SuMSy village whether they work or not.

**Invoice.** A firm's bill to another firm, paid the following month. A firm whose overdue invoices reach a tenth of its monthly turnover, and that can no longer borrow, is wound up.

**Land dividend.** What the SuMSy government pays out to every villager, equally, from a levy it does not need: the surplus returned instead of the levy cut.

**Levy on land.** A monthly charge on the value of land, set at the cost of holding money plus a small margin, so that land is no better a store of value than money.

**Money that someone owes.** In the debt village every unit of money was created by a loan and is matched by a debt; repaying the loan destroys the money.

**Owners' guarantee.** When a firm is wound up, its bank loans pass to its owners in proportion to their shares. An owner who pays nothing for six months is written off.

**Parking fee.** Two percent a month of a SuMSy villager's money above the cushion, which simply disappears. It is not a tax: nobody receives it.

**Parking tax.** One percent a month on the same money, paid to the SuMSy government. Its only tax.

**Rich–poor gap.** The holdings of the richest tenth of villagers less those of the poorest tenth, measured in the meals they would buy. It is always given with the poorest tenth's own holding, because a small gap can mean that the poor have something or that nobody has anything.

**Startup cost.** The SuMSy government's one debt: what it borrows from its citizens while the new money is still filling up the village, and repays once the parking tax covers its spending.

**Winding up.** What happens to a firm that cannot pay its bills: its assets are sold, its loans pass to its owners, its unpaid invoices are written off, and its ovens stand idle until someone starts it again.
