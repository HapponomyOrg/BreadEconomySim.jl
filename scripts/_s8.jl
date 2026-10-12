include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
d = round_data(run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., offer_full_capacity = false)))
println("step 8 sumsy needs-based: rows ", nrow(d), " alive ", d.persons_alive[[1, min(12, end), min(24, end), end]], " hungry ", d.hungry[[1, min(12, end), min(24, end), end]], " bread ", round.(d.price_bread[[1, min(12, end), min(24, end), end]], digits = 2), " baked ", round.(Int, d.bread_baked[[1, min(12, end), min(24, end), end]]), " unemployed ", d.unemployed[[1, min(12, end), end]])
