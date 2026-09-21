# The Bread Economy

*A plain-language report on a village that eats bread, under two kinds of money.*
*Version 3 — 21 September 2026. Sixty-four villagers, one hundred rounds, ten seeds per configuration, per-subsystem random streams. Source and results: github.com/HapponomyOrg/BreadEconomySim.jl.*

> This report describes a simulation. It shows what a set of stated rules does when they run together; it does not show what people do. Every number below is the mean of ten runs that differ only in their random draws, with the worst run in brackets where it matters. Where a result depends on a rule the author chose rather than measured, the text says so.

## 1. What this is, in one paragraph

A village of sixty-four people grows grain, bakes bread, runs two theatres and eats. Two loaves a round is a meal; three rounds without any bread is death. The village is built twice with the same people, farms, bakeries and rules and one difference: where its money comes from. In the first village money is created when a bank lends and destroyed when the loan is repaid, and the government pays for public jobs and unemployment benefit out of taxes and borrowing. In the second village — SuMSy — every person receives a fixed sum of new money each round, money above a personal buffer slowly dissolves, and the government's income is a small surcharge on that dissolution. The report adds one institution at a time to both villages, a *ladder* of twelve rungs, and reads off at every rung who is alive, who is hungry, what bread costs, and what the public purse owes. It ends with the best-surviving and the least-indebted debt villages that were found, and then puts greed into both villages to see what breaks.

## 2. The two kinds of money, in the simplest terms

**Debt-based money (the system in use today).** Two banks lend to farms, bakeries, theatres, households and the government. A loan creates a deposit; repayment destroys it; interest is the bank's income. Whatever money the village has, someone owes. The government taxes wages at a flat 15 % and capital income at 15 %, pays public wages for a tenth of the village's labour and a benefit of two loaves to the unemployed, and borrows the difference at a policy rate — from round 5 by issuing bonds that households and banks buy. There is no ceiling on what it may borrow.

**SuMSy (the alternative).** A money authority credits every living person with a guaranteed income of 5 each round. Balances above a buffer of 30 lose 2 % a round (demurrage: the money is destroyed), and a further 1 % on the same base goes to the government as its only revenue; there is no tax on income. The money stock therefore depends on the guaranteed income and the demurrage and on nothing else — not on prices, not on lending, not on the government. Banks still exist but only pass existing money between savers and borrowers, at a negative rate. Land is sold on instalment.

Both villages start from the same prices and the same behaviour rules. The differences that follow are differences of money.

## 3. The village: who is in it and what they own

| who | how many | owns | does |
|---|---|---|---|
| persons | 64 | up to four units of labour a round; 16 of them own the land (1.5 units a head) | work, buy bread and tickets, save, lend, hold shares |
| farms | 2 (4 on the co-op rung) | grain | rent land, hire labour, sell grain to the bakeries |
| bakeries | 2 (4) | bread | buy grain, hire labour, sell bread: two loaves a grain |
| theatres | 2 from rung 7 | tickets | hire labour, one worker serves two and a half customers; from this version a theatre may be capped at a number of shows with a seat for everyone |
| banks | 2 | loans, deposits | lend (debt village) or intermediate (SuMSy) |
| government | 1 | a reserve (from rung 11) | public jobs, benefit, taxes, bonds |
| money authority | 1 (SuMSy) | — | pays the guaranteed income, collects the demurrage |

From rung 8 the farms, bakeries and theatres are owned by four founders each and their shares trade; on the co-op side rung four farms and four bakeries and one theatre are cooperatives instead — member co-ops in the version of the previous report, worker and consumer co-ops in this one.

## 4. A round, step by step

1. Banks set their rates. 2. Land is rented or sold. 3. Farms and theatres hire, worker co-ops serving their members first. 4. Grain is harvested. 5. Bakeries buy grain and hire. 6. Bread is baked; the government hires whoever is left, up to a tenth of all labour. 7. Everyone without a meal buys bread from the cheapest bakery, paying the consumption tax where there is one; tickets are bought with what is left above the savings buffer. 8. All promises of the round are settled at once, netted (the *clearing*). 9. Debts are serviced; taxes are paid; dividends or patronage are distributed. 10. Under SuMSy the demurrage falls; the wealth tax, where there is one, is collected; the government sets its reserve aside and adjusts its taxes. 11. Everyone eats; the hungry lose capacity; the starving die. 12. Stock ages and spoils; prices and production targets adapt.

## 5. How the actors think: the behaviour rules

The rules are the same in both villages. The ones that changed since the previous report are marked ▲.

**5.1 How much to produce.** A farm or bakery plans to meet last round's demand plus a planning margin of 10 % (from rung 1); a theatre plans on expected ticket demand. Targets rise by one when demand went unmet and fall by one when stock was left.

**5.2 How prices are set.** Every seller posts an ask and every buyer a bid; they concede toward each other in six steps and close inside the zone of agreement. A buyer's ceiling for bread is 1.3 × the recent price, rising with hunger; a seller's floor is unit cost, falling as bread ages. ▲ The ask rises 6 % only when at least 5 % of the market's demand went unserved, and falls 6 % only when at least 5 % of what was offered stayed unsold; the previous report raised the ask on a single missed loaf and cut it on two unsold — Section 6 shows what that did. ▲ From rung 10 the posted ask never falls below unit cost (plus 5 % while the seller's reserve is short).

**5.3 How much to work.** Everyone offers their full capacity; the reservation wage is a meal net of tax, lowered by hunger. Employers hire one unit at a time in turns, so no one empties the market. ▲ A worker cooperative allocates its need to its members first, spread over them in proportion to what they have left, and members reserve capacity for a bakery co-op that hires later in the round.

**5.4 Saving, borrowing and land.** Everyone keeps three meals in reserve and borrows, or spends the reserve, at a coin flip. Land sells at a multiple of its rent, on instalment under SuMSy.

**5.5 Banks.** Debt village: cost recovery, capped at 5 % a round; SuMSy: −1 %.

**5.6 Government.** ▲ From rung 11 the government keeps a reserve of three rounds of expected spending and disposes of any surplus above it by lowering taxes (or, as an option, by an equal payment to everyone). ▲ From rung 12 it runs a fiscal policy: on a shortfall it raises taxes to cover half of it, on a surplus it lowers them, never moving revenue by more than 2 % in a round, and a lever per tax family decides which taxes carry the change — the debt village's endpoint relieves wages entirely (lever −3 on income) and lets the consumption tax carry the raise. The income family is the wage and capital tax under debt money and the demurrage surcharge under SuMSy, which never taxes income. ▲ A consumption tax of 6 % on bread and tickets, paid by the buyer, from rung 12. ▲ A wealth tax on land and shares at book value is available as an option and is examined in Section 10; it is not on the ladder.

**5.7 Eating and dying.** Two loaves a meal, one loaf a half meal that costs a third of next round's capacity, nothing three rounds running is death. Half rations never kill.

**5.8 Ownership.** ▲ Shareholder firms pay dividends above a working reserve and their shares trade on a market with a forward valuation. Cooperatives come in three forms: *member* (the previous report's rule: open membership at par, one equal dividend per member), *worker* (membership follows employment, the surplus goes by hours worked and is taxed as wages, a quarter is locked in an indivisible reserve), and *consumer* (membership follows purchases, the surplus comes back as a rebate on what each member bought). Under SuMSy a member may bring a pledge of demurrage-free buffer instead of money.

## 6. Why the behaviour rules come first

**The one-miss ratchet.** In the previous report the bare-bones SuMSy village (rung 0) lost 8 % of its people and this was read as a property of SuMSy without a planning margin. At ten seeds under separate random streams the loss is 17 % (from 6 % to 38 % across seeds). With the ask reacting to a 5 % shortfall instead of to one missed loaf, *nobody dies*: bread stays at 5.1 instead of climbing to 20.7, hunger halves, and the wealth Gini falls from 0.88 to 0.16. The debt village is unchanged at three quarters dead in all three cases, because its rung-0 problem is that income arrives only through work. The old loss was an artefact of a trigger no market has; it is gone from the ladder.

**Random draws.** Every draw in the model now comes from one of eleven random streams, one per subsystem, seeded from the run seed and the subsystem's name. With the single shared stream of the previous version, switching on a feature that draws — random tie-breaking in hiring, greed assigned at random — shifted every later draw in every other part of the model, so the same seed was a different experiment in two configurations. Ten seeds and separate streams are the minimum the comparisons below are made at; where a result is bimodal (some seeds whole, some dead) the text gives the count of surviving runs rather than a mean.

**The money stock under SuMSy.** It is fixed by the guaranteed income and the demurrage alone. A village started with everyone at the buffer sees its stock rise from about 2,000 to about 15,000 over sixty rounds — convergence to the level the two rates imply, not inflation — and prices rise with it, to about 1.35 × the starting vector. Section 10B starts a village at that level directly.

**How much the starting prices matter.** Both villages start from one price vector (bread 5, grain 5.2, wage 3.92, rent 0.75, ticket 2), chosen so that every link in the chain can pay its worker one meal a round. The scripts refuse to run a comparison in which the two villages start from different prices.

## 7. The ladder

Each rung adds one institution to both villages. Numbers are means of ten runs at round 100 (worst run in brackets where it differs by more than a few people): alive of 64 · unemployed · tickets a round · bread price · public debt (as % of yearly GDP) · deficit a round · cash Gini. The SuMSy village's "deficit" is negative wherever the demurrage surcharge over-collects.

### Rung 0 — bare bones
No government, no benefit, no interest on deposits, no theatre, no planning margin.
**Debt money:** 15 (11) alive · 6.8 · — · 5.66 · no public debt · Gini 0.34. Three quarters of the village starves within the hundred rounds: without a benefit, income comes only from work, and there is not enough work at the prices the bakeries can pay.
**SuMSy:** 53 (40) alive · 26.9 · — · 20.7 · Gini 0.36 — and with the price rule of Section 5.2, 64 alive, bread 5.1, Gini 0.16. The guaranteed income keeps almost everyone fed even here; what kills the rest is the one-miss price ratchet, an artefact, not the money.

### Rung 1 — + planning margin
Producers plan for 10 % more than last round's demand.
**Debt money:** 16 alive · 7.0 · — · 4.94. The margin does nothing for a village whose problem is income, not supply.
**SuMSy:** 64 alive · 29.7 · — · 3.39 · Gini 0.09. Nobody dies from here to the end of the ladder. Unemployment is high because there is nothing to do but bake bread.

### Rung 2 — + government
Public jobs for a tenth of the labour; a benefit of two loaves; the debt village taxes wages and capital at 15 %, SuMSy adds a 1 % surcharge on the demurrage base.
**Debt money:** 64 alive · 22.8 · — · 4.37 · debt 21,354 (305 % of GDP) · deficit 170 · Gini 0.47. The benefit keeps everyone alive and the government pays for it by borrowing about three quarters of what it spends. This is the round on which everything later rests: the debt village lives *because* its government runs a deficit.
**SuMSy:** 64 alive · 22.8 · — · 3.19 · no debt · surplus 72 · Gini 0.09. The surcharge over-collects from the first round; the surplus accumulates on the government's balance and pays demurrage there (Section 11 deals with it).

### Rung 3 — + interest on deposits
1 % a year plus a 2 % loyalty bonus; SuMSy unchanged (deposits earn nothing).
**Debt money:** 64 alive · 22.9 · — · 4.28 · debt 21,309 (311 %) · deficit 168. No visible effect at this scale.
**SuMSy:** as rung 2.

### Rung 4 — + theatre
A place to spend money on something other than bread.
**Debt money:** 64 alive · 15.9 · 68.5 tickets · 3.81 · debt 12,269 (173 %) · deficit 87 · Gini 0.61. The theatre halves the deficit: it employs the unemployed and their wages are taxed. It also doubles the cash Gini.
**SuMSy:** 64 alive · 9.8 · 126.1 tickets · 3.21 · surplus 73 · Gini 0.09. Twice the tickets, half the unemployment, and no change in inequality — the guaranteed income is spent on tickets by everyone, not on shares by a few.

### Rung 5 — + government bonds
The debt government borrows from households and banks instead of only from banks.
**Debt money:** 63 (58) alive · 17.9 · 47.6 · 3.39 · debt 12,302 (208 %) · deficit 95 · Gini 0.33. Bonds change who lends, not how much; they draw household cash away from tickets (69 → 48) and the first deaths appear in the worst seed.
**SuMSy:** as rung 4 — nothing to fund.

### Rung 6 — + charge on balances
2 % a round on enterprise cash above the working reserve, the debt village's mirror of the demurrage.
**Debt money:** 63 (62) alive · 17.6 · 50.0 · 3.12 · debt 11,627 (211 %) · deficit 79 · Gini 0.34. The charge trims the debt by a few percent and the deficit by a sixth. (The previous report's rung used 10 % a round on all cash; at ten seeds that closed every bakery by round 51, which is why the rung was redefined.)
**SuMSy:** 64 alive · 9.9 · 125.9 · 3.17 · surplus 89 · Gini 0.09. The charge is a second demurrage; the village hardly notices.

### Rung 7 — + second theatre
**Debt money:** 64 (62) alive · 17.7 · 48.7 · 3.41 · debt 12,490 (201 %) · deficit 94 · Gini 0.28.
**SuMSy:** 64 alive · 9.9 · 125.8 · 3.82 · surplus 67 · Gini 0.11. Competition between theatres lowers the ticket price in both villages; the debt village's tickets do not rise because the money to buy them is not there.

### Rung 8 — + shareholders and a share market
Every firm has four founders holding 640 shares; shares trade at a forward valuation; the founders keep 51 %.
**Debt money:** 64 (61) alive · 19.2 · 34.9 · 3.35 · debt 13,637 (237 %) · deficit 96 · Gini 0.34. Tickets fall by a third: household cash goes into shares.
**SuMSy:** 64 alive · 17.6 · 50.0 · 6.69 · surplus 93 · Gini 0.45. The largest single change on the SuMSy side of the ladder: tickets from 126 to 50, unemployment from 10 to 18, the cash Gini from 0.11 to 0.45. Shares crowd out the theatre. Section 8 shows this depends on the clearing step and on the dividends it makes possible.

### Rung 9 — co-ops (side rung)
Four farms, four bakeries and one theatre are member cooperatives; the rest stay shareholder firms; the share market runs.
**Debt money:** 64 (60) alive · 17.6 · 50.5 · 3.43 · debt 12,318 (196 %) · deficit 86 · Gini 0.29.
**SuMSy:** 64 alive · 10.4 · 121.0 · 4.85 · surplus 92 · Gini 0.27. The cooperatives, and the cooperative theatre in particular, undo most of the crowding-out: tickets 50 → 121, unemployment 18 → 10, Gini 0.45 → 0.27. Section 9 takes the forms apart; the member form is partly a second guaranteed income by equal dividend, and the worker and consumer forms recover less.

### Rung 10 — + responsive prices
The 5 % thresholds on unmet and unsold demand and the cost floor (Section 5.2), on rung 8.
**Debt money:** 64 (63) alive · 19.5 · 31.8 · 2.96 · debt 16,091 (320 %) · deficit 95 · Gini 0.33. Bread gets cheaper and the government's debt larger: firms that no longer sell below cost pay less tax and hire fewer.
**SuMSy:** 64 alive · 17.8 · 50.2 · 5.69 · surplus 100 · Gini 0.60. The same rules raise the SuMSy cash Gini from 0.45 to 0.60. Responsive prices are what let the greedy village survive in Section 10; they are not free.

### Rung 11 — + a public reserve
Three rounds of expected spending; any surplus above it lowers taxes.
**Debt money:** as rung 10 — the debt government never has a surplus to dispose of. **This is the best-surviving debt village on the ladder: 64 (63) alive, at a deficit of 95 a round and a debt of 320 % of GDP.**
**SuMSy:** 64 (63) alive · 17.0 · 59.3 · 6.06 · reserve 344 · Gini 0.65. The surcharge falls to 8 % of its statutory rate on its own — it had been over-collecting seven to one — and the money that used to sit on the public balance is spent: tickets 50 → 59.

### Rung 12 — + fiscal policy and a consumption tax
A 6 % VAT on bread and tickets; on a shortfall the government raises taxes to cover half of it, 2 % a round at most, with the wage tax relieved (lever −3) and the VAT carrying the raise up to a ceiling of twice its rate.
**Debt money:** 53 (46) alive · 18.3 · 15.7 · 2.13 · debt 13,488 · deficit 66 · Gini 0.48. The wage tax goes to nothing, the VAT to 12 %, the debt falls by a sixth and the deficit by a third — and eleven people die who were alive at rung 11, because a tax on bread reaches whoever could just afford bread. **This is the least-indebted debt village that still survives**, and it is not the best-surviving one. No configuration found this month gives both; Section 12 says why.
**SuMSy:** 64 alive · 18.1 · 48.2 · 6.28 · surplus 16 · Gini 0.65. The policy cuts the surcharge to zero and the VAT to a quarter of its rate, since the village runs a surplus; nothing else changes. A SuMSy village has no use for this rung.

**What the ladder says.** The debt village needs a government that borrows — from rung 2 on it lives on a deficit of a third to three quarters of its spending, and every attempt to close that deficit with a tax it can bear closes at most half of it (Section 12). The SuMSy village needs nothing: a guaranteed income of five and a demurrage of 2 % keep everyone fed from rung 1 with no public debt at all, and its problem is the opposite one, a surcharge that collects seven times what the public sector spends. The two villages diverge most at rung 8, when shares arrive: the debt village's inequality was already high, the SuMSy village's rises to meet it, and cooperatives undo most of that.

### The clearing step: needed throughout on one side, at the founding on the other
Every payment in a round is a promise, and all promises are netted and settled together. Without this step the debt village's bakeries close in the first rounds: a bakery must pay for grain before it has sold the bread. The SuMSy village survives without clearing, but differently: with cash in advance, firms are refused credit twice as often, hold less cash, pay no dividends for the first ten rounds, and the share market barely trades — the village then sells three times the tickets and its cash Gini is 0.18 instead of 0.44. A settlement rule is doing distributional work, and the rung-8 result depends on it.

### Inherited money in the debt village
A village whose starting cash is booked against the banks with no loan behind it behaves like the ordinary debt village at every rung; the inheritance changes who owes the banks, not what the village does.

## 8. What a stock market does

Rung 8 puts four founders behind every firm and lets their shares trade. Five variants were run on the SuMSy village to see which part of the market does the crowding-out: cash-only trades with no spread of required yields; a spread of yields; a resale-expectation term in the valuation; deferred payment with the shares as collateral; and the full market. The answer is the same as in the previous report, at ten seeds: whichever variant, once households can hold shares, ticket sales halve and the cash Gini doubles. What is new:

- The effect needs the clearing step. Without it the firms cannot build the reserves from which dividends are paid, valuations stay low, and the market barely trades (Section 7).
- Responsive prices (rung 10) add to it: the SuMSy cash Gini goes from 0.45 to 0.60 with the share market already in place, and from 0.44 to 0.71 in a no-greed village with the buyer ceiling raised as well. The rules that keep the greedy village alive in Section 10 concentrate cash in the ordinary one.
- A wealth tax on shares at book value (Section 10) equalises — the wealth Gini falls from 0.70 to 0.43 at 25 % a year — by consuming its own base, not by yielding revenue: the base shrinks from 3,800 to 1,300 and revenue tops out at 27 a round whatever the rate.

## 9. Cooperatives against profit-making firms

The previous report's cooperative was a member co-op: anyone with surplus joins any co-op at par, and every member gets the same dividend. With open membership and sixty-odd members per co-op within fifteen rounds, that is a second guaranteed income funded by the producers' surplus, and most of the halving of the crowding-out at rung 9 came from it. This version adds two forms with the distribution rules real cooperatives use.

**Worker co-ops.** Membership follows employment: whoever is hired becomes a member and pays the share out of wages. Members are served first and the work is spread over them in proportion to what they have left, so employment of members is stable and adjustment goes through hours (the pattern found in Italian and Uruguayan cooperatives). The surplus is distributed by hours worked over the last twelve rounds and taxed as wages; a quarter of every distribution is locked in an indivisible reserve that goes to the public purse if the co-op closes.

**Consumer co-ops.** Membership follows purchases; the surplus comes back as a rebate on what each member bought; members net the expected rebate off the posted price when choosing where to buy, so they are loyal. Farms cannot take this form (their customers are bakeries).

**Results, SuMSy, rung-8 village, ten seeds.** With the member form and a cooperative theatre: tickets 119, cash Gini 0.32 — the largest recovery on the ladder. With worker food-chain co-ops and a consumer theatre: tickets 88, Gini 0.38, about where the member form stood without a co-op theatre. The quasi-guaranteed-income reading of the member form is therefore partly right: patronage takes off the last step of the recovery but leaves most of it. A worker-owned theatre is the worst form on inequality (Gini 0.59) — the surplus of a labour-only firm goes to a dozen people — and a consumer-owned one spreads it across sixty. Whether members are served first makes little difference at this size. A co-op member under SuMSy may pledge part of the demurrage-free buffer instead of paying money; buffer-only membership draws the most members (101 against 84), the exemption is conserved, and the distributional effect is below ten-seed resolution.

One asymmetry to keep in mind: a shareholder firm short of capital makes its founders borrow personally, with no affordability test; a cooperative must borrow itself, and is tested. The switch `cooperative_founding = :symmetric` gives co-ops the same capital call on their members; the results above are without it.

## 10. Greed

Greed is programmed, not observed: a greedy person spends every surplus above the buffer, on capital (land, shares, cash) with probability *hoarding* and otherwise on loaves or tickets, up to ten loaves a round. The previous report ran it on the rung-8 village with the report's damped prices and concluded that universal mixed greed (hoarding 0.5) kills the SuMSy village while debt money starves greed of means. Both halves hold at ten seeds — the SuMSy village dies in nine runs of ten, the debt village keeps 59–61 alive at every setting — and the mechanism the previous report gave for the SuMSy death was wrong.

**What kills the greedy SuMSy village.** Not the price of bread outrunning the fixed income; hunger appears while bread is still affordable. In the run traced, at round 20 every unit of labour in the village is sold and 107 of 256 go to the theatres, funded by the greedy shareholders' dividends. The bakeries and farms cannot hire, bread output halves while its price *falls*, hunger cuts capacity, and the spiral runs. A theatre earns about 20 per unit of labour, a bakery under 7, and the bakery cannot bid the labour back because a buyer will pay at most 1.3 × the recent price for bread: scarcity never reaches the price, so it never reaches the wage. Adding capacity (5 or 6 units a head) or land does nothing but delay the collapse, because the theatre absorbs whatever is added in the same proportion. Capping the theatres (one show a round with a seat for everyone) removes the labour drain and exposes a second death underneath: the bakeries, planning for greedy demand that does not all materialise, cut the ask 6 % a round on unsold stock until bread sells below the cost of grain, the grain market freezes, and output goes from 192 loaves to none in one round. Two ways to die, one structure: nobody responds to the price.

**Responsive prices.** With the thresholds, the cost floor and a buyer ceiling of 2 × the recent price, the mixed-greed village survives in all ten runs at any theatre capacity, with output flat from round 60 to 100 and no hunger; the greedy quarter survives with a two-show cap and the thresholds alone. From the equilibrium start (Section 10B) the greedy quarter also survives in all ten runs, with no hunger in any round, and universal greed dies of the inflation the previous report described — every villager holds 167 of spendable surplus from round 1, demand goes unmet every round, and the 6 % rise compounds to a bread price of 85 against an income of 5. So: at the steady-state money stock, responsive prices save the plausible greedy village; only universal, insatiable greed defeats them, and that is the model's strongest assumption, not the money system's.

**Four measures against consumer greed** (universal mixed greed, damped prices). Rationing two loaves a head first: 64 alive. A wage ceiling of four loaves: 0 of 10 at ten seeds (the previous report's "saves a third" was one seed of three). Two prices for bread: nobody. Land for four loaves and a capacity of five: the previous report's success was the capacity, and capacity alone does not survive at ten seeds. Rationing works because it removes the greedy's loaf demand, the driver of the deflation death; nothing on this list touches the labour drain.

**Fiscal instruments and greed** (SuMSy, rung-8 village, ten seeds). Where the public surplus goes decides survival of the responsive greedy village: returned as a tax cut, 10 of 10; paid out per head, 4 of 10 — the payout hands the surplus straight back to the greedy. A consumption tax is scaled away by the tax-cut rule; kept, it is no brake on greed at any rate and is lethal above about 10 % — the tax eats the headroom the bread price needs. A wealth tax on land and shares is the one instrument that helps the greedy-quarter village: survival rises from 2–3 to 5 of 10 at 10 % a year and 7 at 25 %, tickets rise (44 → 76) because the rest of the village can afford them, and it works only because the proceeds are sterilised on the public balance; paid out, they would return to the greedy. At 25 % the same tax costs the no-greed village a person and a third of its tickets.

**An income indexed to bread — the honest critique.** Indexing the guaranteed income to the bread price is harmless without greed and produces a spiral with it (bread 14–28, money stock 22–33 thousand and rising). Unchanged from the previous report; the equilibrium-start version of this test has not been run and is the direct test of "the fixed income is what makes inflation lethal".

## 10B. SuMSy at its equilibrium

The money stock of a SuMSy village is fixed by the guaranteed income and the demurrage: every person's balance converges to buffer + income ÷ (demurrage + surcharge) = 197, the village's to about 14,700. A village started with everyone at the buffer takes sixty rounds to get there, and its prices rise 1.3–1.5 × on the way. The previous report's "saturated" runs started at a price level of 0.63 × the initial vector, a sixteen-person figure; at sixty-four persons the level is 1.35 ×, so those runs started with prices half what their money stock implied, and their result — dead within five rounds under greed — is withdrawn. This version starts the village at its equilibrium directly (`start_at_saturation = :equilibrium`, prices at 1.35 ×). Without greed it is the ordinary village. With greed, the matrix of Section 10: the greedy quarter lives, everyone greedy dies, whatever the price rules.

## 11. The parameters and what they do

Every parameter, its default, its range and the rung or section that uses it is in `docs/dashboard_spec.md`, generated from the source; the tables are not repeated here.

## 12. What this does and does not show

1. **The debt village's deficit is structural.** From rung 2 it borrows a third to three quarters of what it spends, and no survivable tax closes more than about half of that. The wage tax is bearable to 30 % and inflates the indexed outlays it is meant to fund; the Belgian progressive schedule alone kills the village by round 20; a consumption tax closes the most per unit of harm, because it does not gross up public wages, and a 6 % tax on bread costs two lives a run; a wealth tax's base is consumed by its own levy; and four ways of combining them (weights, sliders, a share target, levers) find the same frontier — relieve wages to keep people alive, accept a deficit of 65–95 a round, or balance the budget over a village of fourteen. The ladder's last two rungs are the two ends of that frontier.
2. **The SuMSy village has the opposite fiscal problem.** Its surcharge over-collects seven to one and the surplus sits on the public balance until a reserve rule returns it. Where it is returned matters more than how much: as a tax cut it leaves the greedy village alive; per head it does not.
3. **The greed critique is a critique of damped prices and of an assumption.** With prices that respond in both directions, greed in a quarter of the village is survivable at the steady-state money stock; universal insatiable greed is not, under any rule, and it is the strongest assumption in the model.
4. **Cooperatives do most of what the previous report said**, by two routes: the member form's equal dividend, which is a transfer, and the removal of tradable shares, which is structure.
5. **What this model cannot say.** Demand is a fixed quantity and willingness to pay is anchored to the recent price, so every statement about prices is a statement about a rationing rule; a settlement rule (clearing) does distributional work; the government has no budget constraint on the debt side; ten seeds separate outcomes that differ by more than a few people and no others; and greed, hunger and work are rules, not people.

## 13. Stress tests: greed on the best cases

Greed is put into the two debt villages the ladder ends on — rung 11, the best-surviving, and rung 12, the least-indebted — and into their SuMSy mirrors, in two doses: the richest quarter greedy (hoarding 0.5, the plausible case) and everyone greedy (the extreme). Ten seeds; alive of 64 (worst run) · runs in which the village stayed whole · tickets · cash Gini.

| | debt, rung 11 (best surviving) | debt, rung 12 (least indebted) | SuMSy, rung 11 | SuMSy, rung 12 |
|---|---|---|---|---|
| no greed | 64 (63) · 10 · 32 · 0.33 | 53 (46) · 3 · 16 · 0.48 | 64 (63) · 10 · 59 · 0.65 | 64 · 10 · 48 · 0.65 |
| richest quarter greedy | **64 (63) · 10 · 0 · 0.27** | 55 (21) · 4 · 0 · 0.40 | **64 · 10 · 113 · 0.28** | 60 (25) · 9 · 111 · 0.33 |
| everyone greedy | **64 · 10 · 0 · 0.36** | 57 (45) · 3 · 0 · 0.45 | 58 (0) · 9 · 37 · 0.32 | 58 (0) · 9 · 36 · 0.30 |

Three readings.

**The best-surviving debt village survives greed, and pays with its theatres.** Rung 11 keeps everyone alive under both doses. Its theatres close in every greedy run (tickets 0): the greedy buy the shares, and the dividends that would have bought tickets go into more shares. The village is fed and has nothing to do in the evening.

**The best-surviving SuMSy village survives the plausible greed and improves on it.** With the richest quarter greedy, tickets double to 113 and unemployment falls below one, because responsive prices let the food chain hold its labour and the guaranteed income lets everyone else keep buying. With everyone greedy it loses one run in ten outright — the village that dies goes the way of Section 10B, a late price spiral against a fixed income — and keeps the other nine whole. On the previous report's village universal greed killed nine runs in ten; what changed is the price rules and the disposal of the public surplus, not the money.

**The least-indebted villages are the least robust.** Rung 12 loses a run in ten to the greedy quarter in both systems (worst seeds 21 and 25 alive) and, in the debt village, seven more people to universal greed than rung 11 does. A budget squeezed toward balance — no wage tax, a 12 % consumption tax — has no slack when the greedy pull labour and cash out of the food chain. The ladder's two endpoints are therefore a trade-off twice over: the least-indebted village is also the one greed breaks first.
