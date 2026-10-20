include(joinpath(@__DIR__, "ladder_definition.jl"))
using DataFrames
def = ladder_definition(512, 120, :invoicing)
step, seed, rounds = ARGS[1], parse(Int, ARGS[2]), parse(Int, ARGS[3])
(_, _, ks) = only(r for r in def.rungs if startswith(r[1], step * " "))
d = round_data(run_simulation(SimulationParameters(; seed = seed, def.BARE_SUMSY..., ks..., (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true, own_market_planning = true, firms_plan_on_sales = false, market_rounds = 4)..., (step == "NJ8" ? (; contracts = false) : (;))..., market_rounds = rounds)))
println(step, " SuMSy seed ", seed, " rounds ", rounds, " — alive ", d.persons_alive[end], ", months with no grain traded ", count(isnan, d.price_grain), ", bread ", round(d.price_bread[end], digits = 2), " (", round(100 * ((d.price_bread[end] / d.price_bread[12])^(1 / 9) - 1), digits = 1), " %/yr), grain ", round(d.price_grain[end], digits = 2))
