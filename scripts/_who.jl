include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
const B = BreadEconomySim
def = ladder_definition(512, 120, :invoicing)
(_, kd, _) = only(r for r in def.rungs if startswith(r[1], "8 "))
label = ARGS[1]
m = create_bread_economy(SimulationParameters(; seed = 4, def.BARE_DEBT..., kd..., (label == "nocontracts" ? (; contracts = false) : (;))..., maximum_rounds = 90))
dead = NamedTuple[]
for r in 1:90
    snap = Dict(w.id => (contract = w.contract > 0, debt = B.debt_of(w), cash = B.cash(w), units = sum(values(w.units_last); init = 0.0), hunger = w.hunger, fee = w.fee, land = w.land) for w in B.persons(m))
    B.econo_step!(m, 1)
    alive = Set(w.id for w in B.persons(m))
    for (id, s) in snap; id in alive || push!(dead, (; month = r, s...)); end
    if r in (30, 60, 90)
        ps = B.persons(m)
        c = [w for w in ps if w.contract > 0]; t = [w for w in ps if w.contract == 0]
        mu(v) = isempty(v) ? 0.0 : round(mean(v), digits = 2)
        println(label, " m", r, ": contracted ", length(c), " work ", mu([sum(values(w.units_last); init = 0.0) for w in c]), " cash ", mu([B.cash(w) for w in c]), " debt ", mu([B.debt_of(w) for w in c]), " | others ", length(t), " work ", mu([sum(values(w.units_last); init = 0.0) for w in t]), " cash ", mu([B.cash(w) for w in t]), " debt ", mu([B.debt_of(w) for w in t]), " with debt ", count(w -> B.debt_of(w) > 1, t), " idle ", count(w -> sum(values(w.units_last); init = 0.0) < 0.5, t))
    end
end
println(label, " — died by month 90: ", length(dead), "; of them on contract the month before ", count(x -> x.contract, dead), "; in debt ", count(x -> x.debt > 1, dead), " (mean debt ", round(mean(x.debt for x in dead), digits = 1), "); worked the month before ", count(x -> x.units > 0.5, dead), " (mean units ", round(mean(x.units for x in dead), digits = 2), "); landowners ", count(x -> x.land > 0, dead))
