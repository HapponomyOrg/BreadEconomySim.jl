include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
label = ARGS[1]
(_, kd, _) = only(r for r in def.rungs if startswith(r[1], "2 "))
extra = label == "base" ? (;) : label == "shareplan" ? (; own_market_planning = false, firms_plan_on_sales = true) : label == "oneround" ? (; market_rounds = 1) : label == "min1" ? (; refound_minimum = 1) : label == "nocontracts" ? (; contracts = false) : label == "allold" ? (; own_market_planning = false, firms_plan_on_sales = true, market_rounds = 1, refound_minimum = 1, contracts = false, uncovered_debt_sale = false) : label == "oldclose" ? (; uncovered_debt_sale = false) : (; own_market_planning = false, firms_plan_on_sales = true, market_rounds = 1, refound_minimum = 1, contracts = false)
d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_DEBT..., kd..., extra...)))
deaths = [m for m in 2:nrow(d) if d.persons_alive[m] < d.persons_alive[m - 1]]
println("step 2 debt seed 1 ", label, " — alive at 12/24/36/60/120: ", d.persons_alive[[12, 24, 36, 60, end]], ", first deaths ", deaths[1:min(5, end)], ", hungry peak ", maximum(d.hungry), " (month ", argmax(d.hungry), "), bakeries min ", minimum(d.bakeries_open), ", farms min ", minimum(d.farms_open), ", closures ", d.closures[end], ", interventions ", d.intervention_months[end], ", baked/need at the hungriest month ", round(Int, d.bread_baked[argmax(d.hungry)]), "/", 2 * d.persons_alive[argmax(d.hungry)], ", bread ", round(d.price_bread[end], digits = 2), ", unemployed ", round(Int, d.unemployed[end]), ", poorest tenth ", round(d.wealth_bottom10_meals[end], digits = 1))
