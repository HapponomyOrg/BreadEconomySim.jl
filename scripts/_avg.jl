include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
const REALISTIC_LABOUR = (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true, own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1)
def = ladder_definition(512, 120, :invoicing)
step, seed, sys = ARGS[1], parse(Int, ARGS[2]), ARGS[3]
(_, kd, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
base, kw = sys == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
d = round_data(run_simulation(SimulationParameters(; seed = seed, base..., kw..., REALISTIC_LABOUR...)))
inf(c) = round(100 * ((d[end, c] / d[12, c])^(1 / 9) - 1), digits = 1)
println(step, " ", sys, " seed ", seed, " (three-month average, net of stock) — alive ", d.persons_alive[end], ", bakeries at 24/60/120 ", d.bakeries_open[[24, 60, 120]], ", farms ", d.farms_open[[24, 60, 120]], ", new firms ", round(Int, d.new_firms[end]), ", hungry at the worst month ", maximum(d.hungry), ", months under the emergency rule ", d.intervention_months[end], ", bread ", inf(:price_bread), " %/yr, unemployed ", round(Int, d.unemployed[end]), ", poorest tenth ", round(d.wealth_bottom10_meals[end], digits = 1))
