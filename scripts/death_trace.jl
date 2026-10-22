# ======================================================================================================================
# death_trace.jl — who dies in a village, and what their month before death looked like (22 October 2026)
#
#     include("scripts/death_trace.jl")
#     death_trace()                                                            # step 8, debt money, package T, seed 1
#     death_trace(step = "11 ", fiscal = :taxes, seed = 1)
#     death_trace(step = "11 ", fiscal = :parking, seed = 2, extra = FLOOR_TWO_LOAVES)   # with a variant's settings
#
# Prints, for the villagers who died: how many worked the month before (and how much), how many received the benefit (and
# what a meal cost), how many were in debt (and how much), their cash, whether bread was left unsold that month (it usually
# is not: they could not pay), and the deaths by year. Runs in this process. The constants FLOOR_TWO_LOAVES, PARTIAL_BENEFIT
# and FLOOR_AND_PARTIAL are in scripts/run_all.jl; pass any NamedTuple of settings as `extra`.
# ======================================================================================================================
using DataFrames, Statistics
include(joinpath(@__DIR__, "ladder_definition.jl"))
const DT_B = BreadEconomySim

function death_trace(; step::AbstractString = "8 ", system::AbstractString = "debt", fiscal::Symbol = :taxes, seed::Int = 1, extra = (;), rounds::Int = 120)
    def = ladder_definition(512, rounds, :invoicing; fiscal = fiscal)
    (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], step))
    base, kw = system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
    m = create_bread_economy(SimulationParameters(; seed, base..., kw..., extra...))
    dead = NamedTuple[]
    for r in 1:rounds
        snap = Dict(w.id => (worked = sum(values(w.units_last); init = 0.0), fee = w.fee, debt = DT_B.debt_of(w) + DT_B.peer_debt_of(m, w), cash = DT_B.cash(w), hunger = w.hunger, land = w.land) for w in DT_B.persons(m))
        DT_B.econo_step!(m, 1)
        alive = Set(w.id for w in DT_B.persons(m)); x = m.data[end]
        for (id, s) in snap; id in alive || push!(dead, (; month = r, s..., bread_unsold = x.bread_baked - x.bread_sold, price = x.price_bread)); end
    end
    d = round_data(m); n = length(dead)
    println(name, " | ", system, " | fiscal ", fiscal, " | seed ", seed, isempty(extra) ? "" : " | " * string(extra))
    n == 0 && (println("  nobody died (", d.persons_alive[end], " alive)"); return DataFrame(dead))
    recv = [x for x in dead if x.fee > 1e-6]
    println("  ", n, " died (", d.persons_alive[end], " alive). The month before dying: worked at all ", count(x -> x.worked > 0.5, dead), " (mean units among them ",
            round(mean(x.worked for x in dead if x.worked > 0.5; init = 0.0), digits = 2), "); received the benefit ", length(recv), " (mean ", round(isempty(recv) ? 0.0 : mean(x.fee for x in recv), digits = 2),
            " against a meal of ", round(2 * mean(x.price for x in dead), digits = 2), "); in debt ", count(x -> x.debt > 1, dead), " (mean ", round(mean(x.debt for x in dead), digits = 1),
            "); cash mean ", round(mean(x.cash for x in dead), digits = 1), "; landowners ", count(x -> x.land > 0, dead), "; bread left unsold that month, mean ", round(mean(x.bread_unsold for x in dead)),
            "; months hungry before death, mean ", round(mean(x.hunger for x in dead), digits = 1))
    println("  deaths by year: ", [count(x -> (y - 1) * 12 < x.month <= y * 12, dead) for y in 1:(rounds ÷ 12)], "; at the end: bread ", round(d.price_bread[end], digits = 2), ", unemployed ", round(Int, d.unemployed[end]), ", under water ", d.negative_wealth_persons[end])
    return DataFrame(dead)
end
nothing
