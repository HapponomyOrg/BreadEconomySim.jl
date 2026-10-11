include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "V8"))
for k in 1:2
    m = run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., fixed_prices = false, maximum_rounds = 120)); d = round_data(m)
    println("run ", k, ": ended ", nrow(d), " baked ", round.(Int, d.bread_baked[max(1, end-13):end]), " alive ", d.persons_alive[max(1, end-13):end], " hungry ", d.hungry[max(1, end-13):end], " wage ", round.(d.price_wage[max(1, end-13):end], digits = 2)); flush(stdout)
end
