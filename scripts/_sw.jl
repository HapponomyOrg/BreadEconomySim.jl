include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
step = ARGS[1]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks...))); r = d[end, :]
println(step, " sumsy — alive ", r.persons_alive, ", hungry peak ", maximum(d.hungry), ", bakeries open at 24/36/60/120: ", d.bakeries_open[[min(24, end), min(36, end), min(60, end), end]], ", liquidations ", r.liquidations, ", bread at 12/24/36: ", round.(d.price_bread[[12, min(24, end), min(36, end)]], digits = 1), ", grain ", round.(d.price_grain[[12, min(24, end), min(36, end)]], digits = 1), ", land ", round(Int, r.land_price_traded))
