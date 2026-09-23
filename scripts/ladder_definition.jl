using BreadEconomySim

# The ladder as a function of the village size, the run length and the settlement system (22 September), so that one
# process can build several ladders (scripts/run_all.jl). ladder2_rungs.jl calls it with the command-line values.
function ladder_definition(N::Int, rounds::Int, SETTLEMENT::Symbol)
    RULES = (; number_of_persons = N, number_of_landowners = N ÷ 4, land_per_person = 1.5, initial_production_target = 10 * N ÷ 128, shares_per_person = 10, shareholder_count = 4, number_of_farms = 4, number_of_bakeries = 4, shows_per_round = 1, theatre_seat_margin = 0.25, unmet_demand_share = 0.05, unsold_share = 0.05, founding_equity = true, settlement = SETTLEMENT,   # 23 Sept: founders capitalise their firms
           # 22 September: :invoicing = the settlement design (cash at the counter, wages at month end, invoices between firms, clearing among banks)
             initial_interest_rate = 0.005, maximum_interest_rate = 0.015,   # a month: 6 % a year to start, at most about 20 %; the rate itself covers the banks' costs (one staff unit per bank: staff scaled with customers bankrupted the banks at 512, 22 Sept)
              demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true,
              random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true,
              distress_land_sales = true, maximum_capacity = 4.0,
              wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation,
              gluttony_probability = 0.1, plan_for_gluttony = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
    # Bare bones: no government activity, no benefit, no interest on deposits, no theatre, no margin.
    BARE_DEBT = (; RULES..., wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
                  partial_unemployment_fee = false, government_employment_share = 0.0, account_fee_person = 0.0, account_fee_enterprise = 0.0)
    BARE_SUMSY = (; BARE_DEBT..., monetary_system = :sumsy, dividend_tax_rate = 0.0, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02,
                   account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
    GOV_DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.10)
    GOV_DEBT = (; GOV_DEBT..., profit_tax_rate = 0.10)                                  # 22 September: the debt government also taxes profits (10 % a year; materials fully, wages half deductible)
    GOV_SUMSY = (; demurrage_tax_rate = 0.01, government_employment_share = 0.10)       # public jobs funded by a 1 % demurrage tax; the GI is the benefit
    DEP = (; deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)

    # ---------------------------------------------------------------------------------------------------------------------
    # ladder2.jl (20 September 2026): the report's ladder rebuilt so that it ends at the best-surviving, least-indebted debt
    # village found this week, with SuMSy as the mirror at every rung. Rungs 0–8 are the 15 September ladder; rung 9 is the
    # co-op side rung; rungs 10–12 add, cumulatively on rung 8, the price rules, the government reserve and the fiscal policy.
    #   julia --project=. -O1 scripts/ladder2.jl <nseeds> <rounds> all <N> [rung prefix]
    # Resumable: each run is appended to results/ladder2_<N>_rounds.csv; finished (rung, system, seed) triples are skipped.
    V8_DEBT  = (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 4, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
    V8_SUMSY = (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 4, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
    CHARGE   = (; enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.02, reserve_tax_exempts_standard_reserve = true)
    GREEDY_Q = (; greed = true, greed_share = 0.25)                                                                     # the plausible greed: the richest quarter
    GREEDY_A = (; greed = true, greed_share = 1.0, greed_hoarding = 0.5)                                                # the extreme: everyone, half capital half consumption
    # 21 September: the 5 % triggers on unmet and unsold demand are base rules from rung 0 (the one-miss trigger was a defect, not a
    # rung, and is gone from the ladder). Rung 10 adds what is genuinely an addition: the cost floor and a buyer who pays up to double for
    # scarce bread. The price rules are behaviour, not policy; every rung and stress test from 10 on runs under the full set.
    EQ       = (; start_at_saturation = :equilibrium, initial_price_multiplier = 1.35)   # every villager at cushion + GI/(fee + tax); prices to match
    PRICES   = (; ask_floor = :cost, bread_bid_base_multiplier = 2.0)
    RESERVE  = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0)                                # rung 11: a public reserve, the surplus returned as a tax cut
    FISCAL   = (; tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0,
                 consumption_tax_rate = 0.06, tax_levers = (income = -3.0, consumption = 0.0, wealth = 0.0))            # rung 12: the policy that keeps the debt village alive: wages untaxed, a VAT, the deficit it leaves
    rungs = [
        ("0 bare bones",                    (;), (;)),
        ("1 + planning margin",             (; planning_margin = 0.1), (; planning_margin = 0.1)),
        ("2 + government",                  (; planning_margin = 0.1, GOV_DEBT...), (; planning_margin = 0.1, GOV_SUMSY...)),
        ("3 + interest on deposits",        (; planning_margin = 0.1, GOV_DEBT..., DEP...), (; planning_margin = 0.1, GOV_SUMSY...)),
        ("4 + theatres",                    (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, number_of_theatres = 2), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2)),
        ("5 + government bonds",            (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, number_of_theatres = 2, government_bonds = true), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2)),
        # 21 September: the 15 September rung charged 10 % a round on all enterprise cash (`enterprise_reserve_tax_rate` default); at ten seeds every debt
        # village lost its last bakery by round 31–51. The charge now mirrors the demurrage: 2 % a round on cash above the working reserve.
        ("6 + charge on balances",          (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, number_of_theatres = 2, government_bonds = true, CHARGE...), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 2, CHARGE...)),
        ("7 + two more theatres",           (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 4), (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 4)),
        ("8 + shareholders & share market", V8_DEBT, V8_SUMSY),
        # The co-op side rung changes ownership only: two of the four farms, bakeries and theatres become cooperatives.
        ("9 co-ops (side rung)",            (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed)),
        ("10 + responsive prices",          (; V8_DEBT..., PRICES...), (; V8_SUMSY..., PRICES...)),
        ("11 + government reserve",         (; V8_DEBT..., PRICES..., RESERVE...), (; V8_SUMSY..., PRICES..., RESERVE...)),
        ("12 + fiscal policy and VAT",      (; V8_DEBT..., PRICES..., RESERVE..., FISCAL...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL...)),
        # Stress tests (21 September): greed on the best cases — rung 11 (best surviving) and rung 12 (least indebted), both systems
        ("S1 rung 11 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_Q...)),
        ("S2 rung 12 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...)),
        ("S3 rung 11 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A...)),
        ("S4 rung 12 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...)),
        # The best SuMSy village (21 September): SuMSy has no debt to minimise, so its endpoint is chosen on its own measures —
        # no hunger and the most evenly spread money — under the realistic price rules (they are behaviour, not policy): the
        # co-op village of side rung 9 with rung 10's prices and rung 11's public reserve. Run on both sides for the mirror.
        ("B best SuMSy village: co-ops + prices + reserve", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE...)),
        ("SB1 best SuMSy + greedy quarter", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_Q...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_Q...)),
        ("SB2 best SuMSy + everyone greedy", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_A...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_A...)),
        # Full money stock (23 September): SuMSy villages started at their equilibrium money stock, set against the same steps
        # started with everyone at the cushion — the startup public debt of a filling-up village should disappear. SuMSy side only.
        ("E2 + government, full money stock", (;), (; planning_margin = 0.1, GOV_SUMSY..., EQ...)),
        ("E8 + shareholders & share market, full money stock", (;), (; V8_SUMSY..., EQ...)),
        ("E11 + government reserve, full money stock", (;), (; V8_SUMSY..., PRICES..., RESERVE..., EQ...)),
        ("EB best SuMSy village, full money stock", (;), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., EQ...)),
        # The 2×2 (review 2, §4.4): the monetary system crossed with the fiscal package, on the rung-11 village. X1 = SuMSy money
        # with the debt village's taxes and benefit; X2 = debt money with the SuMSy village's surcharge and no benefit. Together
        # with rungs 11 debt and 11 SuMSy they separate what the money does from what the fiscal package does. Only the named
        # side of each X rung is run.
        ("X1 SuMSy money, debt fiscal package (comparison)", (;), (; V8_SUMSY..., PRICES..., RESERVE..., wage_tax_rate = 0.15, capital_tax_rate = 0.15, dividend_tax_rate = 0.30, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, demurrage_tax_rate = 0.0)),
        ("X2 debt money, SuMSy fiscal package (comparison)", (; V8_DEBT..., PRICES..., RESERVE..., wage_tax_rate = 0.0, capital_tax_rate = 0.0, dividend_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0), (;)),
    ]
    # SuMSy never taxes income: its public money comes from the demurrage tax. Any SuMSy rung with a wage or capital tax is a
    # configuration error unless it is an explicit comparison (name it "(comparison)").
    for (name, kd, ks) in rungs
        occursin("comparison", name) && continue
        ks_full = (; BARE_SUMSY..., ks...)
        (ks_full.wage_tax_rate == 0 && ks_full.capital_tax_rate == 0 && ks_full.dividend_tax_rate == 0) || error("rung '$name': SuMSy must not tax income (wage_tax_rate = $(ks_full.wage_tax_rate), capital_tax_rate = $(ks_full.capital_tax_rate))")
    end

    return (; BARE_DEBT, BARE_SUMSY, rungs)
end
