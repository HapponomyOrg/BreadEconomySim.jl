# Design: a transition from the debt village to SuMSy
*23 September 2026 — design only, nothing implemented. Inspired by "Realistisch haalbaar" (Goed geld, ch. 11). Decisions of 23 September incorporated; points marked **open** still need one.*

## 0. What is modelled
A debt village runs for a while, builds up debt, and then SuMSy is introduced **next to** the euro. For a period both currencies circulate in the same village; participation is voluntary in one path and set by the government in the other. The run continues at least ten years after the switch. The question is what the switch does to survival, debt, inequality and the two money stocks, and how much it matters how late it starts.

## 1. Two currencies in one village
- Every villager, firm, bank and the government holds a **euro balance** (debt money, as now) and a **SuMSy balance**.
- Each has a **participation level** p ∈ [0, 1]; before the switch every p is 0.
- **Reciprocity** (the book's principle, extended to employers and government): in every payment the share paid in SuMSy is **min(p_payer, p_payee)**, the rest in euros. It applies to purchases, wages, rent, invoices, benefits, public wages and taxes (for taxes the government's p is its *acceptance share*, §3).
- **Guaranteed income** = p × the full guaranteed income — in every scenario the guaranteed income scales with commitment; **parking-fee-free buffer** = p × the full buffer; the **parking fee** applies to the SuMSy balance above that buffer. The parking fee is money, not tax.
- **Prices** are one number per good, in units at par; a payment is split by the reciprocity share. (No separate euro and SuMSy prices.)
- Consequence to watch: an early adopter receives its guaranteed income at its own p but can spend SuMSy only at its partners' levels — **unspendable SuMSy that pays the parking fee** is the cost of adopting early.

## 2. Two paths
**A. Set by the government.** Everyone is in; every p follows a schedule from 0 to 1 over the conversion period, swept from **3 to 10 years**; the guaranteed income rises with p. At p = 1 the **full switch** takes place: classic credit loans (money-creating bank loans) are no longer allowed, all loans may be repaid in SuMSy, and remaining euros become SuMSy at par — **both variants are run**: an unlimited official counter at par (people convert when they choose) and an automatic conversion of all euro balances at the switch. The run continues at least **five years** after the full switch.
- Expect a jump: an automatic conversion adds the whole euro money stock to the SuMSy stock, which then sits above its equilibrium; the parking fee destroys the excess over time and prices should fall back. Worth measuring.

**B. Bottom-up.** Participation is chosen:
- **First entrants** are those under financial stress (cash below the cushion, hungry, or unemployed): the guaranteed income is the incentive.
- **Everyone else weighs it** every quarter: the gain of a step up (guaranteed income, taxes payable in SuMSy, old debt repayable in SuMSy, sales to and wages from higher-level partners) against the cost (the parking fee on SuMSy that would be unspendable at the partners' levels). Step up when the gain is larger, down when the cost is. The same rule for firms, with their own gains (sales, wages payable, taxes, old loans).
- **Availability** limits adoption: SuMSy is only worth having where the goods one needs can be bought with it, and wages can be paid with it — both are in the weighing.
- **The government joins when it can use the money.** Two variants are run:
  - *bakery rule*: its participation level is the **bakeries' average commitment** (one bakery at 50 %, two at 25 %, one at 0 % → 25 %); bread is what the benefit must buy, so the government can use SuMSy exactly as far as the bakeries take it;
  - *startup-cost rule*: it sets its level from what it can spend in SuMSy plus the part of the expected startup deficit it chooses to carry.

  In both it accepts taxes in SuMSy up to its level and pays the benefit and public wages under reciprocity, min(p_government, p_recipient).

## 3. Government during the transition
- **Taxes:** income is taxed on its euro part only; SuMSy income is untaxed; the parking tax applies to SuMSy balances. The income tax therefore shrinks by itself as participation grows and the fiscal system ends at the SuMSy village's.
- **Taxes payable in SuMSy** up to the government's participation level — the bakeries' average commitment in path B, the schedule in path A. The government knows a filling-up SuMSy economy has a startup cost (the startup public debt found on 23 September) and carries it: its SuMSy shortfall in the early years is financed by SuMSy peer loans, repaid as the parking tax grows. Being able to pay taxes in SuMSy is itself an incentive to adopt.
- **Old government debt:** bank loans taken before the switch may be repaid in SuMSy at par. **Bonds** follow reciprocity: coupons and principal are paid at min(p_government, p_holder).
- Public debt is reported **in both currencies**.

## 4. Loans and banks
- **Old loans** (issued before the switch) may be repaid in SuMSy **at par**, by law. **New loans** (issued after) must be repaid in euros. **A loan rolled over or refinanced after the switch is new.** A SuMSy repayment is accepted only after checking the loan's start date against the switch. After the full switch of path A every loan may be repaid in SuMSy.
- A bank that receives SuMSy **keeps it and pays the parking fee** on it. It can use that SuMSy, and buffers lent to it by depositors (the existing buffer-lending), as reserves.
- Banks become **intermediaries for SuMSy peer loans** as soon as there is demand, as in the SuMSy village.
- Banks pay their staff under reciprocity: in SuMSy to the extent their employees accept it.
- New bank *credit* is euro only (money creation stays with the euro).

## 5. The private exchange market
- By law SuMSy is at par for payments and old-loan repayment **only**: there is no official exchange counter before the full switch (a finding may be that one is needed); nothing stops private parties trading SuMSy against euros at any rate.
- The incentives are built in: holders of old loans want SuMSy (it pays euro debt at par); holders of unspendable SuMSy want euros; taxpayers want SuMSy up to the acceptance share. A simple order book lets a price emerge each month. **No restriction**: whether restrictions are needed is a finding (e.g. SuMSy funnelled into banks through cheap repayment of old loans).

## 6. Scenarios
- **Starting villages:** the best and the worst debt village among the steps with every element (government, theatres, share market — step 8 on), chosen by rule once the new 512 results are in: best = highest survival, lowest public debt as tie-breaker; worst = lowest survival (**open**: confirm the rule).
- **Target:** the SuMSy money and fiscal setup of the best SuMSy village; **open**: ownership unchanged (proposal — measures the money alone) or also half the firms turned into cooperatives.
- **Debt before the switch:** the switch month is the debt level (the debt village's public debt grows steadily): switch at months 12, 36, 60 and 120.
- **Path B** runs at least 120 months after the switch (up to 240 months).
- **Path A** also sweeps the conversion period (3 to 10 years) and runs five years past the full switch — up to 300 months. Instead of the full grid: the conversion sweep (3, 5, 7, 10 years) at switch month 60, the switch sweep (12, 36, 60, 120) at a five-year conversion, **plus the four corners** (switch 12 and 120 × conversion 3 and 10 years) — eleven cells, each with both end variants (counter, automatic conversion).
- **Path B** has the four switch months, each with both government variants (bakery rule, startup-cost rule).
- Ten seeds per cell, 512 villagers: path A 11 cells × 2 end variants × 2 villages × 10 = 440 runs; path B 4 × 2 × 2 × 10 = 160 runs.

## 7. What is measured
Survival **throughout** the transition (the lowest point, not only the end); participation over time (villagers, firms, banks, government); the two money stocks; the exchange rate; unspendable SuMSy and the parking fee paid by early adopters; public debt in both currencies, and private debt; the rich–poor gap (richest tenth against poorest tenth, in meals); bank SuMSy reserves; and a comparison of the end state with the pure debt village and the pure SuMSy village.

## 8. Order of work
1. Two balances and participation levels; reciprocity in every payment path (the settlement ways already route every payment through one function — the split goes there). 2. Guaranteed income, buffer and parking fee on the SuMSy balance at p. 3. Loans: start-date check, SuMSy repayment of old loans, bank SuMSy reserves, SuMSy peer loans. 4. Government: taxes by currency, acceptance share, SuMSy benefit threshold, bonds under reciprocity. 5. Path A schedule; path B entry and weighing rules. 6. Exchange market. 7. Scenario scripts and the sweep. 8. Greed stress tests on the transition villages — last, once the transition works.

## 9. Tests to write first
Reciprocity split on a sale, a wage, an invoice and a tax; guaranteed income and buffer at p = 0.3; an old loan repaid in SuMSy accepted, a new one refused; a bank paying the parking fee on SuMSy reserves; bonds at min(p_gov, p_holder); income tax on the euro part only; path A reaching p = 1 on schedule; a stressed villager entering first in path B; the government starting the SuMSy benefit only above the coverage threshold; the exchange market clearing at a price between the best bid and ask; both money identities (euro and SuMSy) holding every round.

## 10. Decisions
All points settled on 23 September: starting villages by rule (best = highest survival, lowest public debt as tie-breaker; worst = lowest survival; steps from 8 on); ownership unchanged; switch months 12/36/60/120; par only for payments and old-loan settlement (no official counter before the full switch — a finding may be that one is needed); guaranteed income always scaled by commitment; path A converts over 3–10 years and ends in a full switch with both end variants; a rolled-over loan is new; path B's government level by the bakery rule and by the startup-cost rule, both run; the one-dimensional sweeps plus the four corners. The starting villages are chosen once the 512 results under the 23 September model are in; nothing is built before then.
