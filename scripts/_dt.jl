include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
label = ARGS[1]
(_, kd, _) = only(r for r in def.rungs if startswith(r[1], "8 "))
extra = label == "base" ? (;) : label == "nocontracts" ? (; contracts = false) : label == "shareplan" ? (; own_market_planning = false, firms_plan_on_sales = true) : label == "oneround" ? (; market_rounds = 1) : (; refound_minimum = 1)
d = round_data(run_simulation(SimulationParameters(; seed = 4, def.BARE_DEBT..., kd..., extra...)))
deaths = [(r.round, Int(d.persons_alive[max(r.round - 1, 1)] - r.persons_alive)) for r in eachrow(d) if r.round > 1 && d.persons_alive[r.round - 1] > r.persons_alive]
need(r) = 2 * r.persons_alive
println(label, " — alive at 12/24/36/48/60/84/120: ", d.persons_alive[[12, 24, 36, 48, 60, 84, 120]], " | deaths by month (first 12): ", deaths[1:min(12, end)], " | total months with deaths ", length(deaths))
println(label, " — at the months with deaths: ", [(m, round(Int, d.bread_baked[m]), round(Int, d.bread_sold[m]), d.hungry[m], round(d.price_bread[m], digits = 2), round(Int, d.unemployed[m]), round(Int, d.contracted[m]), round(d.wealth_bottom10_meals[m], digits = 1)) for (m, _) in deaths[1:min(8, end)]], " (month, baked, sold, hungry, bread, unemployed, contracted, poorest tenth)")
println(label, " — end: unemployed ", round(Int, d.unemployed[end]), ", bread ", round(d.price_bread[end], digits = 2), ", benefit per month ", round(d.fees[end] / max(d.unemployed[end], 1), digits = 2), ", bakeries ", d.bakeries_open[end], ", farms ", d.farms_open[end], ", public debt ", round(Int, d.government_debt[end] / 1000), "k, poorest tenth ", round(d.wealth_bottom10_meals[end], digits = 1))
