# ======================================================================================================================
# profile_run.jl — where does a run spend its time? (24 October 2026)
#
#     julia --project=. scripts/profile_run.jl [months]        # step 8, debt money, package T, seed 1; default 24 months
#
# Samples the run and prints the functions with the most samples (own time and inclusive), BreadEconomySim and EconoSim
# frames only, to results/profile_run.txt as well.
# ======================================================================================================================
using Profile, DataFrames
include(joinpath(@__DIR__, "ladder_definition.jl"))
months = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 24
def = ladder_definition(512, months, :invoicing; fiscal = :taxes)
(_, kd, _) = only(r for r in def.rungs if startswith(r[1], "8 "))
p(m) = SimulationParameters(; seed = 1, def.BARE_DEBT..., kd..., maximum_rounds = m)
run_simulation(p(3))                                                   # compile first
Profile.clear(); Profile.init(n = 20_000_000, delay = 0.005)
t = @elapsed (Profile.@profile run_simulation(p(months)))
buf = IOBuffer(); Profile.print(IOContext(buf, :displaysize => (100, 220)); format = :flat, sortedby = :count, mincount = 20, noisefloor = 0)
lines = split(String(take!(buf)), '\n')
keep = [l for l in lines if occursin("BreadEconomySim", l) || occursin("EconoSim", l) || occursin("Count", l)]
out = joinpath(@__DIR__, "..", "results", "profile_run.txt")
open(out, "w") do io
    println(io, "profile of step 8 debt package T, $months months, $(round(t, digits = 1)) s; flat, by sample count (own-frame lines only)")
    foreach(l -> println(io, l), vcat(keep[1:1], reverse(last(keep, 45))))   # the header, then the hottest first (the flat list is sorted ascending)
end
println("PROFILE ", round(t, digits = 1), " s"); foreach(l -> println(l[1:min(end, 190)]), vcat(keep[1:1], reverse(last(keep, 30))))
