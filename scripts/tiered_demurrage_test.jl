# ======================================================================================================================
# tiered_demurrage_test.jl — does a smaller money stock make the guaranteed income worth more? (21 October 2026, Stef)
#
# The SuMSy village at one step of the ladder, ten seeds, under four to six variants: flat demurrage or tiers, each with the
# sector margins off or on. For each run it records the end-of-run bread and ticket prices, the money stock, what the income
# buys (in meals and in tickets), the three Ginis, the two tenths, the richest tenth's cash, land and shares, and the year's
# demurrage. Means over the seeds are printed and everything is written to results/tiered_demurrage_test.csv.
#
# In the REPL:
#     include("scripts/tiered_demurrage_test.jl")
#     tiered_test()                                   # step 8, seeds 1:10, four variants, on all cores but one
#     tiered_test(seeds = 1:3, jobs = 3)              # a quick look
#     tiered_test(paper_tiers = true)                 # adds two variants with the paper's tiers scaled to the village
#     tiered_test(step = "11 ")                       # another step (the prefix of its name in the ladder)
#     tiered_test(seeds = 1:1, rounds = 6, jobs = 1)   # a smoke test: one seed, six months, this process
#
# The paper's tiers (Kuypers 2024, §4.2) in units of the flat-rate equilibrium balance (income ÷ rate): brackets at 0.25,
# 2.5, 5, 50 and 250 of it, rates 1, 2, 5, 10, 50 and 95 %. Scaled to the village (equilibrium 250, flat rate 2 %): brackets at
# 62.5, 625, 1250, 12500, 62500 above the cushion, rates 2, 4, 10, 20, 100 (capped at 95), 95 %.
# ======================================================================================================================

using Distributed, DataFrames, CSV, Statistics

const TD_ROOT = normpath(joinpath(@__DIR__, ".."))

const TD_SETUP = quote
    using BreadEconomySim, DataFrames, Statistics
    const B = BreadEconomySim
    include(joinpath($TD_ROOT, "scripts", "ladder_definition.jl"))
    const TD_MARGINS = (; pricing_target_farm = :margin, pricing_target_bakery = :margin, pricing_target_theatre = :margin)
    function td_paper_tiers(p)
        telo = p.guaranteed_income / p.demurrage_rate                             # the flat-rate equilibrium balance
        scale = p.demurrage_rate / 0.01                                          # the paper starts from 1 %
        [(0.0, 0.01 * scale), (0.25 * telo, 0.02 * scale), (2.5 * telo, 0.05 * scale), (5 * telo, 0.10 * scale),
         (50 * telo, min(0.50 * scale, 0.95)), (250 * telo, 0.95)]
    end
    function td_run(job)
        def = ladder_definition(512, job.rounds, :invoicing)
        (_, _, ks) = only(r for r in def.rungs if startswith(r[1], job.step))
        p0 = SimulationParameters(; seed = job.seed, def.BARE_SUMSY..., ks...)
        tiers = job.tiers == :flat ? Tuple{Float64, Float64}[] : job.tiers == :test ? DEMURRAGE_TIERS_TEST : td_paper_tiers(p0)
        p = SimulationParameters(; seed = job.seed, def.BARE_SUMSY..., ks..., (job.margins ? TD_MARGINS : (;))..., demurrage_tiers = tiers)
        m = run_simulation(p); d = round_data(m)
        ps = B.persons(m); lp = B.land_valuation_price(m)
        w(x) = B.net_wealth(m, x) - B.share_wealth(m, x) + B.measured_share_wealth(m, x)
        srt = sort(ps; by = x -> -w(x)); k = max(length(ps) ÷ 10, 1); top = srt[1:k]
        bread = mean(skipmissing(filter(!isnan, d.price_bread[max(end-11, 1):end]))); ticket = mean(skipmissing(filter(!isnan, d.price_ticket[max(end-11, 1):end])))
        gi = p.guaranteed_income
        (; variant = string(job.tiers, job.margins ? "+margins" : ""), tiers = job.tiers, margins = job.margins, seed = job.seed,
           alive = d.persons_alive[end], bread_price = bread, ticket_price = ticket,
           bread_change_per_year = nrow(d) > 12 ? 100 * ((d.price_bread[end] / d.price_bread[12])^(12 / (nrow(d) - 12)) - 1) : NaN,
           money_stock = d.money_in_circulation[end], income_in_meals = gi / (p.breads_per_meal * bread), income_in_tickets = gi / ticket,
           gini_cash = d.gini_cash_persons[end], gini_wealth = d.gini_net_wealth_persons[end], gini_total = d.gini_total_wealth_persons[end],
           richest_tenth_meals = d.wealth_top10_meals[end], poorest_tenth_meals = d.wealth_bottom10_meals[end],
           top_cash = sum(B.cash(x) for x in top), top_land = sum(x.land for x in top) * lp, top_shares = sum(B.measured_share_wealth(m, x) for x in top),
           demurrage_last_year = sum(d.money_destroyed[max(end-11, 1):end]), dividends_last_year = sum(d.dividends_forprofit[max(end-11, 1):end]),
           land_price = lp, tickets_sold = d.tickets_sold[end], unemployed = d.unemployed[end])
    end
end

Distributed.remotecall_eval(Main, [1], TD_SETUP)

"""
    tiered_test(; step = "8 ", seeds = 1:10, rounds = 120, jobs = max(Sys.CPU_THREADS - 1, 1), paper_tiers = false)

Run the variants over the seeds, print the means per variant, write results/tiered_demurrage_test.csv, return the DataFrame.
"""
function tiered_test(; step::AbstractString = "8 ", seeds = 1:10, rounds::Int = 120, jobs::Int = max(Sys.CPU_THREADS - 1, 1), paper_tiers::Bool = false)
    tiers = paper_tiers ? (:flat, :test, :paper) : (:flat, :test)
    jobs_list = [(; step = String(step), seed, rounds, tiers = t, margins) for t in tiers for margins in (false, true) for seed in seeds]
    n = min(jobs, length(jobs_list))
    if n > 1
        workers() == [1] || rmprocs(workers())
        addprocs(n; exeflags = ["--project=$TD_ROOT", "-O1", "--heap-size-hint=4G"])
        Distributed.remotecall_eval(Main, workers(), TD_SETUP)
        rows = pmap(WorkerPool(workers()), jobs_list) do job; td_run(job) end
        rmprocs(workers())
    else
        rows = [td_run(job) for job in jobs_list]
    end
    df = DataFrame(rows)
    mkpath(joinpath(TD_ROOT, "results")); CSV.write(joinpath(TD_ROOT, "results", "tiered_demurrage_test.csv"), df)
    summary = combine(groupby(df, :variant), :alive => mean => :alive, :bread_price => mean => :bread, :ticket_price => mean => :ticket,
                      :bread_change_per_year => mean => :bread_pct_yr, :money_stock => mean => :money_stock,
                      :income_in_meals => mean => :income_meals, :income_in_tickets => mean => :income_tickets,
                      :gini_cash => mean => :gini_cash, :gini_wealth => mean => :gini_wealth, :poorest_tenth_meals => mean => :poorest,
                      :richest_tenth_meals => mean => :richest, :top_cash => mean => :top_cash, :top_land => mean => :top_land,
                      :top_shares => mean => :top_shares, :demurrage_last_year => mean => :demurrage_yr, :land_price => mean => :land_price)
    show(stdout, summary; allcols = true, allrows = true); println()
    println("\nwritten: results/tiered_demurrage_test.csv ($(nrow(df)) runs)")
    return df
end
nothing
