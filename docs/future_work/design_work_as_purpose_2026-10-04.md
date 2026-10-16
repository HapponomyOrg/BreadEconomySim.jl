# Design: work as purpose
*4 October 2026 — design only, nothing implemented. Stef: people do not only work for money; work gives purpose. Two ways to put that in the village: everyone offers at least half their capacity for paid work, or volunteer work is introduced.*

## 0. What the village does now, and why it matters
A villager offers exactly the labour that a meal, the cushion and the tickets they want require, and nothing more (`labour_supply`). Once bread is cheap, or the guaranteed income and benefit cover a meal, villagers offer less, and the "unemployed" count falls for the wrong reason: not because they found work but because they stopped looking. This is the satiation floor that capped employment at about 85 % in the productive village and lifted SuMSy unemployment from 12 to 24 % when the benefit came in. It also means the model cannot tell someone who chose leisure from someone who wanted work and found none, except through the `voluntarily_idle` column.

A village of people who want to work, as people do, is different in three ways: labour supply is larger and less sensitive to income; unemployment measures want, not satiation; and what the unemployed do with their time becomes a question the model can ask.

## 1. Option A — a minimum offer of paid work
**Rule.** Every villager offers at least `minimum_labour_offer` (0.5) of their capacity for paid work each month, whatever their needs; above that, the present need-based rule.

**What changes.**
- Labour supply rises wherever needs are small: the productive village, the SuMSy village with the benefit, the greedy villages (who already offer everything). It does not change where villagers already offer all they have (the ladder's base: three units earn barely a meal).
- With more labour offered and the same demand, unemployment *as measured* rises, and so does the pressure on wages through the asks of the unemployed. Under the present rules (wage floor for workers in work, loyalty, notice) that pressure runs through turnover, and the debt village's deflation deepens. The parameter therefore interacts with the labour-market sweep (Y8), and the two should be run together.
- The productive village's satiation floor moves: with everyone offering half their capacity, the theatres and the public project can hire more; whether they *want* to depends on demand, which the rule does not change. So the rule exposes demand-constrained unemployment rather than curing it — which is the honest result.

**Cost.** Two lines in `labour_supply`, one parameter, one test. A sweep of the minimum (0, 0.5, 1.0 = `offer_full_capacity`, which already exists) on step 8 and V8 in both villages.

**What it does not do.** It gives the villager a reason to offer labour, but no purpose is modelled: an unemployed villager who offers half and finds nothing is exactly as idle as before. Option A changes supply; it does not change what the idle do.

## 2. Option B — volunteer work
**Rule.** Labour that is offered and not hired can be given, unpaid, to a *commons*: activities the village values that no firm sells. The village has none at present, so the commons has to be defined. Candidates, in order of how little they bend the model:
1. **Care and community** — an abstract public good: volunteer hours are recorded, produce a village-level "care" output, and count as activity; no money, no market. Purely a measure, but an honest one: it says how much of the idle capacity would be used if volunteering were possible, and splits the idle into volunteers and the truly idle.
2. **Community theatre** — volunteers run shows at cost (tickets at the price of the seat's upkeep, near zero). This gives the volunteers' work a product villagers consume, and it competes with the paid theatres — crowding out, which is real (amateur culture does compete with professional) but which would need a rule for how villagers choose between a free seat and a paid one.
3. **The public project** — volunteers help build it, shortening the five years or lowering its cost. Realistic for some projects (a village hall), less so for public transport; it changes the project's economics and would need to be a variant of T8 rather than the ladder.

**What volunteering must not do.** Substitute for paid labour in the firms. Firms that could take volunteers would take them, wages would collapse, and the result would be a model of exploitation rather than of purpose. The commons must be outside the firms.

**Cost.** Candidate 1: a `volunteer!` step after the labour markets, a `commons_hours` column, `volunteers`, and `truly_idle`; a parameter for the share of unhired labour a villager volunteers (1.0 = all). Half a day. Candidates 2 and 3: a market or a project change each, two or three days, and new questions of their own.

## 3. What purpose adds to the findings
- The unemployment figures throughout the report would split into *want work, found none* (paid), *volunteer*, and *idle by choice*. The debt village's benefit bill and the SuMSy village's benefit are driven by the first; today's figures conflate it with the third.
- The satiation floor, which the productive village ran into, becomes a statement about *demand* for labour rather than supply: with everyone offering half their capacity, 15 % unemployment means the village does not want the work, not that the villagers do not.
- Under SuMSy, volunteering is what the guaranteed income is often argued to enable: people fed enough to work unpaid at what the village values. The model could then say how much of that happens at a given income, and the benefit question (§4 of this note) turns on it.

## 4. The benefit question (Stef, 4 October)
With the land levy paid out to everyone — the Gesell rule — the dividend is a second unconditional income. Whether a benefit is still needed is a run (step 8, SuMSy, loyalty on, levy and dividend, with and without the benefit); the check runs are in the handoff. The design above bears on it: with volunteer work, the long-term unemployed have something to do; with a minimum offer, more of them count as looking.

## 5. Recommendation
Do A first: it is cheap, it changes the labour-supply rule in the direction of realism, and its sweep tells us how much of today's unemployment is satiation. Do B as candidate 1 (the measure) in the same step, so that the idle split into volunteers and idle. Leave candidates 2 and 3 until the split is known; they are variants of existing steps, not new ones. Run both on step 8 and V8 in both villages, with the labour-market sweep, for 11 October if built in time; otherwise for the run after.


## Status (16 October 2026)
Built: option A (`minimum_labour_offer`, on the ladder) and option B's measure (`volunteer_share`, volunteer hours; counted once since 15 October). Volunteer work is a structural flag on any enterprise kind (`volunteer_kinds`; theatres since 4 October, C8), and the community theatre (candidate 2) is an option (`community_theatres`, CT8). Volunteers on the public project (candidate 3) were dropped (Stef, 15 October). Since 12 October the labour supply also has the village's share (`labour_for_bread`), which does most of what option A was meant to do.
