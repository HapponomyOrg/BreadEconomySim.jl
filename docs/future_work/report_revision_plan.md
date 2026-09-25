# Report revision plan — 20 September 2026

## 1. Is the structure still right?

The arc the report should have: **bare bones → one component at a time → the best-surviving, least-indebted debt village, with SuMSy as the mirror at every rung.** As printed (15 September) the ladder runs from rung 0 to rung 9 and ends on an *ownership* variant (co-ops vs for-profit), not on the fiscal endpoint; everything found this week — price rules, the public reserve, the fiscal policy, the VAT, the wealth tax, the theatre cap, the cooperative forms — lives in Sections 8–10B as isolated experiments on the rung-8 village. So the structure is no longer correct in two ways:

1. The ladder does not reach the endpoint. It needs three more rungs, cumulative on rung 8: **10 responsive prices** (unmet 5 %, unsold 5 %, cost floor), **11 government reserve** (3 rounds, surplus returned as a tax cut), **12 fiscal policy + VAT** (levers −3:0:0, coverage 50 %, step 2 %, ceiling 2, VAT 6 %) — the configuration that keeps the most debt-villagers alive (60.9 of 64) with the least debt among survivable settings (12,056 against 14,505). Rung 9 (co-ops) becomes a side rung off rung 8, as it always was in substance.
2. Every number in the report came from the single random stream at three seeds. The second ladder (`scripts/ladder2.jl`, `results/ladder2_64_rounds.csv`) reruns rungs 0–12 at ten seeds under the per-subsystem streams. All rung cards are rewritten from it; nothing from the 15 September CSVs is quoted.

The mirror holds: every rung has a SuMSy twin with the same non-monetary components. At rungs 11–12 the mirror is informative in itself (the demurrage tax finds its balancing rate under the reserve rule; the VAT is scaled away by the same rule).

## 2. Section-by-section changes

**1–4 (what this is; two kinds of money; the village; a round).** Add to §4: the wealth-tax step and the reserve/policy step after demurrage; the theatre's seats; the consumption tax at the counter. Otherwise unchanged.

**5 (behaviour rules).** 5.2 prices: the ask rises only when at least 5 % of demand went unmet and falls only when at least 5 % of what was offered stayed unsold; the posted ask never goes below unit cost (plus 5 % while the reserve is short); state that the one-miss rule is what the 15 September report used and why it was wrong (rung 0). 5.6 government: the reserve of three rounds of spending, the surplus returned as a tax cut or per head, the policy (shift, then move), the VAT. New 5.8 ownership forms: member / worker / consumer co-ops, membership by money or buffer pledge.

**6 (why the rules come first).** Add the rung-0 result: the SuMSy loss the report called "8 %" was 17 % at ten seeds and *zero* once the ask reacts to a 5 % shortfall rather than one missed loaf — a trigger artefact, not a SuMSy property. "How much the starting prices matter" gets the money-stock note: under SuMSy the stock is GI and demurrage only; the 64-person steady state sits 1.35× the initial vector, and the saturation runs used a 16-person figure (0.63).

**7 (the ladder).** Rewrite every card from `ladder2`. Rungs 0–8: same components, new numbers (ten seeds, ranges not means for anything bimodal). Rung 9 → side rung, now with a co-op theatre and the three forms. New cards 10–12 with the components above; the closing text of §7 becomes: the debt village survives *because* it borrows; the taxes that would balance it kill it (progressive schedule: dead by round 20; wage tax > 30 %: dead); the survivable endpoint abolishes the wage tax, taxes consumption at 12 %, and still runs a deficit of ~65 a round. "The clearing step" subsection: keep, and add that clearing also finances the reserves that fund the dividends that drive the share market (clearing off = thin market, three times the tickets, Gini 0.18) — a settlement rule doing distributional work. "Inherited money": unchanged.

**8 (stock market).** Keep the five variants; add the clearing dependence above; note the responsive-price cost (no-greed cash Gini 0.44 → 0.71).

**9 (cooperatives).** Rewrite around the forms: member (the 13 September rule, a quasi-GI by equal dividend), worker (members first, hours-based patronage, membership out of wages), consumer (patronage rebate, member price awareness); the co-op theatre (rung 9a: SuMSy tickets 92 → 119, Gini 0.40 → 0.32); the 2×2 of form × contribution (money / buffer pledge, SuMSy only); the founding asymmetry (`cooperative_founding`).

**10 (greed).** The mechanism sentence is replaced. Not "the price of bread outruns the fixed income" (norm start) but: with damped prices, entertainment outbids food for labour (unlimited theatre) or bread deflates below cost and the grain market freezes (capped theatre) — both "nobody responds" failures of the price rules; with responsive prices the greedy village lives from the norm start at any theatre capacity (10 of 10). From the equilibrium start: the greedy quarter lives (10 of 10, no hunger); universal greed dies of the inflation the report described. Measures: rationing holds; the wage ceiling "saves a third" is one seed of three and 0 of 10 at threshold 5 % — drop; capacity and land do nothing; the theatre cap chooses between the two deaths. Fiscal: where the public surplus goes decides survival (tax cut 10 of 10, per capita 4 of 10); a VAT is no brake and is lethal above ~10 % through the ceiling; a wealth tax on the greedy quarter is the one instrument that helps (2–3 → 7 of 10 at 25 %), and only because the proceeds are sterilised.

**10B (saturation).** Rerun at multiplier 1.35 before quoting; the 0.63 runs are withdrawn. Add the equilibrium start (`:equilibrium`) as the fair steady-state test and the matrix above.

**11 (parameters).** Regenerate from `parameters.jl` (dashboard_spec tables are current).

**12 (what this does and does not show).** Add: the deficit of the debt village is structural and not closable by a survivable tax (four combining mechanisms tried); the SuMSy demurrage tax over-collects seven to one; the greed critique is a critique of damped prices and of universal insatiable greed, not of the money system; and the reviewer's items now settled (2×2 confound: still open; RNG streams: done; enterprise affordability, retained interest: still open).

**Languages.** The Dutch body stops at §7; every changed section restarts the translation. FR/ES/DE/ZH are front matter only.

## 3. Rung table (filled from ladder2 when the runs are in)

`ladder2_64_summary.csv`, 10 seeds, per-subsystem streams, 100 rounds; alive (min) / unemployed / tickets / bread price / public debt (% of GDP) / deficit a round / cash Gini — debt village first, SuMSy second.

| rung | debt | SuMSy |
|---|---|---|
| 0 bare bones | 15.3 (11) / 6.8 / — / 5.66 / — / — / 0.34 | 53.1 (40) / 26.9 / — / 20.7 / — / — / 0.36 |
| 1 + planning margin | 16.2 / 7.0 / — / 4.94 / — / — / 0.27 | 64 / 29.7 / — / 3.39 / — / — / 0.09 |
| 2 + government | 64 / 22.8 / — / 4.37 / 21,354 (305 %) / 170 / 0.47 | 64 / 22.8 / — / 3.19 / 0 / surplus 72 / 0.09 |
| 3 + interest on deposits | 64 / 22.9 / — / 4.28 / 21,309 (311 %) / 168 / 0.46 | as 2 |
| 4 + theatre | 64 / 15.9 / 68.5 / 3.81 / 12,269 (173 %) / 87 / 0.61 | 64 / 9.8 / 126.1 / 3.21 / 0 / surplus 73 / 0.09 |
| 5 + government bonds | 63.2 (58) / 17.9 / 47.6 / 3.39 / 12,302 (208 %) / 95 / 0.33 | as 4 |
| 6 + charge on balances | 64 — **runs end before round 88 (check: enterprise_tax = :reserve under debt)** | 64 / 9.9 / 125.6 / 2.48 / 0 / surplus 177 / 0.11 |
| 7 + second theatre | 63.7 (62) / 17.7 / 48.7 / 3.41 / 12,490 (201 %) / 94 / 0.28 | 64 / 9.9 / 125.8 / 3.82 / 0 / surplus 67 / 0.11 |
| 8 + shareholders & share market | 63.6 (61) / 19.2 / 34.9 / 3.35 / 13,637 (237 %) / 96 / 0.34 | 64 / 17.6 / 50.0 / 6.69 / 0 / surplus 93 / 0.45 |
| 9 co-ops, co-op theatre (side) | 63.6 (60) / 17.6 / 50.5 / 3.43 / 12,318 (196 %) / 86 / 0.29 | 64 / 10.4 / 121.0 / 4.85 / 0 / surplus 92 / 0.27 |
| 10 + responsive prices | **63.8 (63)** / 19.5 / 31.8 / 2.96 / 16,091 (320 %) / 95 / 0.33 | 64 / 17.8 / 50.2 / 5.69 / 0 / surplus 100 / 0.60 |
| 11 + government reserve | as 10 (no surplus to dispose of in the debt village) | 63.9 / 17.0 / 59.3 / 6.06 / 0 / tax scale **0.08**, reserve 344 / 0.65 |
| 12 + fiscal policy and VAT | **53.1 (46)** / 18.3 / 15.7 / 2.13 / 13,488 (463 %) / 66 / 0.48 | 64 / 19.3 / 37.6 / 5.16 / 0 / demurrage tax ×1.96, VAT ×0.24 / 0.55 |

**What the second ladder says, and what it changes in the plan above.**
1. Rungs 0–9 reproduce the 15 September ladder in shape at ten seeds (debt village alive from rung 2 on with public debt of 170–310 % of GDP; SuMSy no deaths from rung 1, zero public debt, ~2.5× the tickets, half the unemployment; rung 0 SuMSy 17 % dead). The rung cards can be rewritten from this table as it stands.
2. **The endpoint is a trade-off, not a rung.** The "best debt village" of the block runs (60.9 alive, levers −3:1:0) was found on damped prices. On the cumulative ladder, once prices respond (rung 10), the fiscal policy at rung 12 costs ten lives (63.8 → 53.1) for a lower debt (16.1k → 13.5k) and a smaller deficit (95 → 66). So rung 11 is the best-*surviving* debt village and rung 12 the least-*indebted* survivable one, and the report's closing rung should present both, with the sentence: nothing found this week gives both at once. The plan's §2 for Section 7 is amended accordingly.
3. **The SuMSy mirror at rung 12 exposes a lever semantics to state in §5.6**: levers turn with the policy, so lever −3 on income means "income against the policy": on the SuMSy village's chronic *surplus* the policy cuts, and the lever therefore *raises* the demurrage tax (scale 1.96) while the VAT is cut (0.24). Whether that is wanted is a design question; as written it is what the rule does.
4. Rung 6 debt: the runs stop before round 88 — every row has 64 alive and a public debt of 78, so nothing died; the `enterprise_tax = :reserve` village under debt money appears to hit a stop condition or an error. Not investigated; the card must not be written until it is.
5. Rung 10's responsive prices raise the SuMSy cash Gini from 0.45 (rung 8) to 0.60 and lower the debt village's bread price (3.35 → 2.96) — the distributional cost of responsive prices seen in the greed work, now on the ladder.
