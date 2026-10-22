include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, CSV
def = ladder_definition(512, 120, :invoicing)
step, sys = ARGS[1], ARGS[2]
(name, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
d = round_data(run_simulation(SimulationParameters(; seed = 1, base..., kw...)))
o = CSV.read(ARGS[3], DataFrame)
cols = [:persons_alive, :price_bread, :government_debt, :unemployed, :money_in_circulation, :hungry, :liquidations]
diffs = [c for c in cols if !all(isequal(d[i, c], o[i, c]) || isapprox(d[i, c], o[i, c]; rtol = 1e-9) for i in 1:min(nrow(d), nrow(o)))]
println("REGRESSION step ", step, " ", sys, " seed 1: ", isempty(diffs) ? "identical to 2026-10-20.4 in every month" : "DIFFERS in $(diffs); first month off: $(findfirst(i -> !isapprox(d[i, :persons_alive], o[i, :persons_alive]) || !isapprox(d[i, :money_in_circulation], o[i, :money_in_circulation]; rtol = 1e-9), 1:min(nrow(d), nrow(o))))")
