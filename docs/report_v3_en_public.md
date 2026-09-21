# The Bread Economy

*What happens to a village when you change its money*

Version 3 — 21 September 2026

Some passages are set apart in frames like this one. They hold the numbers and the mechanics for the reader who wants them; the running text can be read without them.

\[ KADER  
**How to read the numbers in this report.**  
Everything here comes from a computer simulation. The village is run for a hundred rounds, ten times over, with a different roll of the dice each time; the figures given are the average of those ten runs, and where one run went badly wrong the worst one is mentioned as well. A round is best thought of as a month. There are sixty-four villagers. "Alive" means alive at the end of the hundred rounds. Whenever a result rests on a rule the author chose rather than something measured in the real world, the text says so. The code and every result are public: github.com/HapponomyOrg/BreadEconomySim.jl.  
\]

## 1. A village, twice

Imagine a small village. Sixty-four people live there. Some own land, most do not. Two farms grow grain, two bakeries turn it into bread, and later on two theatres give people something to do in the evening. Everyone needs two loaves a day. Go three days without any bread at all and you die.

Now imagine the same village built twice, with the same people, the same fields, the same ovens, the same habits — and one difference: where its money comes from.

In the first village, money is what it is for us today. It comes into being when a bank makes a loan and disappears again when the loan is paid back. Every euro in someone's pocket is a euro that someone else owes. The government pays for a few public jobs and a small allowance for people without work, out of taxes and, when the taxes fall short, out of borrowing.

In the second village, every person receives a fixed sum of new money every month, whether they work or not. Money that sits idle above a modest cushion slowly melts away — a small percentage each month simply disappears. The government's income is a tiny slice of that melting. Nobody owes anyone for the money in their pocket. This second arrangement has a name, SuMSy, and it is the alternative this report is about.

The report builds the village up one piece at a time. First there is nothing but fields, ovens and hungry people. Then a government is added, then interest on savings, then a theatre, then the possibility for the government to borrow from its own citizens, then a second theatre, then shareholders and a market where shares change hands, then a set of price rules that make the village's markets behave more like real ones, then a public reserve, and finally a tax policy that tries to keep the government's books in order. At every step both villages get the same addition, and at every step we look at the same things: who is alive, who is hungry, what a loaf costs, and how much the government owes.

At the end we do something unkind: we make some of the villagers greedy and see which village breaks.

## 2. Two kinds of money, in plain words

**Money as debt.** Two banks lend to the farms, the bakeries, the theatres, the households and the government. A loan puts money into the world; paying it back takes it out again. Interest is how the banks live. The government taxes wages at fifteen percent, pays wages for about a tenth of the village's work, gives two loaves a month to anyone without a job, and borrows whatever it is short. Nothing stops it borrowing more.

**Money as a shared allowance.** A money authority puts five units into every living person's account each month. Whatever anyone holds above a cushion of thirty loses two percent a month — it is not taxed, it is gone. A further one percent on that same amount goes to the government, and that is the government's only income; nobody's wages are taxed. Because of how it is made and unmade, the total amount of money in this village settles at a level set by those two numbers, the allowance and the melting rate, and nothing else can move it — not prices, not lending, not the government. Banks exist but only pass existing money between savers and borrowers. Land is paid for in instalments.

Both villages start from the same prices and with the same habits. Everything that differs afterwards, differs because of the money.

\[ KADER  
**The parameters behind the two villages.**  
Debt village: wage tax 15 %, capital income tax 15 %, public employment 10 % of total labour, unemployment benefit two loaves (never less than two), bank lending rate cost-covering and capped at 5 % a month, government borrowing unlimited, bonds from rung 5.  
SuMSy village: guaranteed income 5 a month, demurrage-free buffer 30, demurrage 2 % a month on balances above it, a 1 % surcharge on the same base to the government, no income tax, bank rate −1 %, land bought on instalment.  
Both: one price vector at the start (bread 5, grain 5.2, wage 3.92, rent 0.75, ticket 2), chosen so that each link in the chain can pay a worker one meal a month; the scripts refuse to compare villages that start from different prices.  
\]

## 3. Who lives there

Sixty-four people, each able to do up to four units of work a month. Sixteen of them own the land, a unit and a half a head. Two farms rent that land and hire workers to grow grain. Two bakeries buy the grain and hire workers to bake it — two loaves to a grain. Two theatres, from the seventh step up, hire workers to put on shows; one worker can entertain two and a half people. Two banks. A government. And, in the second village, the money authority.

Later in the story the farms, bakeries and theatres get owners: four founders each, whose shares can be bought and sold. On one side step, some of them become cooperatives instead.

## 4. A month in the village

The month starts with the banks setting their rates and the landowners letting their fields. The farms and the theatres hire. The grain comes in; the bakeries buy it and hire their bakers. Bread is baked. The government hires whoever is still without work, up to its tenth. Then everyone who has not yet got a meal goes to the cheapest bakery, and whoever has money left over after keeping a cushion for lean times buys a theatre ticket.

Then comes a step that matters more than it sounds: all the promises to pay made during the month are settled at once, netted against each other. A bakery that has sold bread can pay for the grain it bought with the money it is about to receive. Without this step — the report comes back to it — the debt village's bakeries go under in the first weeks.

After settlement, debts are serviced, taxes paid, profits handed to owners. In the SuMSy village the idle money melts. The government puts its reserve aside and, in the later steps, adjusts its taxes. Everyone eats. Whoever ate too little works less next month; whoever ate nothing for three months is buried. Old bread goes stale; prices and plans adjust for the month to come.

## 5. How the villagers decide

The villagers are not clever. They follow simple rules, the same in both villages, and the point of the exercise is to see what those rules do when they all run at once.

A baker bakes what sold last month plus a little extra. A seller asks a price and a buyer offers one, and they meet somewhere in between. A hungry person will pay more. Nobody sells for less than it cost to make. Everyone offers all the work they can, and asks for a wage that buys a meal. Everyone keeps a cushion of three meals' worth of money if they can, and borrows or dips into the cushion when they must.

Two of the rules deserve a closer look, because the first version of this report got them wrong and the whole story changed when they were put right.

**When does a price go up?** In the first version, a bakery raised its price the moment a single customer found no bread — one missed loaf in a hundred and up went the price by six percent. No real market behaves like that. Now the price rises only when the bakery has turned away at least one customer in twenty, and falls only when at least one loaf in twenty has stayed on the shelf. That small change is the difference between a village that starves and a village that does not (see the next section).

**Who does a cooperative serve first?** Cooperatives now come in three kinds — owned by their customers, owned by their workers, or open to anyone with money to spare — and a worker-owned firm gives its own members the work first, sharing it out among them when there is not enough to go round. That is how real worker cooperatives behave, and it changes what cooperatives do for the village.

\[ KADER  
**The behaviour rules, for the reader who wants them.**  
*Production:* target = last month's demand + 10 % (from rung 1); a theatre plans on expected ticket demand and may be capped at a number of shows with a seat for every villager.  
*Prices:* seller's ask and buyer's bid concede toward each other in six steps. A buyer's ceiling for bread is 1.3 × the recent price, higher when hungry; the seller's floor is unit cost, falling as bread ages. The ask rises 6 % when ≥ 5 % of demand went unserved, falls 6 % when ≥ 5 % of the offer stayed unsold; from rung 10 the posted ask never falls below unit cost (+5 % while the seller's reserve is short).  
*Work:* full capacity offered; reservation wage = one meal net of tax, lowered by hunger; employers hire one unit at a time in turns. Worker co-ops allocate to members first, in proportion to remaining capacity.  
*Money:* three meals' cushion; borrow or spend the cushion on a coin flip; land at a multiple of its rent.  
*Government (rungs 11–12):* a reserve of three months' expected spending; surplus above it lowers taxes; on a shortfall taxes rise to cover half of it, at most 2 % of revenue a month, with a lever per tax family deciding which taxes carry the change (the debt village's endpoint relieves wages entirely and lets a consumption tax carry the raise, up to twice its rate). Under SuMSy the "income" family is the demurrage surcharge; SuMSy never taxes income.  
*Eating:* two loaves a meal; one loaf costs a third of next month's capacity; three months with nothing is death.  
*Ownership:* shareholder firms pay dividends above a working reserve; shares trade at a forward valuation; founders keep 51 %. Co-ops: member (open membership at par, equal dividend), worker (membership through employment, surplus by hours worked, taxed as wages, a quarter locked in an indivisible reserve), consumer (membership through purchases, surplus rebated on what each member bought). Under SuMSy a member may pledge part of the demurrage-free buffer instead of paying money.  
\]

## 6. Why the rules matter more than the money — at first

Before the two kinds of money can be compared, the village has to work at all. Three things learned on the way are worth telling.

**The one missed loaf.** With the old price rule, the bare SuMSy village — no government, no theatre, nothing but the monthly allowance — lost about one person in six. The first report read this as a weakness of SuMSy. It was a weakness of the rule. Let the price react to one customer in twenty instead of one in a hundred, and nobody dies, bread stays at five instead of climbing to twenty, and wealth is spread almost evenly. The bare debt village, meanwhile, loses three people in four whichever rule is used: its problem is that money only comes through work, and there is not enough work.

**Rolling the dice properly.** A simulation with chance in it has to be run many times. The first report ran each village three times; this one runs it ten, and it draws its chance events from separate sources for each part of the model, so that switching on a feature in one corner of the village does not change the luck in another. Several of the first report's claims turned out to be one lucky run out of three. Where the ten runs disagree — some villages whole, some dead — the text says how many survived rather than giving an average that describes none of them.

**How much money a SuMSy village has.** The amount is fixed by the allowance and the melting rate. A village that starts with everyone holding only their cushion takes about five years to fill up to that level, and prices rise on the way — not inflation, just the water finding its level. Section 10 starts a village at the full level directly, which turns out to be the fairer test.

\[ KADER  
**Rung 0 in numbers, ten runs.**  
SuMSy, one-miss price rule: 53 of 64 alive (worst run 40), bread 20.7, wealth Gini 0.88. Same village, 5 % rule: 64 alive in every run, bread 5.1, wealth Gini 0.16, hunger halved. Debt village: about 15 alive under either rule. Random draws: eleven separate streams, one per subsystem, each seeded from the run seed and the subsystem's name. SuMSy money stock: each balance converges to buffer + income ÷ (demurrage + surcharge) = 197; the village's total to about 14,700; prices to about 1.35 × the starting vector.  
\]

## 7. The ladder

Now the village is built up, one step at a time. At each step the same thing is added to both villages, and the same questions are asked. The frame at the end of each step has the figures.

### Step 0. Bare bones
Fields, ovens, hungry people. No government, no allowance for the workless, no theatre.

In the debt village three people in four are dead within the hundred months. There is no work for most of them, and without work there is no money, and without money there is no bread. In the SuMSy village almost everyone lives: the monthly allowance is enough for a meal. (With the old price rule one in six died here; with the corrected one, nobody.)

\[ KADER  
Debt: 15 alive (worst 11), unemployment 6.8 of 64, bread 5.66. SuMSy: 53 alive (worst 40), unemployment 26.9, bread 20.7 — with the 5 % price rule, 64 alive, bread 5.1.  
\]

### Step 1. Planning ahead
Farmers and bakers now plan for a tenth more than last month's demand.

It does nothing for the debt village, whose problem is not supply. In the SuMSy village nobody dies from here to the end of the story. A lot of people are without work, because there is nothing to do in this village but grow and bake.

\[ KADER  
Debt: 16 alive, bread 4.94. SuMSy: 64 alive, unemployment 29.7, bread 3.39, cash Gini 0.09.  
\]

### Step 2. A government
Public jobs for a tenth of the village's work, two loaves a month for anyone without a job. The debt village pays for this with a fifteen-percent tax on wages; the SuMSy village with the one-percent slice of the melting.

This is the step that changes everything on the debt side. Everyone lives. But the government spends far more than the tax brings in, and borrows the rest — about three quarters of what it spends. Its debt reaches three times the village's yearly output. Everything that follows on this side of the ladder rests on that fact: **the debt village lives because its government goes into debt.**

On the SuMSy side the government has the opposite problem. Its slice of the melting brings in far more than the few public jobs cost, and the surplus piles up on its account — where, since it is idle money, it melts. Nobody minds yet.

\[ KADER  
Debt: 64 alive, unemployment 22.8, bread 4.37, public debt 21,354 (305 % of yearly output), the government spending 170 a month against revenue of about 45. SuMSy: 64 alive, bread 3.19, no debt, government surplus 72 a month, cash Gini 0.09.  
\]

### Step 3. Interest on savings
A small interest on deposits in the debt village. No visible effect at this size. SuMSy deposits earn nothing, and nothing changes.

### Step 4. A theatre
Somewhere to spend money on something other than bread.

In the debt village the theatre halves the government's monthly shortfall: it gives work to people who had none, and their wages are taxed. It also doubles the gap between the villagers who have money and those who do not — the theatre's owner is doing well. In the SuMSy village the theatre sells twice as many tickets, unemployment drops to a third, and the money stays as evenly spread as before, because it is everyone's allowance being spent, not a few people's profits.

\[ KADER  
Debt: 64 alive, unemployment 15.9, tickets 68.5 a month, bread 3.81, debt 12,269 (173 % of output), shortfall 87 a month, cash Gini 0.61. SuMSy: 64 alive, unemployment 9.8, tickets 126, bread 3.21, surplus 73, cash Gini 0.09.  
\]

### Step 5. Government bonds
The debt government can now borrow from its own citizens and not only from the banks.

Who lends changes; how much does not. Households put cash into bonds instead of tickets, ticket sales drop by a third, and in the worst of the ten runs a few people die. The SuMSy village has no borrowing to do.

\[ KADER  
Debt: 63 alive (worst 58), tickets 47.6, debt 12,302 (208 %), shortfall 95, cash Gini 0.33. SuMSy unchanged.  
\]

### Step 6. A charge on idle money
A small monthly charge on the money that firms hold beyond what they need to operate — the debt village's version of the SuMSy melting.

It trims the government's debt by a few percent and its monthly shortfall by a sixth. The SuMSy village barely notices a second melting.

\[ KADER  
Debt: 63 alive (worst 62), tickets 50, bread 3.12, debt 11,627 (211 %), shortfall 79. SuMSy: 64 alive, tickets 126, surplus 89. The first report charged 10 % a month on all a firm's cash; at ten runs that closed every bakery in the debt village by month 51, so the step was redefined as 2 % a month above the working reserve.  
\]

### Step 7. A second theatre
Two theatres compete, and tickets get cheaper in both villages. The debt village does not buy more of them: the money to do so is not there.

\[ KADER  
Debt: 64 alive (worst 62), tickets 48.7, bread 3.41, debt 12,490 (201 %), shortfall 94, cash Gini 0.28. SuMSy: 64 alive, tickets 126, bread 3.82, cash Gini 0.11.  
\]

### Step 8. Owners and a stock market
Every farm, bakery and theatre now belongs to four founders, and their shares can be bought and sold.

In the debt village, household money that used to buy tickets now buys shares, and ticket sales fall by a third. In the SuMSy village this is the biggest change on the whole ladder: ticket sales drop from 126 to 50, unemployment nearly doubles, and the money — spread almost evenly until now — gathers in the hands of whoever holds shares. Shares crowd out the theatre. Section 8 looks at why, and at how much of it depends on the settlement step described in Section 4.

\[ KADER  
Debt: 64 alive (worst 61), unemployment 19.2, tickets 34.9, bread 3.35, debt 13,637 (237 %), shortfall 96, cash Gini 0.34. SuMSy: 64 alive, unemployment 17.6, tickets 50, bread 6.69, cash Gini 0.45 (from 0.11).  
\]

### Step 9, a side step. Cooperatives
Four farms, four bakeries and one theatre become cooperatives; the rest keep their shareholders.

The cooperatives, and the cooperative theatre most of all, undo most of what the stock market did on the SuMSy side: tickets back up to 121, unemployment back down to ten, money spread nearly as evenly as before. Section 9 takes the different kinds of cooperative apart, because they do not all do this for the same reason.

\[ KADER  
Debt: 64 alive (worst 60), tickets 50.5, debt 12,318 (196 %), cash Gini 0.29. SuMSy: 64 alive, unemployment 10.4, tickets 121, bread 4.85, cash Gini 0.27.  
\]

### Step 10. Prices that respond
From here on prices move when bread runs short or piles up, as described in Section 5, and nobody sells below cost.

Bread gets cheaper in the debt village and the government's debt gets larger: firms that no longer sell at a loss employ fewer people and pay less tax. In the SuMSy village the money gathers further — these rules reward whoever holds stock when it is scarce. They are what will save the village from greed in Section 10, and they are not free.

\[ KADER  
Debt: 64 alive (worst 63), tickets 31.8, bread 2.96, debt 16,091 (320 %), shortfall 95, cash Gini 0.33. SuMSy: 64 alive, tickets 50.2, bread 5.69, cash Gini 0.60 (from 0.45).  
\]

### Step 11. A public reserve
The government keeps three months of expected spending in reserve, and whatever it holds above that it gives back by lowering taxes.

The debt government never has a surplus to give back, so nothing changes. **This is the best-surviving debt village on the ladder**: everyone alive, at the cost of a government spending almost twice what it earns and owing three times a year's output.

The SuMSy government, which had been hoarding a fifth of the village's money, finds that its slice of the melting only needs to be a twelfth of what it was. It cuts it, on its own, and the money it used to hold gets spent: more tickets.

\[ KADER  
Debt: as step 10 — 64 alive (worst 63), shortfall 95, debt 320 % of output. SuMSy: 64 alive (worst 63), tickets 59, the surcharge scaled to 0.08 of its statutory rate, reserve on target at 344, cash Gini 0.65.  
\]

### Step 12. A tax policy and a tax on bread
A six-percent tax on bread and tickets. When the government is short, it raises taxes a little each month to cover half the gap, keeping wages out of it and letting the tax on bread carry the increase, up to twice its rate.

The wage tax disappears; the bread tax doubles to twelve percent; the debt shrinks by a sixth and the monthly shortfall by a third. And eleven people who were alive at the previous step are now dead, because a tax on bread reaches exactly the person who could only just afford bread. **This is the least-indebted debt village that still survives**, and it is not the same village as the best-surviving one. Nothing found in this study gives both at once.

For the SuMSy village the step is meaningless: it has a surplus, so its policy cuts the slice of the melting to nothing and the bread tax to a quarter, and life goes on.

\[ KADER  
Debt: 53 alive (worst 46), tickets 15.7, bread 2.13, wage tax scaled to 0.01, consumption tax to 12 %, debt 13,488, shortfall 66, cash Gini 0.48. SuMSy: 64 alive, tickets 48, surcharge scaled to 0, consumption tax to 0.24 × 6 %.  
\]

### What the ladder says
The debt village needs a government that borrows. From the moment it has one, it lives on a shortfall of a third to three quarters of what the government spends, and every tax it can bear closes at most half of that gap (Section 12 sets out why). The SuMSy village needs nothing but its allowance and its melting: nobody dies from step 1 on, and there is no public debt at all. Its trouble is the reverse — a government that collects seven times what it spends until a rule tells it to stop. The two villages look most alike at step 8, when shares arrive: inequality, which had been high in the debt village all along, rises in the SuMSy village to meet it. Cooperatives undo most of that.

### Two things that turned out to matter more than they should

**Settling accounts.** The step in Section 4 where all promises are netted keeps the debt village's bakeries alive: without it a bakery must pay for grain before it has sold bread, and goes under. In the SuMSy village the same step does something else. Without it, firms are refused credit twice as often, hold less cash, and pay no dividends for the first ten months — so the stock market barely trades, the village sells three times as many tickets, and the money stays spread. A bookkeeping rule is deciding who ends up rich.

**Inherited money.** A debt village whose starting cash is not owed to anyone behaves like the ordinary one at every step. Inheritance changes who owes the banks, not what the village does.

\[ KADER  
SuMSy without clearing: credit refusals 1,157 by month 10 against 583; enterprise cash ~550 instead of 900–1,300; dividends 0 in months 5–10; share trades 0–8 a month after month 6 against 60–80; tickets 125 against 38 at month 100; cash Gini 0.18 against 0.44.  
\]

## 8. What a stock market does

Step 8 gave every firm owners and let the shares trade. To see which part of the market does the damage, it was rebuilt five ways: with and without a spread in what people expect shares to yield, with and without buying on credit, with and without the hope of selling on at a profit. It made no difference. Once households can hold shares, ticket sales halve and the money gathers, whichever way the market is built.

Three things are new since the first report. The effect needs the settlement step — without it firms cannot build up the profits from which dividends are paid, and the market goes quiet. The responsive prices of step 10 make the gathering worse. And a tax on wealth, which one might expect to spread the money again, does so only by eating the wealth it taxes: the shares lose their value faster than the tax brings anything in.

\[ KADER  
Five market variants, SuMSy, ten runs each: tickets 47–52 a month and cash Gini 0.49–0.52 in all of them, against 126 and 0.11 without a market. Responsive prices: SuMSy cash Gini 0.45 → 0.60 with the market; 0.44 → 0.71 in a no-greed village with the buyer ceiling raised as well. Wealth tax at 25 % a year on the debt village: wealth Gini 0.70 → 0.43, base 3,800 → 1,300, revenue never above 27 a month.  
\]

## 9. Cooperatives

The first report's cooperative was the simplest kind: anyone with money to spare could join any co-op, and every member got the same share of the profit. Within a year or so nearly everyone was a member of every co-op, and the equal dividend was, in effect, a second monthly allowance paid out of the firms' profits. Most of what cooperatives did for the SuMSy village at step 9 came from that.

Real cooperatives are not usually like that, so this version adds two more kinds. A worker cooperative belongs to the people who work in it: you join by being hired, you pay for your share out of your wages, the members get the work first and share it out among themselves when there is not enough, and the profit is divided by hours worked. A consumer cooperative belongs to its customers: you join by shopping there, the profit comes back as a rebate on what you bought, and members go to their own co-op first because they know the rebate is coming.

Does it matter which kind? Some. With the simple kind and a cooperative theatre, the SuMSy village recovers almost all the tickets it lost to the stock market. With worker-owned farms and bakeries and a customer-owned theatre it recovers most of them. A worker-owned theatre is the one bad idea on the list: a theatre needs only a dozen workers, and dividing its profit among them makes those twelve rich. A customer-owned theatre spreads the same profit across sixty.

\[ KADER  
SuMSy, step-8 village, ten runs. Member co-ops with a co-op theatre: tickets 119, cash Gini 0.32. Worker farms and bakeries with a consumer theatre: tickets 88, Gini 0.38. Worker theatre: Gini 0.59. Whether members are served first changes little at this size. Buffer-pledge membership (SuMSy): 101 members against 84 for money, the exemption conserved, distributional effect within noise. A shareholder firm short of capital makes its founders borrow personally without an affordability test; a cooperative must borrow itself and is tested — `cooperative_founding = :symmetric` removes the asymmetry and is not used above.  
\]

## 10. Greed

So far the villagers have been modest: they eat, they go to the theatre now and then, they keep a cushion. Now some of them are made greedy. A greedy villager spends everything above the cushion, every month — half the time on land, shares or plain hoarding, half the time on loaves and tickets, up to ten loaves at a time. This is a rule, not an observation; nobody has measured how greedy people are. The point is to find out what breaks.

The first report put greed into the whole village and found that the SuMSy village died and the debt village did not — its greedy simply had no money to be greedy with. That still holds at ten runs. What was wrong was the explanation.

**How the greedy SuMSy village dies.** The first report said: the price of bread runs away from the fixed allowance. It does not — people go hungry while bread is still cheap. What happens is this. The greedy owners of the theatres get rich on dividends and spend them on tickets. The theatres hire more and more; a theatre can pay a worker three times what a bakery can, because one worker entertains two and a half people while one baker feeds two. By the twentieth month every pair of hands in the village is employed and nearly half of them are at the theatre. The bakeries cannot get workers, bread runs short, the hungry work less, less bread still, and the village starves in a hall full of shows. And the bakeries cannot buy the workers back, because nobody will pay more than a third above last month's price for bread, so scarcity never reaches the price, and the price never reaches the wage.

Giving the village more hands or more land does not help: the theatre takes the extra in the same proportion. Capping the theatres — one show a night, a seat for everyone — stops the drain and uncovers a second death underneath. Now the greedy buy bread instead, the bakeries bake for it, not all of it sells, and the price falls a little every month until a loaf sells for less than the grain in it. Then the bakeries stop buying grain, and a village with full fields and full ovens has no bread at all within a month. Two ways to die, one cause: nobody responds to what the price is saying.

**Prices that respond.** Let a hungry buyer pay up to double last month's price, let no one sell below cost, and let prices move only on real shortages and real gluts — and the greedy village lives, in every one of ten runs, with as many theatres as you like. The village with only its richest quarter greedy lives too. And when the village is started with its money at the full level (Section 6), the greedy quarter still lives, without a single hungry month — but a village where *everyone* is greedy dies of exactly the price spiral the first report described: every villager starts with money to burn, bread is short every month, the price climbs by six percent a month for years, and the allowance of five faces a loaf at eighty-five.

So the honest sentence is this. Greed in a quarter of the village is survivable if prices are allowed to move. Greed in the whole village, where everyone wants ten loaves and endless tickets forever, is not — and that is the strongest assumption in this model, not a property of the money.

**What helps and what does not.** Rationing — two loaves for everyone before anyone gets a third — keeps the greedy village fed. A ceiling on wages does not (the first report's one lucky run out of three). Two prices for bread do not. More capacity does not. Where the government puts its surplus matters: give it back as a tax cut and the greedy village lives; hand it out equally to everyone and most of it goes straight back to the greedy, and the village dies in six runs of ten. A tax on bread does nothing against greed and, above about ten percent, kills on its own. A tax on wealth is the one tax that helps: with the richest quarter greedy, it lifts the number of surviving runs from two or three in ten to seven, and the rest of the village goes to the theatre more, not less — but only because the government sits on the proceeds. Paid out, they would return to the greedy.

\[ KADER  
Universal mixed greed (hoarding 0.5), SuMSy, step-8 village, ten runs, survived: report prices 1; capacity 5 or 6, land 2: 0–1; theatre capped at one show: 0 (deflation death), two shows: 4; responsive prices (thresholds, cost floor, ceiling 2.0): 10 at any theatre capacity; from the equilibrium start: 0. Richest quarter greedy: report prices 2–3; two shows with thresholds and floor 10; responsive from the equilibrium start 10, no hunger. Measures: rationing 64 alive; wage ceiling 0 of 10; two prices 0; land + capacity 0–1. Public surplus on the responsive greedy village: tax cut 10 of 10, per capita 4 of 10. VAT: scaled away by the tax-cut rule; kept, 20 % kills the no-greed village (2.4 alive) through the buyer ceiling. Wealth tax on the greedy quarter: 2 % → 3 of 10, 10 % → 5, 25 % → 7, tickets 44 → 76. Indexing the allowance to bread: harmless without greed, a spiral with it (money 22–33 thousand and rising).  
\]

## 11. Taxes, and why the debt village's books do not balance

The debt village's government spends nearly twice what it earns from the first month it exists. Can that be fixed? A good part of this study went into trying.

Raising the wage tax works up to about thirty percent and then kills. Worse, it hardly helps even where it works, because most of what the government pays for — its own workers' wages, the bread allowance — is measured in loaves, and a higher tax on wages pushes up the price of everything, loaves included. Belgium's actual income-tax schedule, applied to the village, kills it within two years.

A tax on bread and tickets does better, for a reason worth understanding: it does not push up the government's own wage bill. Shift the burden from wages to bread, and the shortfall falls by two thirds. But every point of tax on bread reaches the people who can only just afford it; six percent costs about two lives in sixty-four, twelve percent fifteen.

A tax on land and shares brings in almost nothing — the village's wealth is small, and the tax shrinks it — while it does make the village more equal.

Four different ways of combining the taxes were tried, with the government raising and lowering them a little each month as its books required. They all found the same frontier. Take the tax off wages and everyone lives, with a government spending half again what it earns. Balance the books and fourteen people are left. There is no setting that does both.

\[ KADER  
Debt village, ten runs. Wage-tax ceiling sweep: 30 % → 60.5 alive, shortfall 82 → 48; 35 % → 33.6 (worst 0); 45 % → 3.8. Progressive schedule (25/40/45/50 %, 13 % social contribution, 7 % municipal): 3.9 alive, deaths from month 5. VAT 6 % alone: 59.1 alive (worst 54), shortfall 37; 12 %: 49.1; policy shifting the burden to consumption (lever −3 on income): 60.9 alive, wage tax 0, VAT 12 %, shortfall 66. Wealth tax: revenue ≤ 27 a month at any rate, alive 61 → 51 at 25 %. The one balanced budget found (all taxes raised together): 14 alive. Combining mechanisms tried: revenue-weighted scaling, six-way sliders, a share target, per-family levers with shift-then-move.  
\]

## 12. What this shows, and what it cannot

It shows that a village on debt money needs a government willing to go deep into debt, and that no tax the village can bear will get it out. It shows that a village on a shared allowance and a melting rate needs no such thing: nobody starves and nothing is owed, though its government has to be told to stop collecting. It shows that a stock market gathers money in both villages, that cooperatives spread it again, and that the piece of plumbing which settles the month's accounts has more to do with who gets rich than it should. And it shows that greed breaks the SuMSy village only when prices are not allowed to move or when every single villager is insatiable.

It cannot show what people would actually do. The villagers follow rules; the greedy are greedy by decree; hunger is a number. Demand for bread is fixed at two loaves, and what people will pay is tied to what they paid last month, so every statement about prices here is a statement about a rationing rule. The government of the debt village can borrow without limit, which no real one can. Ten runs tell apart outcomes that differ by a few people, and no finer. And the whole thing is sixty-four people and two bakeries.

## 13. The stress test: greed on the best villages

The ladder ended on two debt villages — the one where everyone lives, and the one that owes the least — and their SuMSy twins. Into each of the four, greed is now introduced twice: first the richest quarter, then everyone.

The village where everyone lives keeps everyone alive under both doses, in both kinds of money. The debt village pays with its theatres: in every greedy run they close, because the greedy buy shares rather than tickets, and the dividends that would have bought tickets buy more shares. The village is fed and has nothing to do in the evening. The SuMSy village does the opposite with the greedy quarter: tickets double and almost nobody is without work, because its prices let the bakeries hold their workers and its allowance lets everyone else keep going out. With the whole village greedy it loses one run in ten — the price spiral of Section 10 arriving late — and keeps the other nine whole. On the first report's village the same greed killed nine in ten.

The village that owes the least is the fragile one. In both kinds of money it loses a run in ten to the greedy quarter — with twenty-odd survivors in the run that goes wrong — and the debt version loses seven more people to universal greed than its better-fed neighbour does. A budget squeezed toward balance, with no wage tax and a twelve-percent tax on bread, has no slack left when the greedy pull workers and money out of the food chain.

So the two ends of the ladder are a trade-off twice over: the village that owes the least is also the one greed breaks first.

\[ KADER  
Ten runs; alive of 64 (worst) · runs whole · tickets · cash Gini.  
Debt, step 11: no greed 64 (63) · 10 · 32 · 0.33; greedy quarter 64 (63) · 10 · 0 · 0.27; everyone 64 · 10 · 0 · 0.36.  
Debt, step 12: no greed 53 (46) · 3 · 16 · 0.48; greedy quarter 55 (21) · 4 · 0 · 0.40; everyone 57 (45) · 3 · 0 · 0.45.  
SuMSy, step 11: no greed 64 (63) · 10 · 59 · 0.65; greedy quarter 64 · 10 · 113 · 0.28; everyone 58 (0) · 9 · 37 · 0.32.  
SuMSy, step 12: no greed 64 · 10 · 48 · 0.65; greedy quarter 60 (25) · 9 · 111 · 0.33; everyone 58 (0) · 9 · 36 · 0.30.  
\]

## Glossary

**Allowance (guaranteed income).** The five units every living villager receives each month under SuMSy.
**Cushion (buffer).** The thirty units a villager may hold before the melting starts; also the three meals' worth of money the villagers try to keep.
**Melting (demurrage).** The two percent a month that disappears from any balance above the cushion.
**Round.** A month.
**Run.** One hundred rounds with one roll of the dice; every figure is the average of ten.
**Settlement (clearing).** The step in which all the month's promises to pay are netted and settled at once.
**Shortfall (deficit).** What the government spends in a month beyond what it takes in.
**Step (rung).** One addition to the village on the ladder of Section 7.
