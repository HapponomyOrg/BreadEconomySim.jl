include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
const B = BreadEconomySim
def = ladder_definition(512, 120, :invoicing)
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "S3 "))
m = create_bread_economy(SimulationParameters(; seed = 4, def.BARE_SUMSY..., ks..., maximum_rounds = 56))
for r in 1:55
    if r >= 50
        bs = B.enterprises(m, :bakery); ps = B.persons(m)
        res = [B.buyer_reservation(m, w, :bread) for w in ps[1:50]]
        println("before m", r, ": bakery asks ", round.([b.ask[:bread] for b in bs], digits = 2), " reservations ", round.([B.seller_reservation(m, b, :bread) for b in bs], digits = 2), " greedy firms ", [B.greedy_firm(m, b) for b in bs], " targets ", [b.production_target for b in bs], " grain held ", round.([B.grain_units(b) for b in bs], digits = 1), " bread held ", round.([B.bread_units(b) for b in bs], digits = 0), " | buyers' max bid: median ", round(median(res), digits = 2), " max ", round(maximum(res), digits = 2), " | buyers' cash median ", round(median(B.cash(w) for w in ps), digits = 1), " intervention ", m.intervention)
    end
    B.econo_step!(m, 1)
    if r >= 50
        x = m.data[end]
        println("   after m", r, ": baked ", round(Int, x.bread_baked), " sold ", round(Int, x.bread_sold), " price ", round(x.price_bread, digits = 2), " hungry ", x.hungry, " grain traded at ", round(x.price_grain, digits = 2), " harvested ", round(Int, x.grain_harvested), " unemployed ", round(Int, x.unemployed), " contracted ", x.contracted)
    end
end
