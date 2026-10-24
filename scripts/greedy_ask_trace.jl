# ======================================================================================================================
# greedy_ask_trace.jl — ten years of the greedy SuMSy village (SB2) under the realistic set and the parking package, with
# the greedy ask on the expected price (as built) and on the price last paid (24 October). Prints bread, wage, the levy's
# scale, the greedy loaves and the unemployed at years 1, 3, 5, 6, 7, 8, 9, 10, and the public debt, survivors and poorest tenth.
#
#     julia --project=. scripts/greedy_ask_trace.jl            # about 20 minutes; one process
# ======================================================================================================================
using BreadEconomySim; const B = BreadEconomySim
include(joinpath(@__DIR__, "ladder_definition.jl"))
const REAL = (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true, own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1, price_on_expected_sales = true, cost_floor_includes_debt_service = true, floor_debt_service = :long, floor_per_unit_sold = true, firm_land_loan_max_rounds = 240, land_price_meets_offers = true)
def = ladder_definition(512, 120, :invoicing; fiscal = :parking)
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "SB2"))
for (label, extra) in (("old greedy ask", (; REAL..., greedy_ask_on_paid_price = false)), ("greedy ask on the price paid", REAL))
    d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., extra...)))
    ms = [12, 36, 60, 72, 84, 96, 108, 120]
    println(label, ": bread ", round.(d.price_bread[ms], digits = 2), " wage ", round.(d.price_wage[ms], digits = 2), " levy scale ", round.(d.land_levy_scale[ms], digits = 1), " greedy loaves ", round.(d.greedy_loaves[ms]), " unemployed ", round.(d.unemployed[ms]), " | public debt ", round(Int, d.government_debt[end]), " alive ", d.persons_alive[end], " poorest ", round(d.wealth_bottom10_meals[end], digits = 1))
end
