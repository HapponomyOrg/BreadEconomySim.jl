# Future work

Designs and analyses that are written but not built. Each is self-contained; the handoff (`HANDOFF_2026-09-18.md`) records the decisions taken on them.

- `design_transition_2026-09-23.md` — the transition from the debt village to SuMSy: two currencies with the reciprocity principle, two paths (set by the government; bottom-up), loans and banks, the exchange market, the sweep on the switch month and the conversion period, the supplemental co-op variants. Waits for the 25 September results to choose the starting villages and the target.
- `modularity_report_2026-09-25.md` — how far the code is from plug-and-play agents, enterprises, markets and government (and AI-steered agents), and the staged refactor to get there (six to nine weeks; stage 1, the decision interface, first).
- `report_revision_plan.md` — the plan for the public report's next version.

Implemented designs are in `../designs_implemented/` (settlement and taxes, 21 September; market entry, 25 September).

Not yet written down: a monetary policy for SuMSy (a rule adjusting the parking fee toward a target such as what the guaranteed income buys in bread — 25 September, Stef), and the tracing of the `clearing_all` SuMSy indebtedness at steps 4–7 (review 6 §2.4).


*16 October 2026:* work as purpose — built (see its status note); modularity — addendum of 16 October; transition — waits for the talk; new: Gesell's own land scheme (public purchase with bonds, lease to the highest bidder, the rent paid out) as a possible village, not designed yet.

*18 October 2026:* Gesell's own land scheme — built as public land (`public_land`, PL8 and its dwelling-rent policies); the lease to the highest bidder is not modelled, the rent is a lever. New since: labour contracts and experience (built; the design note in `docs/designs_implemented/`).

*19 October 2026:* `roadmap_macrosim_2026-10-18.md` (Stef) — the plan from BreadEconomySim to MacroSim; its step 3 (distributions, paired tests) is partly done in `run_all.jl` and `scripts/paired_tests.py`; its step 12.5 (the claims ledger) is next after the talk.

*23 October 2026:* `banks_on_real_world_economics_2026-10-23.md` — the model's banks keep 83–97 % of their revenue (one employee, the loan rate at its cap); costs that scale with customers and loans, calibrated to real margins; the long-run test of the 2021 paper's `p`.

*25 October 2026:* `roadmap_macrosim_2026-10-18.md` brought up to date — the state of the bread model before the refactor, the week's bugs as test-harness lessons, findings per step, relationships between actors (step 7, item 8, on MoneySim.jl's population model), new open questions. The refactor is the next step.
