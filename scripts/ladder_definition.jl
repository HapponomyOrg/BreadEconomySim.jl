using BreadEconomySim, OrderedCollections

# The ladder as a function of the village size, the run length and the settlement system (22 September), so that one
# process can build several ladders (scripts/run_all.jl). ladder2_rungs.jl calls it with the command-line values.
function ladder_definition(N::Int, rounds::Int, SETTLEMENT::Symbol; fiscal::Symbol = :own, surplus_rule::Symbol = :debt_levy_taxcut)
    # 20 Oct (evening): the base reproduces the 17 October run exactly (checked: step 8, debt, seed 1, identical in every month) —
    # this week's realistic labour market (contracts at 0.8, own-market planning, four market rounds, at least two firms, failing
    # firms with uncovered debt offered for sale) showed effects not yet understood in the 2026-10-20.0 run, so it is a cell (RB8,
    # RB11) until they are traced. The talk and the report stand on this base with the new measures (bonds, three Ginis).
    # 20 Oct: NOTHING may follow a comment on the RULES lines — a comment runs to the end of the line, and four comments
    # inserted mid-line on 18 and 19 October silently dropped eighteen rules (the settlement, the food emergency, founding
    # equity, the owner guarantee, greedy pricing, plan_greedy_on_purchases, notice, the minimum labour offer, …) and the
    # 19 October additions (own-market planning, market rounds) from every run of 2026-10-18.0 to 2026-10-19.3. A test now
    # checks that the base holds every rule. The week's additions: contracts at 0.8 with notice and loyalty (18–19 Oct, Stef),
    # at least two firms of each kind (19 Oct), own-market planning with the village plan as the emergency rule, and up to
    # four market rounds a month (19 Oct).
    RULES = (; ask_floor = :cost, collection_floor_in_breads = 2.0, bank_rate_cost_from_going_wage = true, bank_loans_per_labour_unit = 12, greedy_ask_on_paid_price = true,   # 23 Oct: the banks' rate on the going wage, not on the surplus-absorbing bid (it sat at the cap)   # 22 Oct (Stef): debt collection may not take a villager below a meal (two loaves) — at one loaf it caused most of the debt village's deaths (steps 8 and 11)
               bread_bid_base_multiplier = 1.2, ticket_max_in_breads = 2.0, employer_wage_margin = 0.20, number_of_persons = N, number_of_landowners = N ÷ 4, land_per_person = 1.5, initial_production_target = 10 * N ÷ 128, shares_per_person = 10, shareholder_count = 4, number_of_farms = 4, number_of_bakeries = 4, shows_per_round = 1, theatre_seat_margin = 0.25, unmet_demand_share = 0.05, unsold_share = 0.05, wage_threshold = true, wage_cut_maximum = 0.005, wage_floor_months = 1, joint_labour_market = true, contracts = false, contract_share = 0.8, refound_minimum = 1, uncovered_debt_sale = false, employer_loyalty = true, notice_months = 3, minimum_labour_offer = 0.5, volunteer_share = 1.0, spoilage_acceptance = 0.5, greedy_pricing = true, distress_pricing = true, distress_cost_cutting = true, plan_greedy_on_purchases = true, plan_within_capacity = true, own_market_planning = false, firms_plan_on_sales = true, market_rounds = 1, food_emergency_share = 0.9, employer_loss_tolerance = 0.10, owner_guarantee = true, interest_from_equity = true, bank_capital_ratio = 0.08, founding_equity = true, founders = :distinct, settlement = SETTLEMENT,   # 23 Sept: founders capitalise their firms
           # 22 September: :invoicing = the settlement design (cash at the counter, wages at month end, invoices between firms, clearing among banks)
             initial_interest_rate = 0.005, maximum_interest_rate = 0.015,   # a month: 6 % a year to start, at most about 20 %; the rate itself covers the banks' costs (one staff unit per bank: staff scaled with customers bankrupted the banks at 512, 22 Sept)
              demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true,
              random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = false, labour_for_bread = true, credit_for_bread = true, spoilage_aware_stocking = true,
              distress_land_sales = true, maximum_capacity = 4.0,
              wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation,
              gluttony_probability = 0.1, plan_for_gluttony = true, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false,
              land_pricing = :market, instalment_purchases = true, stop_without_producers = false)   # 24 Sept: land prices discovered by the money logic, seller credit on both sides, villages run on
    # Bare bones: no government activity, no benefit, no interest on deposits, no theatre, no margin.
    BARE_DEBT = (; RULES..., wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0,
                  partial_unemployment_fee = false, government_employment_share = 0.0, account_fee_person = 0.0, account_fee_enterprise = 0.0)
    BARE_SUMSY = (; BARE_DEBT..., monetary_system = :sumsy, dividend_tax_rate = 0.0, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02,
                   account_fee_person = 0.5, account_fee_enterprise = 1.5)   # 24 Sept: the SuMSy-only land settings (price multiple 50, instalments) are gone — both villages share one land market
    GOV_DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.10)
    GOV_DEBT = (; GOV_DEBT..., profit_tax_rate = 0.10)                                  # 22 September: the debt government also taxes profits (10 % a year; materials fully, wages half deductible)
    # 4 October (Stef): a benefit under SuMSy too — one loaf, half the debt village's, since the guaranteed income covers the other
    # half; paid from the parking tax, which the government may raise if short (PARKPOLICY from step 10; see the check runs).
    GOV_SUMSY = (; demurrage_tax_rate = 0.015, government_employment_share = 0.10, unemployment_fee_in_breads = 1.0, minimum_fee_in_breads = 1.0)   # 1.5 %: at 1 % the benefit left 35k of debt at year 10 (single run)
    DEP = (; deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)

    # ---------------------------------------------------------------------------------------------------------------------
    # ladder2.jl (20 September 2026): the report's ladder rebuilt so that it ends at the best-surviving, least-indebted debt
    # village found this week, with SuMSy as the mirror at every rung. Rungs 0–8 are the 15 September ladder; rung 9 is the
    # co-op side rung; rungs 10–12 add, cumulatively on rung 8, the price rules, the government reserve and the fiscal policy.
    #   julia --project=. -O1 scripts/ladder2.jl <nseeds> <rounds> all <N> [rung prefix]
    # Resumable: each run is appended to results/ladder2_<N>_rounds.csv; finished (rung, system, seed) triples are skipped.
    V8_DEBT  = (; planning_margin = 0.1, GOV_DEBT..., DEP..., entertainment = true, government_bonds = true, number_of_theatres = 4, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
    V8_SUMSY = (; planning_margin = 0.1, GOV_SUMSY..., entertainment = true, number_of_theatres = 4, ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002)
    # 4 Oct (Stef): the land levy paid out to everyone — Gesell's rule — is the SuMSy village's standard from step 8, where land is owned and traded
    V8_SUMSY = (; V8_SUMSY..., land_levy = true, government_reserve_in_rounds = 3, surplus_tax_reduction_share = 0.0, surplus_redistribution_share = 1.0)
    CHARGE   = (; enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.02, reserve_tax_exempts_standard_reserve = true)
    GREEDY_Q = (; greed = true, greed_share = 0.25, greed_month = 12)   # 15 Oct: the richest quarter chosen once a trend shows                                                                     # the plausible greed: the richest quarter
    GREEDY_A = (; greed = true, greed_share = 1.0, greed_hoarding = 0.5)                                                # the extreme: everyone, half capital half consumption
    # 21 September: the 5 % triggers on unmet and unsold demand are base rules from rung 0 (the one-miss trigger was a defect, not a
    # rung, and is gone from the ladder). Rung 10 adds what is genuinely an addition: the cost floor and a buyer who pays up to double for
    # scarce bread. The price rules are behaviour, not policy; every rung and stress test from 10 on runs under the full set.
    EQ       = (; start_at_saturation = :equilibrium, initial_price_multiplier = 1.0)   # 25 Sept: base prices — the old 1.35 (a 64-person, old-rule estimate) sat above the equilibrium and the cost floor kept it there (E11: 43 deaths)
    DIVIDEND = (; surplus_tax_reduction_share = 0.0, surplus_redistribution_share = 1.0)   # the surplus paid out per head instead of cutting taxes
    PARKPOLICY = (; tax_policy = :scale, tax_response_coverage = 1.0, tax_response_step = 0.02, tax_scale_maximum = 10.0)   # SuMSy: the parking tax covers the public payroll
    ENTRY    = (; market_entry = true, entry_coop_share = 0.0)   # 25 Sept: firms enter on unmet demand or high margins
    level(fee) = 30 + 5 / (fee + 0.01)                              # a villager's settled money: cushion + guaranteed income ÷ (fee + parking tax)
    REALISTIC = (; contracts = true, contract_share = 0.8, refound_minimum = 2, uncovered_debt_sale = true, own_market_planning = true, firms_plan_on_sales = false, market_rounds = 1)   # 20 Oct (rounds off: they ratchet prices down)
    DEMTAX15 = (; wage_tax_rate = 0.0, capital_tax_rate = 0.0, dividend_tax_rate = 0.0, demurrage_tax_rate = 0.015, demurrage_free_buffer = 30.0)   # 14 Oct: a demurrage tax instead of income tax, on debt money
    PRODUCTIVE = (; breads_per_grain = 4, customers_per_labour_unit = 2.0,   # 23 Oct (Stef): at least two customers per unit of labour (was 1.0 — one unit per customer); the base has 2.5 initial_prices = OrderedDict(:bread => 3.0, :grain => 5.2, :rent => 0.75, :wage => 3.92, :ticket => 5.0),
                  shows_per_round = 2, standard_of_living_tickets = 2, refound_minimum = 4)   # 15 Oct: prices free (Stef: the productive village is for full employment; fixed prices are the test, V8-P)
    PRICES   = (;)   # 25 Sept: the realistic price rules are base rules from step 0 (see RULES); the old step 10 is gone
    RESERVE  = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0)                                # rung 11: a public reserve, the surplus returned as a tax cut
    FISCAL   = (; tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0,
                 consumption_tax_rate = 0.06, tax_levers = (income = -3.0, consumption = 0.0, wealth = 0.0))            # rung 12: the policy that keeps the debt village alive: wages untaxed, a VAT, the deficit it leaves
    rungs = [
        # 25 Sept: no government at steps 0 and 1 — so nobody stands behind the banks either (a bank that loses money carries
        # negative net worth); the bailout rule starts with the government at step 2
        ("0 bare bones",                    (; bank_bailout = false), (; bank_bailout = false)),
        ("1 + planning margin",             (; planning_margin = 0.1, bank_bailout = false), (; planning_margin = 0.1, bank_bailout = false)),
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
        ("10 + government reserve",         (; V8_DEBT..., PRICES..., RESERVE...), (; V8_SUMSY..., PRICES..., RESERVE...)),
        ("11 + fiscal policy and VAT",      (; V8_DEBT..., PRICES..., RESERVE..., FISCAL...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL...)),
        # Stress tests (21 September): greed on the best cases — rung 11 (best surviving) and rung 12 (least indebted), both systems
        ("S1 step 10 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_Q...)),
        ("S2 step 11 + greedy quarter",     (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_Q...)),
        ("S3 step 10 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A...)),
        ("S4 step 11 + everyone greedy",    (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., GREEDY_A...)),
        # The best SuMSy village (21 September): SuMSy has no debt to minimise, so its endpoint is chosen on its own measures —
        # no hunger and the most evenly spread money — under the realistic price rules (they are behaviour, not policy): the
        # co-op village of side rung 9 with rung 10's prices and rung 11's public reserve. Run on both sides for the mirror.
        ("B best SuMSy village: co-ops + reserve", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE...)),
        ("BG best village, with gold", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., gold_grams_per_villager = 100.0), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., gold_grams_per_villager = 100.0)),   # 23 Oct (the talk chat): rung B with the gold holders of R8, for the inequality slide
        ("SB1 best SuMSy + greedy quarter", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_Q...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_Q...)),
        ("SB2 best SuMSy + everyone greedy", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_A...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., GREEDY_A...)),
        # Full money stock (23 September): SuMSy villages started at their equilibrium money stock, set against the same steps
        # started with everyone at the cushion — the startup public debt of a filling-up village should disappear. SuMSy side only.
        ("E2 + government, full money stock", (;), (; planning_margin = 0.1, GOV_SUMSY..., EQ...)),
        ("E8 + shareholders & share market, full money stock", (;), (; V8_SUMSY..., EQ...)),
        ("E10 + government reserve, full money stock", (;), (; V8_SUMSY..., PRICES..., RESERVE..., EQ...)),
        ("EB best SuMSy village, full money stock", (;), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, PRICES..., RESERVE..., EQ...)),
        # Land levy variants (24 September, Gesell's Freiland): the key SuMSy steps with a levy on land equal to the cost of holding money
        # plus a margin, so that land is no better a store of value than money. Without it, under SuMSy land beats money at any price.
        ("L2 + government, land levy", (;), (; planning_margin = 0.1, GOV_SUMSY..., RESERVE..., land_levy = true)),   # the reserve rule scales the levy down when revenue exceeds need (24 Sept)
        # Land dividend (24 September): the levy stays at the rate that neutralises land as a store of value, and what the government does
        # not need is paid out equally to every villager instead of cutting the levy (Gesell's use of land rent). SuMSy side only.
        # Public employment (24 September): how large can the government's workforce be? Steps 8 and 11, both villages, the share of the
        # village's labour the government hires (as employer of last resort, from labour the market leaves idle) swept from 20 to 50 %.
        ("G8-20 step 8, public employment 20 %", (; V8_DEBT..., government_employment_share = 0.2), (; V8_SUMSY..., government_employment_share = 0.2)),
        ("G8-30 step 8, public employment 30 %", (; V8_DEBT..., government_employment_share = 0.3), (; V8_SUMSY..., government_employment_share = 0.3)),
        ("G8-40 step 8, public employment 40 %", (; V8_DEBT..., government_employment_share = 0.4), (; V8_SUMSY..., government_employment_share = 0.4)),
        ("G8-50 step 8, public employment 50 %", (; V8_DEBT..., government_employment_share = 0.5), (; V8_SUMSY..., government_employment_share = 0.5)),
        ("G10-20 step 10, public employment 20 %", (; V8_DEBT..., PRICES..., RESERVE..., government_employment_share = 0.2), (; V8_SUMSY..., PRICES..., RESERVE..., government_employment_share = 0.2)),
        ("G10-30 step 10, public employment 30 %", (; V8_DEBT..., PRICES..., RESERVE..., government_employment_share = 0.3), (; V8_SUMSY..., PRICES..., RESERVE..., government_employment_share = 0.3)),
        ("G10-40 step 10, public employment 40 %", (; V8_DEBT..., PRICES..., RESERVE..., government_employment_share = 0.4), (; V8_SUMSY..., PRICES..., RESERVE..., government_employment_share = 0.4)),
        ("G10-50 step 10, public employment 50 %", (; V8_DEBT..., PRICES..., RESERVE..., government_employment_share = 0.5), (; V8_SUMSY..., PRICES..., RESERVE..., government_employment_share = 0.5)),
        # The 2×2 (review 2, §4.4): the monetary system crossed with the fiscal package, on the rung-11 village. X1 = SuMSy money
        # with the debt village's taxes and benefit; X2 = debt money with the SuMSy village's surcharge and no benefit. Together
        # with rungs 11 debt and 11 SuMSy they separate what the money does from what the fiscal package does. Only the named
        # side of each X rung is run.
        # Market entry twins (25 September, design_market_entry_2026-09-25.md): the key steps with entry on and no cooperative entrants,
        # set against the same steps without it (the ladder keeps entry off, one institution per step).
        ("N8 step 8, market entry", (; V8_DEBT..., ENTRY...), (; V8_SUMSY..., ENTRY...)),
        ("N10 step 10, market entry", (; V8_DEBT..., RESERVE..., ENTRY...), (; V8_SUMSY..., RESERVE..., ENTRY...)),
        ("NB co-op village, market entry", (; V8_DEBT..., cooperative_theatres = 2, ownership = :mixed, RESERVE..., ENTRY...), (; V8_SUMSY..., cooperative_theatres = 2, ownership = :mixed, RESERVE..., ENTRY...)),
        # Fixed prices (26 September, Stef's question): every transaction at the starting price vector, only quantities move — the
        # reference case against which the price choices are measured. Both villages.
        ("P2 step 2, fixed prices", (; planning_margin = 0.1, GOV_DEBT..., fixed_prices = true), (; planning_margin = 0.1, GOV_SUMSY..., fixed_prices = true)),
        ("P8 step 8, fixed prices", (; V8_DEBT..., fixed_prices = true), (; V8_SUMSY..., fixed_prices = true)),
        ("P10 step 10, fixed prices", (; V8_DEBT..., RESERVE..., fixed_prices = true), (; V8_SUMSY..., RESERVE..., fixed_prices = true)),
        # Full employment at fixed prices (26 September, for policy makers): 40 % public jobs bring unemployment to a few percent;
        # U8 keeps taxes as they are (the deficit is then visible as debt), UP8 lets each government raise its own taxes until the
        # budget balances (the debt village its income and capital taxes, the SuMSy village its parking tax). Both villages.
        # 15 Oct (Stef): as V8 and V8-P — free prices are the cell, fixed prices the test
        ("U8 step 8, 40 % public jobs", (; V8_DEBT..., government_employment_share = 0.4), (; V8_SUMSY..., government_employment_share = 0.4)),
        ("U8-P step 8, 40 % public jobs, fixed prices", (; V8_DEBT..., fixed_prices = true, government_employment_share = 0.4), (; V8_SUMSY..., fixed_prices = true, government_employment_share = 0.4)),
        ("UP8 step 8, 40 % public jobs, taxes balance the budget", (; V8_DEBT..., RESERVE..., PARKPOLICY..., government_employment_share = 0.4), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., government_employment_share = 0.4)),
        ("UP8-P step 8, 40 % public jobs, taxes balance the budget, fixed prices", (; V8_DEBT..., RESERVE..., PARKPOLICY..., fixed_prices = true, government_employment_share = 0.4), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., fixed_prices = true, government_employment_share = 0.4)),
        # The willingness to overpay (27 September): how much a hungry buyer will pay over last month's price sets the pace of
        # inflation in the debt village (1.1×: stable, 1.3×: ~6 % a year, 2×: ~15 %); the public debt rises in every case.
        # 1.2× is the base rule (Stef, 27 September: realistic numbers), 2× the "panic buying" stress variant. Debt side only.
        ("W2-11 step 2, buyers overpay up to 1.1x", (; planning_margin = 0.1, GOV_DEBT..., bread_bid_base_multiplier = 1.1), (;)),
        ("W2-13 step 2, buyers overpay up to 1.3x", (; planning_margin = 0.1, GOV_DEBT..., bread_bid_base_multiplier = 1.3), (;)),
        ("W2-20 step 2, buyers overpay up to 2x (panic buying)", (; planning_margin = 0.1, GOV_DEBT..., bread_bid_base_multiplier = 2.0), (;)),
        ("W8-20 step 8, buyers overpay up to 2x (panic buying)", (; V8_DEBT..., bread_bid_base_multiplier = 2.0), (;)),
        ("W8-13 step 8, buyers overpay up to 1.3x", (; V8_DEBT..., bread_bid_base_multiplier = 1.3), (;)),
        # The productive village (27 September, for policy makers): cheap bread (four loaves a grain, bread at 3), theatres that need
        # a worker per customer at a ticket price that covers the wage, households aiming for two tickets a month, failed theatres
        # restarted while fewer than four are open, prices fixed, 10 % public jobs. Employment then rises to what the villagers'
        # wants allow (~85 %); the question is what the public debt does. Both villages.
        ("V8 productive village, standard of living", (; V8_DEBT..., PRODUCTIVE...), (; V8_SUMSY..., PRODUCTIVE...)),
        ("V8-P productive village, fixed prices", (; V8_DEBT..., PRODUCTIVE..., fixed_prices = true), (; V8_SUMSY..., PRODUCTIVE..., fixed_prices = true)),
        # Austerity (30 September, Stef): the benefit tapers from two loaves to one over six months from month 60 and stays there.
        # Debt side only (SuMSy has no benefit to cut).
        ("A8 step 8, austerity from month 60", (; V8_DEBT..., austerity_start = 60), (;)),
        ("A10 step 10, austerity from month 60", (; V8_DEBT..., RESERVE..., austerity_start = 60), (;)),
        # The 1 % hoarders (30 September, Stef): one villager in a hundred greedy, hoarding half the surplus. Both villages.
        ("H8 step 8, the richest 1 % greedy (they spend or invest every surplus)", (; V8_DEBT..., greed = true, greed_share = 0.01, greed_hoarding = 0.5, greed_month = 12), (; V8_SUMSY..., greed = true, greed_month = 12, greed_share = 0.01, greed_hoarding = 0.5)),
        # A public investment (3 October, Stef — public transport): five years of building with 5 % of the village's capacity and
        # nothing coming back, then fares of half a loaf a ride, one ride a month per villager who can afford it. Both villages.
        ("T8 step 8, public transport project", (; V8_DEBT..., public_project_start = 1), (; V8_SUMSY..., public_project_start = 1)),
        ("T10 step 10, public transport project", (; V8_DEBT..., RESERVE..., public_project_start = 1), (; V8_SUMSY..., RESERVE..., public_project_start = 1)),
        # The labour-market sweep (3 October): how long a worker holds a wage after losing a job, and whether employers keep their
        # workers before taking strangers — the two channels through which a slack market lowers wages. Both villages, step 8.
        ("Y8-floor3 step 8, wage floor outlasts a job by 3 months", (; V8_DEBT..., wage_floor_months = 3), (; V8_SUMSY..., wage_floor_months = 3)),
        ("Y8-noloyalty step 8, employers take the cheapest hands, not their own", (; V8_DEBT..., employer_loyalty = false), (; V8_SUMSY..., employer_loyalty = false)),   # 13 Oct (review 7): the ladder has loyalty on; this is its mirror
        ("Y8-nonotice step 8, no notice period", (; V8_DEBT..., notice_months = 0), (; V8_SUMSY..., notice_months = 0)),
        # The SuMSy village without the land levy (4 October): the Gesell runaway, kept as the comparison. SuMSy only.
        ("Z8 step 8, SuMSy without the land levy", (;), (; V8_SUMSY..., land_levy = false, surplus_redistribution_share = 0.0)),
        # Volunteers in the theatres (4 October, Stef): paid hiring first, villagers' unhired labour for the rest. Both villages.
        ("C8 step 8, volunteers staff the theatres", (; V8_DEBT..., volunteers_in_theatres = true), (; V8_SUMSY..., volunteers_in_theatres = true)),
        # Not working, for reasons of their own (5 October, Stef): 5 % of villagers take paid work only to eat, a third of them only
        # once hungry; none gives volunteer hours. Both villages.
        ("Q8 step 8, 5 % not working for reasons of their own", (; V8_DEBT..., nonworking_share = 0.05), (; V8_SUMSY..., nonworking_share = 0.05)),
        # Gold (5 October, Stef): 100 grams a villager, held at the start by the richest tenth, a pure store of value on a market. Both villages.
        # Gold is reported beside wealth, not in it: it yields nothing and feeds no one until someone pays money for it.
        ("R8 step 8, gold", (; V8_DEBT..., gold_grams_per_villager = 100.0), (; V8_SUMSY..., gold_grams_per_villager = 100.0)),
        ("RZ8 step 8, gold, SuMSy without the land levy", (;), (; V8_SUMSY..., land_levy = false, surplus_redistribution_share = 0.0, gold_grams_per_villager = 100.0)),
        # A premium loaf (11 October, Stef): value that grows without volume growing — the month's bread at five times the price for
        # whoever can pay, with half a unit of extra labour per loaf. On step 8 and on the productive village. Both villages.
        ("K8 step 8, a premium loaf", (; V8_DEBT..., premium_markup = 5.0), (; V8_SUMSY..., premium_markup = 5.0)),
        ("KV8 productive village, a premium loaf", (; V8_DEBT..., PRODUCTIVE..., premium_markup = 5.0), (; V8_SUMSY..., PRODUCTIVE..., premium_markup = 5.0)),
        # The sharing margin (12 October): each villager offers at least their share of last month's labour wanted plus this
        # margin. At step 0, without a benefit, it decides who is left out — 0 shares the work exactly (tight market, prices up),
        # 10 % holds prices and leaves a residue of outsiders. Both villages.
        ("M0-0 bare bones, sharing margin 0", (; bank_bailout = false, labour_for_bread_margin = 0.0), (; bank_bailout = false, labour_for_bread_margin = 0.0)),
        ("M0-5 bare bones, sharing margin 5 %", (; bank_bailout = false, labour_for_bread_margin = 0.05), (; bank_bailout = false, labour_for_bread_margin = 0.05)),
        ("M0-20 bare bones, sharing margin 20 %", (; bank_bailout = false, labour_for_bread_margin = 0.2), (; bank_bailout = false, labour_for_bread_margin = 0.2)),
        ("M8-0 step 8, sharing margin 0", (; V8_DEBT..., labour_for_bread_margin = 0.0), (; V8_SUMSY..., labour_for_bread_margin = 0.0)),
        # Spoilage acceptance (13 October, Stef): how much bread a greedy villager will buy beyond what they can eat before it rots.
        # On the greedy village (S3: everyone greedy, step 10). Both villages. The ladder's greedy steps use 0.5.
        ("S3-SP10 everyone greedy, spoilage acceptance 10 %", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 0.1), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 0.1)),
        ("S3-SP100 everyone greedy, spoilage acceptance 100 %", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 1.0), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 1.0)),
        ("S3-SP300 everyone greedy, spoilage acceptance 300 %", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 3.0), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = 3.0)),
        ("S3-SPold everyone greedy, the old ten-loaf cap", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = NaN), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., spoilage_acceptance = NaN)),
        # The overpay dial on the greedy village (13 October): whether a bread price free to follow its inputs saves the bakeries.
        # The ladder's greedy steps sit at 1.2×. Both moneys.
        ("S3-W11 everyone greedy, overpay up to 1.1×", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 1.1), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 1.1)),
        ("S3-W13 everyone greedy, overpay up to 1.3×", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 1.3), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 1.3)),
        ("S3-W20 everyone greedy, overpay up to 2×", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 2.0), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., bread_bid_base_multiplier = 2.0)),
        # Greedy pricing and distress pricing (13 October) switched off, on the greedy village and on step 8: their own effect.
        ("S3-NGP everyone greedy, firms price by the step rule", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., greedy_pricing = false), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., greedy_pricing = false)),
        ("S3-NDP everyone greedy, no distress pricing", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., distress_pricing = false), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., distress_pricing = false)),
        ("NDP8 step 8, no distress pricing", (; V8_DEBT..., distress_pricing = false), (; V8_SUMSY..., distress_pricing = false)),
        # Cost cutting under distress (14 October) switched off: its own effect, on step 8 and on the productive village. Both moneys.
        ("NDC8 step 8, no cost cutting under distress", (; V8_DEBT..., distress_cost_cutting = false), (; V8_SUMSY..., distress_cost_cutting = false)),
        ("V8-NDC productive village, no cost cutting under distress", (; V8_DEBT..., PRODUCTIVE..., distress_cost_cutting = false), (; V8_SUMSY..., PRODUCTIVE..., distress_cost_cutting = false)),
        # A reader's question (14 October): does any village with a basic income and a land dividend keep its people alive, or is it
        # the money? SuMSy's fiscal arrangement on debt money, piece by piece. Debt side only.
        ("DGI8 debt money, basic income 5", (; V8_DEBT..., basic_income = 5.0), (;)),
        ("DD8 debt money, demurrage tax 1.5 % instead of income tax", (; V8_DEBT..., DEMTAX15...), (;)),
        ("DDL8 debt money, demurrage tax 1.5 %, land levy and dividend", (; V8_DEBT..., DEMTAX15..., land_levy = true, land_levy_dividend = true), (;)),
        ("DDGL8 debt money, SuMSy's arrangement: demurrage tax 1.5 %, levy and dividend, basic income, one-loaf benefit", (; V8_DEBT..., DEMTAX15..., land_levy = true, land_levy_dividend = true, basic_income = 5.0, unemployment_fee_in_breads = 1.0, minimum_fee_in_breads = 1.0), (;)),
        ("DDGL8-35 as DDGL8 at a demurrage tax of 3.5 %", (; V8_DEBT..., DEMTAX15..., demurrage_tax_rate = 0.035, land_levy = true, land_levy_dividend = true, basic_income = 5.0, unemployment_fee_in_breads = 1.0, minimum_fee_in_breads = 1.0), (;)),
        # Cash hoarders (15 October, Stef): the richest 1 % keep every surplus as money and spend nothing beyond their bread. Both moneys.
        ("HC8 step 8, 1 % cash hoarders (those holding the most money at month 12)", (; V8_DEBT..., cash_hoarder_share = 0.01, cash_hoarder_month = 12), (; V8_SUMSY..., cash_hoarder_share = 0.01, cash_hoarder_month = 12)),
        ("HC8-10 step 8, 10 % cash hoarders (those holding the most money at month 12)", (; V8_DEBT..., cash_hoarder_share = 0.10, cash_hoarder_month = 12), (; V8_SUMSY..., cash_hoarder_share = 0.10, cash_hoarder_month = 12)),
        # A volunteer-run community theatre (15 October, Stef): one of the four theatres hires nobody, volunteers staff it, seats at a
        # quarter of a loaf. Both moneys.
        ("CT8 step 8, a volunteer-run community theatre", (; V8_DEBT..., community_theatres = 1), (; V8_SUMSY..., community_theatres = 1)),
        # Gesell's objection to George (15 October): landowners pass the levy on to their tenants (the farms). SuMSy, where the levy
        # stands; and the debt-money twin with the levy (DDL8).
        ("LPT8 step 8, landowners pass the levy on to their tenants", (;), (; V8_SUMSY..., levy_pass_through = true)),
        ("DDL8-PT debt money, demurrage tax, levy and dividend, the levy passed on", (; V8_DEBT..., DEMTAX15..., land_levy = true, land_levy_dividend = true, levy_pass_through = true), (;)),
        # Labour contracts (17 October, Stef): the dial from temps to contracts — the share of its hands an employer may hold on
        # contract; a temp who has worked three months running gets one while there is room; contracted workers are off the market,
        # with three months' notice from the employer and one from the worker. Both moneys.
        ("J8-50 step 8, contracts for half the hands", (; V8_DEBT..., contracts = true, contract_share = 0.5), (; V8_SUMSY..., contracts = true, contract_share = 0.5)),
        # The contracts dial at its ends (19 October, Stef): the base holds 0.8 on contract; every hand on contract (J…-100) and none
        # (NJ…) beside it where the labour market matters — the first government step, step 8, step 11, the productive village and the
        # everyone-greedy village. Both moneys.
        ("NJ2 step 2, no contracts (temps only)", (; planning_margin = 0.1, GOV_DEBT..., contracts = false), (; planning_margin = 0.1, GOV_SUMSY..., contracts = false)),
        ("J2-100 step 2, every hand on contract", (; planning_margin = 0.1, GOV_DEBT..., contracts = true, contract_share = 1.0), (; planning_margin = 0.1, GOV_SUMSY..., contracts = true, contract_share = 1.0)),
        ("NJ8 step 8, no contracts (temps only)", (; V8_DEBT..., contracts = false), (; V8_SUMSY..., contracts = false)),
        ("J8-100 step 8, every hand on contract", (; V8_DEBT..., contracts = true, contract_share = 1.0), (; V8_SUMSY..., contracts = true, contract_share = 1.0)),
        ("NJ11 step 11, no contracts (temps only)", (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., contracts = false), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., contracts = false)),
        ("J11-100 step 11, every hand on contract", (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., contracts = true, contract_share = 1.0), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., contracts = true, contract_share = 1.0)),
        ("V8-NJ productive village, no contracts (temps only)", (; V8_DEBT..., PRODUCTIVE..., contracts = false), (; V8_SUMSY..., PRODUCTIVE..., contracts = false)),
        ("V8-J100 productive village, every hand on contract", (; V8_DEBT..., PRODUCTIVE..., contracts = true, contract_share = 1.0), (; V8_SUMSY..., PRODUCTIVE..., contracts = true, contract_share = 1.0)),
        ("S3-NJ step 10, everyone greedy, no contracts (temps only)", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., contracts = false), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., contracts = false)),
        ("S3-J100 step 10, everyone greedy, every hand on contract", (; V8_DEBT..., PRICES..., RESERVE..., GREEDY_A..., contracts = true, contract_share = 1.0), (; V8_SUMSY..., PRICES..., RESERVE..., GREEDY_A..., contracts = true, contract_share = 1.0)),
        # Experience (17 October, Stef): level 2 after 3 months running in a kind of enterprise, level 3 after 9; +10 % and +20 % output
        # per unit; a level lost for every 3 months not worked in that kind. Both moneys.
        ("XP8 step 8, experience", (; V8_DEBT..., experience = true), (; V8_SUMSY..., experience = true)),
        ("XPN8 step 8, experience, no contracts", (; V8_DEBT..., experience = true, contracts = false), (; V8_SUMSY..., experience = true, contracts = false)),
        # Public land (18 October, Stef — close to Gesell's Freiland): the government owns the land; farms pay a loaf a plot a month,
        # bakeries and theatres two loaves a month, every villager a quarter loaf a month for the ground they live on; the rents
        # follow the tax levers. No land market, no levy. Both moneys (the SuMSy side without its levy and dividend of step 8).
        ("PL8 step 8, public land: ground rents of 1 loaf a plot, 2 a firm, 1/4 a villager", (; V8_DEBT..., land_pricing = :multiple, public_land = true, public_land_farm_rent_in_breads = 1.0, public_land_firm_rent_in_breads = 2.0, public_land_dwelling_rent_in_breads = 0.25), (; V8_SUMSY..., land_pricing = :multiple, land_levy = false, public_land = true, public_land_farm_rent_in_breads = 1.0, public_land_firm_rent_in_breads = 2.0, public_land_dwelling_rent_in_breads = 0.25)),
        ("PL8-0 step 8, public land, no ground rent", (; V8_DEBT..., land_pricing = :multiple, public_land = true), (; V8_SUMSY..., land_pricing = :multiple, land_levy = false, public_land = true)),
        # 18 Oct (Stef): the dwelling rent and those on the benefit — exempted, or the rent added to the benefit. Debt side (under SuMSy the dividend covers it).
        ("PL8-X step 8, public land, those on the benefit exempt from the dwelling rent", (; V8_DEBT..., land_pricing = :multiple, public_land = true, public_land_farm_rent_in_breads = 1.0, public_land_firm_rent_in_breads = 2.0, public_land_dwelling_rent_in_breads = 0.25, public_land_dwelling_exempt_benefit = true), (;)),
        ("PL8-B step 8, public land, the dwelling rent added to the benefit", (; V8_DEBT..., land_pricing = :multiple, public_land = true, public_land_farm_rent_in_breads = 1.0, public_land_firm_rent_in_breads = 2.0, public_land_dwelling_rent_in_breads = 0.25, public_land_dwelling_in_benefit = true), (;)),
        # This week's realistic labour market as one cell (20 October): contracts at 0.8, own-market planning with the emergency rule,
        # four market rounds, at least two firms of each kind, failing firms with uncovered debt offered for sale. Both moneys.
        ("RB8 step 8, the realistic labour market of 18-20 October", (; V8_DEBT..., REALISTIC...), (; V8_SUMSY..., REALISTIC...)),
        ("RB11 step 11, the realistic labour market of 18-20 October", (; V8_DEBT..., PRICES..., RESERVE..., FISCAL..., REALISTIC...), (; V8_SUMSY..., PRICES..., RESERVE..., FISCAL..., REALISTIC...)),
        # The benefit fixed in money (26 September): the debt village's transfer as a fixed sum, like SuMSy's guaranteed income —
        # separates the money system from the indexation of the transfer. Debt side only.
        ("I2 step 2, benefit fixed in money", (; planning_margin = 0.1, GOV_DEBT..., benefit_indexed = false), (;)),
        ("I8 step 8, benefit fixed in money", (; V8_DEBT..., benefit_indexed = false), (;)),
        ("I10 step 10, benefit fixed in money", (; V8_DEBT..., RESERVE..., benefit_indexed = false), (;)),
        # A ceiling on public borrowing (26 September): the debt village with its public debt capped at a multiple of yearly output;
        # over it, public jobs and the benefit are scaled down. Debt side only.
        ("D2-100 step 2, public debt ceiling 1 x yearly output", (; planning_margin = 0.1, GOV_DEBT..., public_debt_limit = 1.0), (;)),
        ("D2-50 step 2, public debt ceiling 0.5 x yearly output", (; planning_margin = 0.1, GOV_DEBT..., public_debt_limit = 0.5), (;)),
        ("D8-100 step 8, public debt ceiling 1 x yearly output", (; V8_DEBT..., public_debt_limit = 1.0), (;)),
        ("D8-50 step 8, public debt ceiling 0.5 x yearly output", (; V8_DEBT..., public_debt_limit = 0.5), (;)),
        # A debt rule like the euro area's (15 October): the ceiling at 60 % of yearly output, the reference value of the fiscal rules —
        # on the debt village, and on its twin with a basic income, which a debt rule must cut once it binds.
        ("D8-60 step 8, public debt ceiling 0.6 x yearly output", (; V8_DEBT..., public_debt_limit = 0.6), (;)),
        ("EU8 debt money, basic income 5, public debt ceiling 0.6 x yearly output", (; V8_DEBT..., basic_income = 5.0, public_debt_limit = 0.6), (;)),
        # The income reversed (15 October): cut to half from month 60, in each money — the cost of undoing it.
        ("RV8 step 8, the income halved from month 60", (; V8_DEBT..., basic_income = 5.0, income_cut_start = 60), (; V8_SUMSY..., income_cut_start = 60)),
        ("D10-100 step 10, public debt ceiling 1 x yearly output", (; V8_DEBT..., RESERVE..., public_debt_limit = 1.0), (;)),
        ("D10-50 step 10, public debt ceiling 0.5 x yearly output", (; V8_DEBT..., RESERVE..., public_debt_limit = 0.5), (;)),
        # The parking fee as monetary policy (25 September): a higher fee lowers the money stock each villager settles at
        # (cushion + guaranteed income ÷ (fee + parking tax)); with starting prices scaled to that level, prices follow the money and
        # the guaranteed income buys more. Full money stock at step 8 (F8) and filling up at step 8 (FF8); F8-2 is the control
        # (normal fee, the same lower starting prices as F8-3). SuMSy side only.
        ("F8-2 step 8, full money stock, fee 2 %, prices x 0.79 (control)", (;), (; V8_SUMSY..., EQ..., demurrage_rate = 0.02, initial_price_multiplier = level(0.03) / level(0.02))),
        ("F8-3 step 8, full money stock, fee 3 %, matching prices", (;), (; V8_SUMSY..., EQ..., demurrage_rate = 0.03, initial_price_multiplier = level(0.03) / level(0.02))),
        ("F8-4 step 8, full money stock, fee 4 %, matching prices", (;), (; V8_SUMSY..., EQ..., demurrage_rate = 0.04, initial_price_multiplier = level(0.04) / level(0.02))),
        ("FF8-3 step 8, filling up, fee 3 %", (;), (; V8_SUMSY..., demurrage_rate = 0.03)),
        ("FF8-4 step 8, filling up, fee 4 %", (;), (; V8_SUMSY..., demurrage_rate = 0.04)),
        # The fair SuMSy test of a large public sector (25 September): the same shares with a policy that raises the parking tax
        # (and lowers it on a surplus) to close the whole gap, up to ten times its rate. SuMSy side only.
        ("GP10-20 step 10, public employment 20 %, parking tax policy", (;), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., government_employment_share = 0.2)),
        ("GP10-30 step 10, public employment 30 %, parking tax policy", (;), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., government_employment_share = 0.3)),
        ("GP10-40 step 10, public employment 40 %, parking tax policy", (;), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., government_employment_share = 0.4)),
        ("GP10-50 step 10, public employment 50 %, parking tax policy", (;), (; V8_SUMSY..., RESERVE..., PARKPOLICY..., government_employment_share = 0.5)),
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

    # 12 Oct: on the SuMSy side the land levy always comes with its dividend — the reserve block layered on later steps had set
    # "surplus → cut taxes" to 1 and overridden it, so the levy was cut, land froze, and steps 10/11/B read a land runaway.
    rungs = [(n, kd, (get(ks, :land_levy, false) ? (; ks..., surplus_tax_reduction_share = 0.0, surplus_redistribution_share = 1.0) : ks)) for (n, kd, ks) in rungs]
    fiscal == :own || (rungs = apply_fiscal_package(rungs, fiscal; surplus_rule))
    return (; BARE_DEBT, BARE_SUMSY, rungs, fiscal, surplus_rule)
end


# ======================================================================================================================
# The common fiscal packages (22 October 2026, docs/talk/same_fiscal_rules_instructions_2026-10-22.md): under `fiscal = :taxes`
# (package T) or `:parking` (package P) both villages get the same fiscal package at every rung, and differ in the money only
# (D1: how money is created and destroyed, the guaranteed income, the fee, the account fees, deposit interest and bonds — debt
# side only, D3/D4 —, the loan rates). Each rung keeps its institutions; its fiscal fields are overwritten on both sides.
# ======================================================================================================================
const FISCAL_FIELDS = (:surplus_rule, :levy_dividend_target_in_breads, :basic_income_target_in_breads, :wage_tax_rate, :capital_tax_rate, :dividend_tax_rate, :profit_tax_rate, :demurrage_tax_rate, :demurrage_free_buffer,
                       :unemployment_fee_in_breads, :minimum_fee_in_breads, :government_employment_share, :land_levy, :land_levy_dividend,
                       :government_reserve_in_rounds, :surplus_tax_reduction_share, :surplus_redistribution_share,
                       :enterprise_tax, :enterprise_reserve_tax_rate, :reserve_tax_exempts_standard_reserve)
const MONEY_FIELDS = (:monetary_system, :guaranteed_income, :demurrage_rate, :account_fee_person, :account_fee_enterprise,
                      :deposit_interest_rate, :deposit_interest_period, :loyalty_bonus_rate, :government_bonds, :peer_lending, :peer_loan_rate,
                      :bank_spread, :loan_rate_covers_deposit_interest,
                      :basic_income, :income_cut_start, :income_cut_share)   # the debt village's twin of the guaranteed income (DGI8, RV8) is a money field; basic_income_target_in_breads is in FISCAL_FIELDS and set on both sides (it acts only in debt money)
has_government(kw) = get(kw, :government_employment_share, 0.0) > 0 || get(kw, :unemployment_fee_in_breads, 0.0) > 0 || get(kw, :wage_tax_rate, 0.0) > 0 || get(kw, :demurrage_tax_rate, 0.0) > 0
has_levy(kw) = get(kw, :land_levy, false)
has_charge(kw) = get(kw, :enterprise_tax, :none) == :reserves

"""The fiscal package for a rung: `:taxes` (T) or `:parking` (P), for a rung with or without a government, with or without the
land levy, with or without the enterprise charge (D8a: under P the charge is off; under T it is on for the debt side only — the
model itself skips it for SuMSy producers, D8)."""
function fiscal_package(fiscal::Symbol, government::Bool, levy::Bool, charge::Bool, system::Symbol; surplus_rule::Symbol = :debt_levy_taxcut)
    base = (; dividend_tax_rate = 0.0, wage_tax_rate = 0.0, capital_tax_rate = 0.0, profit_tax_rate = 0.0, demurrage_tax_rate = 0.0,
              unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.0,
              land_levy = false, land_levy_dividend = false, government_reserve_in_rounds = 0, surplus_tax_reduction_share = 0.0, surplus_redistribution_share = 0.0,
              enterprise_tax = :none)
    government || return base                                                          # steps 0 and 1: no government, no taxes on either side
    gov = fiscal == :taxes ? (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, dividend_tax_rate = 0.30, profit_tax_rate = 0.10, demurrage_tax_rate = 0.0) :
          fiscal == :parking ? (; wage_tax_rate = 0.0, capital_tax_rate = 0.0, dividend_tax_rate = 0.0, profit_tax_rate = 0.0, demurrage_tax_rate = 0.015, demurrage_free_buffer = 30.0) :
          error("fiscal must be :own, :taxes or :parking, got $fiscal")
    # 23 Oct (the talk chat's handoff §1): the surplus rule as one setting. :per_head = the 2026-10-22.13 packages (from the
    # levy step: a 3-month reserve, the levy into the budget, the surplus paid out per head, taxes never lowered; no reserve
    # before). :debt_levy_taxcut = Stef's rule from the levy step (D3: steps 2–7 as they were): repay public debt first, the
    # month's levy paid out per head within the surplus, every tax but the levy lowered with what is left; the levy's scale is
    # the dividend's lever (levy_dividend_target_in_breads = 2: income + dividend = a meal).
    pkg = (; base..., gov..., unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.10, surplus_rule = surplus_rule)   # D2 default: 2 loaves on both sides
    if levy
        pkg = surplus_rule == :per_head ?
              (; pkg..., land_levy = true, land_levy_dividend = false, levy_dividend_target_in_breads = 0.0, government_reserve_in_rounds = 3, surplus_tax_reduction_share = 0.0, surplus_redistribution_share = 1.0) :
              (; pkg..., land_levy = true, land_levy_dividend = true, levy_dividend_target_in_breads = 2.0, government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0, surplus_redistribution_share = 0.0)
        # 23 Oct (Stef): under the parking package the debt village pays everyone a basic income that brings income + levy
        # dividend to a meal, funded by the parking tax scaled up as needed — the fair twin of the SuMSy village's income
        surplus_rule != :per_head && fiscal == :parking && (pkg = (; pkg..., basic_income_target_in_breads = 2.0))
    end
    charge && fiscal == :taxes && (pkg = (; pkg..., enterprise_tax = :reserves, enterprise_reserve_tax_rate = 0.02, reserve_tax_exempts_standard_reserve = true))   # D8a: under T the charge is set on both sides; the model exempts SuMSy producers (D8), SuMSy banks still pay it on retained interest — reported, not yet decided
    return pkg
end

function apply_fiscal_package(rungs, fiscal::Symbol; surplus_rule::Symbol = :debt_levy_taxcut)
    out = similar(rungs, 0)
    for (name, kd, ks) in rungs
        gov = has_government(kd) || has_government(ks); levy = has_levy(kd) || has_levy(ks); charge = has_charge(kd) || has_charge(ks)
        kd2 = isempty(kd) ? kd : (; kd..., fiscal_package(fiscal, gov, levy, charge, :debt; surplus_rule)...)
        ks2 = isempty(ks) ? ks : (; ks..., fiscal_package(fiscal, gov, levy, charge, :sumsy; surplus_rule)...)
        push!(out, (name, kd2, ks2))
    end
    return out
end
