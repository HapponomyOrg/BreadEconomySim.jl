include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames, Statistics
const B = BreadEconomySim
const REALISTIC_LABOUR = (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true, own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1)
def = ladder_definition(512, 120, :invoicing)
label = ARGS[1]
extra = label == "lastmonth" ? (; plan_window = 1) : label == "average" ? (;) : label == "rises" ? (; plan_window_follows_rises = true) : (; own_market_planning = false, firms_plan_on_sales = true)
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
p = SimulationParameters(; seed = 1, def.BARE_SUMSY..., ks..., REALISTIC_LABOUR..., extra...)
m = create_bread_economy(p)
soldout = Dict(:bread => 0, :grain => 0, :ticket => 0); firm_months = Dict(:bread => 0, :grain => 0, :ticket => 0)
short = Dict(:bread => 0, :grain => 0, :ticket => 0)   # months a kind as a whole offered less than was wanted
up = 0; down = 0
for r in 1:120
    B.econo_step!(m, 1)
    for (good, kind) in ((:bread, :bakery), (:grain, :farm), (:ticket, :theatre))
        es = B.enterprises(m, kind); isempty(es) && continue
        for e in es
            mk = e.market[good]; mk.offered > 1e-9 || continue
            firm_months[good] += 1
            mk.sold >= mk.offered * (1 - p.unsold_share) - 1e-9 && (soldout[good] += 1)
        end
        any(e -> e.market[good].unmet_units > 1e-9, es) && (short[good] += 1)
    end
end
d = round_data(m)
inf(c) = round(100 * ((d[end, c] / d[12, c])^(1 / 9) - 1), digits = 1)
println(label, " — bread ", inf(:price_bread), " %/yr; sold-out firm-months: bread ", soldout[:bread], "/", firm_months[:bread], ", grain ", soldout[:grain], "/", firm_months[:grain], ", tickets ", soldout[:ticket], "/", firm_months[:ticket], "; months with turned-away customers: bread ", short[:bread], ", grain ", short[:grain], ", tickets ", short[:ticket])
