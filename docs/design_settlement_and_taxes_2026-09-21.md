# Design: settlement systems, liquidation, and the tax families
*21 September 2026 — agreed in discussion, not yet implemented. Every rule here is a choice; the ones that were argued over say why.*

## 0. What changes and why
Today every payment in a round is a promise, and all promises of all agents are netted and settled together at the end of the round (`clear!`), with the credit decision taken once on each agent's net position. That is a clearing house with the whole village in it. Real clearing exists between banks; between firms, much less; and a consumer pays at the counter. So settlement is split into four ways of paying, each with a stated membership, and a firm that cannot pay its invoices is liquidated by a stated rule. At the same time the taxes are put on one footing — five families, each with its own scale and lever, each with a collection period — so any tax can be tried in either village, with the parking fee kept outside as money rather than tax.

The ladder now running at 128 (`ladder2_128_rounds.csv`) is the **before** of the settlement change and is kept as such.

## 1. Four ways of paying
| way | who | when the money moves | if the payer is short |
|---|---|---|---|
| **cash** | any payment in which a person is a party (bread, tickets, land, shares, membership, benefit, guaranteed income, wealth tax, dividends), and any payment involving a firm that belongs to neither system below | at once, at the counter | the purchase does not happen (`fund!` as fixed on 21 September: cash or eligible credit) |
| **wages** | employer → worker | an obligation within the round, settled at the end of the round from the employer's cash; credit for the shortfall (bank loan or peer loan, affordability-tested) | unpaid wages become arrears the worker can garnish, as now |
| **invoice** | firm → firm where both belong to the invoicing or the clearing system (farm ↔ bakery grain; bakery → bank fees; any firm → bank interest and repayment stays a loan, not an invoice) | recorded this round, **payable at the end of the next round** from cash; unpaid → arrears with an age | nothing is refused at the sale: the invoice is trade credit without interest or affordability test. Arrears accumulate; §2 decides when they end the firm |
| **clearing** | firms that belong to the clearing system, among themselves: **banks only by default** | netted and settled at the end of the round, as `clear!` does today, restricted to clearing members | the net deficit is financed as today |

Membership: `settlement_clearing::Vector{Symbol} = [:bank]`, `settlement_invoicing::Vector{Symbol} = [:farm, :bakery, :theatre]`. A kind in neither pays cash. The government pays cash (benefit, public wages as wages, coupons) and receives cash and invoices (taxes on firms are invoices; on persons, cash). Under SuMSy the same rules; the two banks clear between themselves, which is nearly nothing — that is the point of stating it.

Why wages are their own way: paying at hiring would be cash-in-advance, which closed every debt-village bakery before there was clearing; paying next round would let a firm run a month of labour on credit it never asked for. End of round, from takings, is what wages are.

### What this does to the existing code
`promise!` gets a `way` argument decided by a single function `settlement_way(payer, payee, purpose)` from the memberships. Cash promises settle immediately (the immediate path, with the 21 September `fund!`). Wage promises keep priority 2 and settle in the end-of-round step without netting against anyone else's. Invoice promises are stored on the payer as `Invoice(to, amount, round_issued)` and paid in the next round's end-of-round step, oldest first, from cash after wages. Clearing promises go through `clear!` as now but only among members. The end-of-round step becomes: wages → invoices due → clearing → taxes.

## 2. Liquidation
**Trigger** (checked once a round after invoices are paid): the invoices a firm owes that are **three or more rounds overdue** sum to at least `liquidation_arrears_share = 0.10` of its book value (cash + land at the land price − bank debt − peer debt). Book value ≤ 0 with any overdue invoice also triggers.

**Stage 1 — sale as a going concern (refounding).** Asking price = `liquidation_price_share = 0.90` × book value, never below the debt left after the firm's reserves have been applied to it (`minimum price = max(0.9 × book, debt − reserves)`). Buyers: persons and firms with cash above their cushion or reserve, taken in order of spare cash, up to `shareholder_count` of them, who together put up the price and hold the new shares pro rata — the founding mechanism reused. The proceeds pay the overdue invoices first (oldest first), then bank and peer debt; what is left stays in the firm as the new owners' capital. The old shares are cancelled; the old owners get nothing. Cooperatives are refounded as shareholder firms unless `liquidated_coop_stays_coop = true` (members refound it with new shares at par; default false — recorded as a choice).

**Stage 2 — asset liquidation** (no group can reach the minimum price, or book ≤ debt): cash and land at the land price go to creditors pro rata in the order invoices → peer loans → bank loans; the firm ceases to exist (`close_enterprise!` does most of this today). What cannot be paid is **struck**.

**Struck debts**
- *Bank loan (debt money):* the loan is removed; the deposits it created stay in circulation. `money_written_off` is added to the identity (created − destroyed − written off = in circulation). The bank's capital takes the loss. When a bank's capital would go below zero, the **government recapitalises it** — pays in the shortfall, funded by borrowing (`bank_bailout`). Stated rule: banks do not fail; the state stands behind them. The alternative (the bank fails, depositors lose) is not modelled and is said so in the report.
- *Peer loan (SuMSy):* extend `default_insurance` from instalment sales to all peer loans: every lender pays `insurance_premium_rate` of each repayment received into the bank's pool; on a struck peer loan the bank pays the lenders from the pool; what the pool cannot cover the lenders lose, pro rata. No lender of last resort. The premium rate is the price of credit risk under SuMSy and is a sweep variable.
- *Invoice:* the supplier writes the receivable off (`bad_debt_received`), no cover, and may hit its own trigger — chains are allowed and counted (`liquidation_chain_length`).

Land of a firm that ceases: sold to persons/firms with spare cash at the land price during the asset liquidation; unsold land goes to the government (it has land now).

## 3. Taxes: five families, one footing
| family | base | payer | period | lever |
|---|---|---|---|---|
| income | wages (flat or progressive brackets), capital income, dividends | persons | `income_tax_period` ∈ {1, 12}: 1 = withheld monthly (as now); 12 = accrued through the year, charged in the 12th round; arrears garnished as wages are; (a third mode, monthly withholding with a yearly balance, is the Belgian one and a future option) | income |
| consumption | bread and tickets, paid at the counter | persons | per purchase, unchanged | consumption |
| wealth | land and shares at book | persons | monthly at rate ÷ 12, as now | wealth |
| **profit** (new) | a firm's revenue over the period minus material cost × `deductible_materials = 1.0` minus labour cost × `deductible_labour = 0.5`, never below 0; rate `profit_tax_rate = 0.10` a year | firms | `profit_tax_period` ∈ {1, 12}, same semantics; the firm's period result is accumulated; charged as an invoice to the government | profit |
| **parking tax** (SuMSy) | balances above the buffer, on top of the parking fee | everyone | monthly, as now | parking |

`tax_levers` becomes a five-tuple `(income, consumption, wealth, profit, parking)`; each family has its own scale; the policy's r moves all five and the levers shift them (|r| × lever, then r). The parking *fee* (`demurrage_rate`) is money, not tax: never scaled, never levered. The SuMSy guard in the scripts becomes: income, wealth and profit levers may be non-zero only in a variant named "(comparison)"; consumption and parking are SuMSy's own. `enterprise_tax = :income` (the old 10 % on the operating result, no deductions) is replaced by the profit family; `:reserves` (the charge on balances) stays as it is — it is a charge on idle money, not a tax on profit, and rung 6 keeps it.

Existing behaviour is the default everywhere: periods 1, profit tax 0, levers 0 — every golden value survives except where the settlement change moves them (§1 moves everything).

## 4. Parameters (new)
`settlement_clearing`, `settlement_invoicing`, `liquidation_arrears_share = 0.10`, `liquidation_overdue_rounds = 3`, `liquidation_price_share = 0.90`, `liquidated_coop_stays_coop = false`, `bank_bailout = true`, `peer_loan_insurance = false` (true extends the pool to peer loans), `income_tax_period = 1`, `profit_tax_rate = 0.0`, `profit_tax_period = 1`, `deductible_materials = 1.0`, `deductible_labour = 0.5`, `tax_levers = (0,0,0,0,0)`.

## 5. Data and events
Per round: `invoices_issued`, `invoices_overdue`, `liquidations`, `refoundings`, `firms_ceased`, `money_written_off` (cumulative), `bank_bailouts` (cumulative), `insurance_pool`, `insurance_shortfall`, `profit_tax`, `income_tax_due` (accrued), per-family scales. Events: `:invoice`, `:liquidation` (trigger values), `:refounding` (buyers, price), `:asset_liquidation`, `:written_off` (kind, amount), `:bailout`, `:insurance_payout`.

## 6. Tests to write before the code
Settlement: a bread sale is cash and fails without cash; wages settle at the end of the round from takings; a grain sale is an invoice paid at the end of the next round; two banks clear net; a firm in no system pays cash. Liquidation: the trigger fires at 10 %/3 rounds and not at 9 % or 2 rounds; refounding takes up to four buyers pro rata and pays the oldest invoice first; asset liquidation pays invoices before loans; a struck bank loan raises `money_written_off` by its amount and the identity still holds; a bank driven below zero capital is recapitalised and the government's debt rises by the shortfall; a struck peer loan is covered from the pool up to the pool and the rest is lost pro rata; a supplier's write-off can trigger its own liquidation. Taxes: the profit base with the two deductibles on a prepared firm; period 12 charges the year in round 12 and nothing before; the five levers on a prepared shortfall; the parking fee is untouched by any lever; SuMSy guard refuses income/wealth/profit levers outside a comparison.

## 7. Order of work and cost
1. Settlement ways + wages (touches `promise!`, `clear!`, the round order). 2. Invoices and their ageing. 3. Liquidation, refounding, write-offs, bailout, peer insurance. 4. Profit tax, income period, five families. 5. Golden values regenerated; full test run. 6. Full rerun at 128 (ladder, stress, 2×2, best SuMSy) and the blocks; then the 256 comparison. Two to three days of implementation and tests before the first new run; a day of compute after.

## 8. Decisions (closed 21 September)
- **Banks are recapitalised.** When a bank's capital would go below zero after a write-off, the government pays in the shortfall, funded by borrowing (`bank_bailout = true`). Stated in the report as the rule. *Bank failure — the bank ceases, depositors lose — is a possible future design option, not modelled.*
- **A refounded firm is a going concern**: it keeps its production target, its staff, its stock and its land; only the owners change.
- **A liquidated cooperative is refounded as a shareholder firm** (`liquidated_coop_stays_coop = false`). Refounding by the members is an option, off by default.
- **Tax periods default to 1** (monthly, as now); 12 is the yearly comparison. *Belgian mode — monthly withholding with a yearly balance — is a future option.*
