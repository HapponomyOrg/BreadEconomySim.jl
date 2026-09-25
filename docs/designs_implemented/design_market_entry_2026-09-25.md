# Design: market entry
*25 September 2026 — design only, not implemented. Agreed in principle with Stef: entry as a switch, the ladder without it, entry twins of the key steps, and entry as one of the transition's variants.*

## 0. Why
The number of farms, bakeries and theatres is fixed at the founding; firms leave (liquidation) but only return when a whole kind has gone (`refound_minimum`). Real markets gain firms where demand goes unserved or profits run high. With entry the number of firms becomes a result — whether new competitors push prices and profits down, who founds them, and whether entry spreads ownership (cooperatives) or concentrates it (the villagers with spare cash).

## 1. The rule (`market_entry = true`; off by default and on the ladder)
- **Signal**, per kind (farms, bakeries, theatres), checked monthly:
  - *unmet demand*: the market's unserved share has been at least `entry_unmet_share` (5 %) in each of the last `entry_unmet_months` (3) months, or
  - *high margins*: the firms of that kind have averaged an operating margin (operating result over turnover) above `entry_margin` (20 %) over the last `entry_margin_months` (6) months.
- **Pace**: at most one new firm per kind per `entry_cooldown` months (3), so prices can react before the next one.
- **Founders**: the `shareholder_count` villagers with the most spare cash (ties by id), paying in the working reserve under the founding rules (`pay_in_equity!`: savings above the cushion, then a founding loan on business terms, or a peer loan under SuMSy; never below the protected minimum). If they raise nothing, no firm is founded and the signal is checked again next month.
- **Form**: a cooperative with probability `entry_coop_share` (0 in the entry twins, so they measure entry alone), founded by its founding members; a shareholder firm otherwise.
- **The new firm**: a new agent of that kind (a closed firm's shell is reused when one exists), the starting production target, no stock, debts or history; theatres get their seat cap recomputed.
- **Limit**: `entry_max_per_kind` (default: twice the starting number) keeps a runaway signal from flooding the village.

## 2. Where it runs
- **The ladder: off** — it stays the controlled comparison, one institution per step.
- **Entry twins** (both villages, ten runs): the best debt village (step 8 or 10, to be chosen from the 25 September results), step 10 (reserve), the co-op village B, and LD10 (levy and land dividend) — each with entry on and `entry_coop_share = 0`.
- **The transition** (see design_transition): one variant with entry on and `entry_coop_share = 0.5`.

## 3. Measures
Firms by kind and form per month; entries and exits (cumulative); the Herfindahl index of bread and grain sales (concentration); owners (distinct shareholders and co-op members); bread and grain price; margins.

## 4. Tests to write first
Entry fires after three months of 5 % unmet demand and not after two; at most one per kind per cooldown; founders are the villagers with most spare cash and pay in the reserve; a failed attempt founds nothing; `entry_coop_share = 1` founds a cooperative with founding members; `entry_max_per_kind` holds; the money identity holds in both villages with entry on.

## 5. Open
- The margin threshold (20 %) is a guess; the unmet-demand trigger is the one the model already uses for prices.
- Whether a failed firm's shell is reused or a new agent is created: reuse is simpler and keeps agent ids dense; new agents are cleaner for the data. Proposed: reuse, as `refound_missing_producers!` does.
