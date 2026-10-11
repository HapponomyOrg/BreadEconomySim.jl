include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
def = ladder_definition(512, 120, :invoicing)
const B = BreadEconomySim
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], "V8"))
m = create_bread_economy(SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., fixed_prices = false, maximum_rounds = 8))
for r in 1:7
    B.econo_step!(m, 1)
    ws = B.persons(m); bak = first(B.enterprises(m, :bakery)); th = first(B.enterprises(m, :theatre))
    asks = [w.ask[:wage] for w in ws if w.alive]
    println("m", r, " paid wage ", round(B.going_wage(m), digits = 2), " expected ", round(B.expected_price(m, :wage), digits = 2), " asks mean/min/max ", round(mean(asks), digits = 2), "/", round(minimum(asks), digits = 2), "/", round(maximum(asks), digits = 2),
            " bakery bid ", round(bak.bid[:wage], digits = 2), " ceiling ", round(B.buyer_reservation(m, bak, :wage), digits = 2), " own limit ", round(B.employer_wage_limit(m, bak), digits = 2), " theatre ceiling ", round(B.buyer_reservation(m, th, :wage), digits = 2),
            " hired ", round(Int, sum(e.hired_labour for e in B.alive_agents(m) if e isa B.Enterprise; init = 0.0)), " baked ", round(Int, m.data[end].bread_baked), " alive ", count(w -> w.alive, ws)); flush(stdout)
end
