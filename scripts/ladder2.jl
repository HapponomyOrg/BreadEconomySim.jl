using BreadEconomySim, DataFrames, CSV, Statistics

nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6
rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50

# Behaviour rules needed for any village to function at all (Section 5 of the report); not components.
N = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 16
RULES = (; number_of_persons = N, number_of_landowners = N ÷ 4, land_per_person = 1.5, initial_production_target = max(N ÷ 6, 6), shares_per_person = (N > 16 ? 10 : 0), shareholder_count = max(N ÷ 16, 2), demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true,
          random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true,
          distress_land_sales = true, maximum_capacity = 4.0,
          wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation,
          gluttony_probability = 0.1, plan_for_gluttony = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
# Bare bones: no government activity, no benefit, no interest on deposits, no theatre, no margin.
BARE_DEBT = (; RULES..., wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
              partial_unemployment_fee = false, government_employment_share = 0.0, account_fee_person = 0.0, account_fee_enterprise = 0.0)
BARE_SUMSY = (; BARE_DEBT..., monetary_system = :sumsy, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02,
               account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
GOV_DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.10)
GOV_SUMSY = (; demurrage_tax_rate = 0.01, government_employment_share = 0.10)       # public jobs funded by a 1 % demurrage tax; the GI is the benefit
DEP = (; deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)

# ---------------------------------------------------------------------------------------------------------------------
# ladder2.jl (20 September 2026): the report's ladder rebuilt so that it ends at the best-surviving, least-indebted debt
# village found this week, with SuMSy as the mirror at every rung. Rungs 0–8 are the 15 September ladder; rung 9 is the
# co-op side rung; rungs 10–12 add, cumulatively on rung 8, the price rules, the government reserve and the fiscal policy.
#   julia --project=. -O1 scripts/ladder2.jl <nseeds> <rounds> all <N> [rung prefix]
# Resumable: each run is appended to results/ladder2_<N>_rounds.csv; finished (rung, system, seed) triples are skipped.
V8_DEBT  = (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
V8_SUMSY = (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
CHARGE   = (; enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.02, reserve_tax_exempts_standard_reserve = true)
GREEDY_Q = (; greed = true, greed_share = 0.25)                                                                     # the plausible greed: the richest quarter
GREEDY_A = (; greed = true, greed_share = 1.0, greed_hoarding = 0.5)                                                # the extreme: everyone, half capital half consumption
PRICES   = (; unmet_demand_share = 0.05, unsold_share = 0.05, ask_floor = :cost)                                   # rung 10: prices that respond to scarcity and to loss
RESERVE  = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0)                                # rung 11: a public reserve, the surplus returned as a tax cut
FISCAL   = (; tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0,
             consumption_tax_rate = 0.06, tax_levers = (income = -3.0, consumption = 0.0, wealth = 0.0))            # rung 12: the policy that keeps the debt village alive: wages untaxed, a VAT, the deficit it leaves
rungs = [
    ("0 bare bones",                    (;), (;)),
    ("1 + planning margin",             (; planning_margin = 0.1), (; planning_margin = 0.1)),
    ("2 + government",                  (; planning_margin = 0.1, GOV_DEBT...), (; planning_margin = 0.1, GOV_SUMSY...)),
    ("3 + interest on deposits",        (; planning_margin = 0.1, GOV_DEBT..., DEP...), (; planning_margin = 0.1, GOV_SUMSY...)),
    ("4 + theatre",                     (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true)),
    ("5 + government bonds",            (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true)),
    # 21 September: the 15 September rung charged 10 % a round on all enterprise cash (`enterprise_reserve_tax_rate` default); at ten seeds every debt
    # village lost its last bakery by round 31–51. The charge now mirrors the demurrage: 2 % a round on cash above the working reserve.
    ("6 + charge on balances",          (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, CHARGE...), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, CHARGE...)),
    ("7 + second theatre",              (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 2), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2)),
    ("8 + shareholders & share market", V8_DEBT, V8_SUMSY),
    ("9 co-ops (side rung)",            (; V8_DEBT..., number_of_farms = 4, number_of_bakeries = 4, cooperative_theatres = 1, ownership = :mixed), (; V8_SUMSY..., number_of_farms = 4, number_of_bakeries = 4, cooperative_theatres = 1, ownership = :mixed)),
    ("10 + responsive prices",          (; V8_DEBT..., PRICES...), (; V8_SUMSY..., PRICES...)),
    ("11 + government reserve",         (; V8_DEBT..., PRICES..., RESERVE...), (; V8_SUMSY..., PRICES..., RESERVE...)),
    ("12 + fiscal policy and VAT",      (; V8_DEBT..., PRICES..., RESERVE..., FISCAL...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL...)),
    # Stress tests (21 September): greed on the best cases — rung 11 (best surviving) and rung 12 (least indebted), both systems
    ("S1 rung 11 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_Q...)),
    ("S2 rung 12 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...)),
    ("S3 rung 11 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A...)),
    ("S4 rung 12 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...)),
]
# SuMSy never taxes income: its public money comes from the demurrage tax. Any SuMSy rung with a wage or capital tax is a
# configuration error unless it is an explicit comparison (name it "(comparison)").
for (name, kd, ks) in rungs
    occursin("comparison", name) && continue
    ks_full = (; BARE_SUMSY..., ks...)
    (ks_full.wage_tax_rate == 0 && ks_full.capital_tax_rate == 0) || error("rung '$name': SuMSy must not tax income (wage_tax_rate = $(ks_full.wage_tax_rate), capital_tax_rate = $(ks_full.capital_tax_rate))")
end
only_rung = length(ARGS) >= 5 ? ARGS[5] : ""
only_rung != "" && filter!(r -> startswith(r[1], only_rung), rungs)
path = joinpath(@__DIR__, "..", "results", "ladder2_$(N)_rounds.csv")
done = isfile(path) ? Set(Tuple.(eachrow(unique(CSV.read(path, DataFrame; select = [:rung, :system, :seed]))))) : Set()
for (name, kd, ks) in rungs, (system, base, kw) in (("debt", BARE_DEBT, kd), ("sumsy", BARE_SUMSY, ks)), s in 1:nseeds
    (name, system, s) in done && continue
    m = run_simulation(SimulationParameters(; seed = s, base..., kw...)); d = round_data(m)
    d.rung .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m)
    # append, never rewrite: rewriting a growing file on every run segfaulted the process on 21 September and left the
    # file truncated (rungs 4–12 and S1–S3 lost). All runs share one column set, so appending is safe.
    CSV.write(path, d; append = isfile(path), header = !isfile(path))
    println(name, " ", system, " seed ", s, " alive ", d.persons_alive[end]); flush(stdout)
end
println("DONE")
