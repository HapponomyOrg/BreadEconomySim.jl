include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
const B = BreadEconomySim
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "V8"))
for rounds in (8, 120)
    m = run_simulation(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., fixed_prices = false, maximum_rounds = rounds)); d = round_data(m)
    println("max ", rounds, ": ended ", nrow(d), " '", m.termination_reason, "' baked ", round.(Int, d.bread_baked[1:min(7, end)]), " alive ", d.persons_alive[1:min(7, end)], " hungry ", d.hungry[1:min(7, end)]); flush(stdout)
end
