using BreadEconomySim, DataFrames, Statistics
function summary_row(name, kw, s)
    m = run_simulation(SimulationParameters(; seed = s, kw...)); d = round_data(m)
    (variant = name, seed = s, rounds = nrow(d), stop = m.termination_reason, alive = d.persons_alive[end], farms = d.farms_open[end], bakeries = d.bakeries_open[end],
     money = round(d.money_in_circulation[end], digits=1), debt = round(d.outstanding_debt[end], digits=1), gov_debt = round(d.government_debt[end], digits=1),
     bread = round(mean(d.bread_baked), digits=1), hungry = sum(d.hungry), unemployed = round(mean(d.unemployed), digits=1), refusals = d.cumulative_credit_refusals[end],
     gini_nw = round(d.gini_net_wealth_persons[end], digits=3), trade_arrears = round(d.trade_arrears[end], digits=1))
end
variants = [("clearing", (;)), ("clearing_noprot", (; reserve_protection_probability = 0.0)), ("clearing_t30", (; wage_tax_rate = 0.30))]
rows = [summary_row(n, kw, s) for (n, kw) in variants for s in 1:6]
b = DataFrame(rows)
show(stdout, b; allrows = true, allcols = true); println()
