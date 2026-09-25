# BreadEconomySim.jl — modularity analysis
*25 September 2026. A report on how far the code is from plug-and-play agents, enterprises, markets and government — including agents whose behaviour is steered by AI calls — and what it would take to get there. Nothing was changed.*

## 1. The verdict in short

The model is a **transparent, well-tested, procedural simulation**. Its rules are easy to find and to read, every draw is reproducible, and 575 tests plus bit-exact golden values guard it. It is **not modular in the plug-and-play sense**. There are two agent structs, a `Person` and an `Enterprise` whose role is a symbol (`:farm`, `:bakery`, `:theatre`, `:bank`, `:government`). A round is a fixed list of 38 global procedures, each of which loops over every agent and branches on its type or role. The *decisions* an agent makes — what to produce, what to ask, whether to hire, buy, borrow, sell land, join a co-op, hoard — are written inside the market procedures, not on the agent. Replacing a behaviour means editing those procedures; adding a kind of agent means touching most files; steering an agent by an AI call is not possible without a refactor, because there is no point in the code where "this agent decides" is a single call.

The good news: the refactor is staged, mechanical in large part, and protected by the golden values, which must reproduce bit for bit at every stage. The cost is roughly **six to nine weeks of implementation**, of which the first stage — the one that also makes AI-steered agents possible — is two to three weeks.

## 2. The code as it stands

| | count | consequence |
|---|---|---|
| source lines | 5,315 in 13 files; `credit.jl` alone 1,730 | settlement, credit, liquidation, founding and entry share one file |
| agent structs | 2 (`Person`: 41 fields; `Enterprise`: 55 fields) | every role's state lives in one struct: an `Enterprise` carries bank, co-op and theatre fields whatever it is |
| role dispatch | `kind == :x` branches: 42; `is_farm/is_bank/…` calls: 80; `isa Person / isa Enterprise` checks: 161 | behaviour is selected by testing the role inside procedures, not by dispatching on a type |
| round steps | 38 global functions in one list (`ROUND_BEHAVIORS`) | the pipeline itself is pluggable at the step level (a step is a function); the inside of a step is not |
| market procedures | 7 hand-written markets (land, labour ×2, grain, bread, tickets, shares) over one `negotiate` routine | a new good needs a new procedure; the matching logic is shared, the decision logic is not |
| parameters | one struct of 258 fields | no per-role parameter sets; agent heterogeneity is one flag (`greed`) |
| model state | 108 properties on the model, 49 event kinds | rich observability — an asset for any decision interface |
| decision points inside procedures | ≈ 15 (see §4) | the seams along which to cut |

What already helps:
- **One pipeline of steps.** Adding or reordering a step is one line. Settlement, liquidation, restarts and entry were added this way without touching the markets.
- **One routing function for every payment** (`settlement_way`) and **one negotiation routine** — the model already has chokepoints where a general mechanism replaced special cases.
- **Per-subsystem random streams**, version-stable: a behaviour swap in one part of the model does not disturb the draws elsewhere.
- **The event log and the per-round data**: an AI-steered agent needs to observe its situation, and most of what it would need is already recorded.
- **The test suite**: golden values pin the current rules to nine digits. A refactor that keeps them is, by construction, behaviour-preserving.

## 3. The gaps, layer by layer

**Agent state.** Two concrete structs with a symbol for the role. A new kind of enterprise (a mill, a landlord company, a mutual) means either new fields in `Enterprise` or a third struct, and the latter breaks every one of the 161 `isa` checks and the `Union{Person, Enterprise}` agent type. Persons are all alike except for the `greed` flag; households with different preferences, ages or skills cannot be expressed.

**Behaviour.** The rules are inlined. `bread_market!` computes the buyer's willingness, the seller's floor, the order of buyers and the purchase; `labour_market!` computes the reservation wage and hires; `land_market!` computes reservations, funding routes and bids. There is no `decide(agent, situation)`; the agent is a bag of state that procedures read and write.

**Markets.** Each good has its own procedure with its own conventions (bread buyers shuffle, farms hire in turns, land buyers sort by cash). Matching and price adaptation could be one engine parameterised by good; today they are seven copies with local variations.

**Government.** A singleton `Enterprise` of kind `:government` with its rules in `government.jl` (hiring, benefit, taxes, reserve, levers). The fiscal policy is a set of `if`s, not an object one could replace with a different policy or an AI-steered one.

**Parameters.** One 258-field struct; every rule reads the fields it needs. Role-specific settings (a bakery's planning margin, a bank's rate cap) are global; two bakeries cannot differ.

## 4. The target: a decision interface, then composition

The change that unlocks everything is to make each decision a **call on the agent's policy**, with the current rule as the default implementation. Julia's multiple dispatch makes this natural: an agent gets a `policy` field; markets call `decide_ask(policy, agent, good, model)` and get a number; `RuleBased` answers with today's formula, another policy answers differently, an `AIPolicy` answers by asking a model. The decision points, from the code:

| decision | today computed in | interface |
|---|---|---|
| production target, planning margin | `record_and_adapt!`, `take_stock!` | `plan_production(policy, firm, model)` |
| ask and bid, price adaptation | `negotiate`, market procedures, `record_and_adapt!` | `quote(policy, agent, good, model)` |
| labour offered, reservation wage | `labour_supply` | `offer_labour(policy, person, model)` |
| hiring, members first | `hire!`, `labour_market!` | `hire(policy, firm, applicants, model)` |
| what to buy (bread, tickets, extra), cushion, greed | `bread_market!`, `ticket_market!`, `greed_spending!` | `spend(policy, person, budget, model)` |
| borrow or dip into savings | `fund!`, `request_loan!` | `finance(policy, agent, need, model)` |
| buy or sell land, on what terms | `land_market!` | `land_bid(policy, …)`, `land_offer(policy, …)` |
| join a cooperative | `join_cooperatives!` | `join(policy, person, coop, model)` |
| dividends, retained reserve | `pay_dividends!` | `distribute(policy, firm, model)` |
| bank rate, lend or refuse | `set_interest_rates!`, `affordable` | `lend(policy, bank, request, model)` |
| government: hire, benefit, taxes, reserve, levers | `government.jl` | `fiscal_policy(policy, government, model)` |
| **transition: participation level** (planned) | — | `participate(policy, agent, model)` — the first interface to write |

Then composition instead of a symbol: an `Enterprise` holds a `role` object (`Farm`, `Bakery`, `Theatre`, `Bank`, `Government`, later `Mill`) with that role's state and parameters; the 122 role branches become dispatch on the role type; a new role is a new type plus its policy defaults. Markets become instances of one engine (`Market(good, sellers, buyers, matching, adaptation)`), each good a configuration. Parameters split into groups per role, each agent able to carry its own copy.

## 5. AI-steered agents specifically

With the decision interface in place, an `AIPolicy` is one more policy type. Three things it needs that the rules do not:

1. **An observation function** — `observe(agent, model)` returning a compact, serialisable picture (cash, stock, recent prices, own history, market signals). The event log and the round data already hold most of it.
2. **A call budget.** 2,048 units of labour, 512 villagers, 38 steps, 120 months: a call per decision is out of the question. Realistic patterns: AI for a *few* agents (one bakery, the government), the rules for the rest; decisions taken quarterly and held in between; batched calls; a cache keyed on the observation so identical situations reuse an answer.
3. **Reproducibility.** An AI answer is not a stable random draw. Runs with AI agents need a **replay log**: every observation and answer recorded, so a run can be repeated from the log without the API, and the golden-value discipline survives in that form.

The design also settles a question the transition raises: the "weigh the advantages" rule for participation is exactly the kind of decision an AI policy could take instead of a formula, and it is the natural first experiment.

## 6. Effort, staged, each stage leaving the golden values intact

| stage | work | size | what it buys |
|---|---|---|---|
| 1 | extract the decision interface: the ≈ 15 calls of §4, `RuleBased` defaults reproducing today's rules bit for bit; markets call the interface | **2–3 weeks** | swappable behaviour; the door to AI agents; the participation decision for the transition |
| 2 | roles as objects on `Enterprise`; dispatch replaces the 122 role branches; the `Agent` union stays | 1–2 weeks | new kinds of firm without touching existing ones |
| 3 | one market engine, seven configurations; price adaptation in one place | 1–2 weeks | new goods; markets as plug-ins |
| 4 | parameter groups per role; per-agent copies | 3–5 days | heterogeneous agents |
| 5 | `AIPolicy`: observation, batching and cache, replay log; first experiments | 1–2 weeks | AI-steered agents, reproducibly |
| | **total** | **6–9 weeks** | |

Ordering matters: stage 1 first, since it also serves the transition build; stages 2–4 are independent of each other and can wait; stage 5 needs 1 only.

## 7. Risks and where I would resist

- **Performance.** A `policy::Any` field would make Julia's compiler guess. The pattern to use is the one MoneySim.jl applies to its transaction and monetary models: an **abstract supertype per family** (`abstract type Policy end`, `abstract type FiscalPolicy end`, `abstract type Role end`), concrete parametric structs under it (`struct RuleBased <: Policy`, `struct AIPolicy{C} <: Policy`), and **every method written for the concrete type** (`decide_ask(::RuleBased, …)`, `decide_ask(::AIPolicy, …)`) — as MoneySim does with `initialize_transaction_model!(model, ::StandardYardSaleParams)` beside `initialize_transaction_model!(model, ::GDPYardSaleParams)` under `YardSaleParams`. Dispatch is then resolved at compile time, the agent struct is typed on its policy (`Person{P <: Policy}`), and the cost of the interface is nil. Where a collection must hold mixed policies, a small `Union` keeps dispatch static. Measure once at stage 1 on the 512 ladder to confirm.
- **Over-abstraction.** The model's value is that a reader can find the rule for anything in a page of code. Interfaces must keep that: one default implementation per decision, in one place, named after the decision.
- **Two refactors at once.** The transition adds two currencies and participation. Doing stage 1 *before* the transition means the transition's decisions are born on the interface; doing both at once risks a long stretch with nothing runnable. I would do stage 1, run the ladder to prove the golden values hold, then build the transition on it.
- **The `Agent` union.** Keeping `Union{Person, Enterprise}` (stage 2 composes roles inside `Enterprise` rather than adding structs) avoids touching the 161 `isa` checks; most of them are "is this a person?" and remain valid.

## 8. Recommendation

Do stage 1 now, before the transition: two to three weeks, no change of results, and the transition's participation rule becomes the first decision written on the interface. Decide on AI-steered agents after that, on the strength of a first experiment with one AI-steered bakery against 511 rule-based villagers, replayable from its log.
