include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
label = ARGS[1]
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "S3 "))
extra = label == "base" ? (;) : label == "nocontracts" ? (; contracts = false) : (; market_rounds = 1)
d = round_data(run_simulation(SimulationParameters(; seed = 4, def.BARE_SUMSY..., ks..., extra...)))
nosale = [(r.round, round(Int, r.bread_baked), r.hungry) for r in eachrow(d) if r.bread_sold < 1 && r.bread_baked > 100]
println("S3 SuMSy seed 4 ", label, " — alive at 24/48/60/72/120: ", d.persons_alive[[24, 48, 60, 72, end]], ", hungry peak ", maximum(d.hungry), " (month ", argmax(d.hungry), "), months with bread baked and none sold: ", nosale[1:min(6, end)], ", bakeries min ", minimum(d.bakeries_open), ", farms min ", minimum(d.farms_open), ", intervention months ", d.intervention_months[end], ", bread ", round(d.price_bread[end], digits = 2), ", poorest tenth ", round(d.wealth_bottom10_meals[end], digits = 1))
