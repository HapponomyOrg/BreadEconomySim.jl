include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
step, sys, seed = ARGS[1], ARGS[2], parse(Int, ARGS[3])
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
d = round_data(run_simulation(SimulationParameters(; seed = seed, base..., kw...))); r = d[end, :]
println(step, " ", sys, " seed ", seed, " — alive ", r.persons_alive, ", hungry peak ", maximum(d.hungry), ", bakeries at 24/60/120 ", d.bakeries_open[[24, 60, end]], ", farms ", d.farms_open[[24, 60, end]], ", closures ", r.closures, ", liquidations ", r.liquidations, ", intervention months ", r.intervention_months, ", bread ", round(r.price_bread, digits = 2), " (", round(100 * ((d.price_bread[end] / d.price_bread[12])^(1 / 9) - 1), digits = 1), " %/yr), unemployed ", round(Int, r.unemployed), ", public debt ", round(Int, r.government_debt / 1000), "k, gap ", round(r.wealth_gap_meals, digits = 1), ", bottom tenth ", round(r.wealth_bottom10_meals, digits = 1))
