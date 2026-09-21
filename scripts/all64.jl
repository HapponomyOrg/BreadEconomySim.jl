# Every experiment of Sections 8–10B at sixty-four villagers, a hundred rounds, three seeds.
using BreadEconomySim, DataFrames, CSV, Statistics
nseeds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 3; rounds = 100; N = 64
BASE = (; number_of_persons = N, number_of_landowners = 16, land_per_person = 1.5, initial_production_target = 10, shares_per_person = 10, shareholder_count = 4,
         demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true, ask_increase_only_on_unmet_demand = true, random_hiring_ties = true, no_labour_tolerance = true, offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true, maximum_capacity = 4.0,
         wage_reservation_net_of_tax = true, initial_endowment = :norm, startup_loan_term = 60, land_sales = :reservation, gluttony_probability = 0.1, plan_for_gluttony = true, planning_margin = 0.1, entertainment = true, number_of_theatres = 2, maximum_rounds = rounds, stop_when_half_dead = false, stop_when_stationary = false)
DEBT = (; wage_tax_rate = 0.15, capital_tax_rate = 0.15, unemployment_fee_in_breads = 2.0, minimum_fee_in_breads = 2.0, government_employment_share = 0.1, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02, account_fee_person = 0.0, account_fee_enterprise = 0.0, government_bonds = true)
SUMSY = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0, minimum_fee_in_breads = 0.0, government_employment_share = 0.1, demurrage_tax_rate = 0.01, guaranteed_income = 5.0, demurrage_free_buffer = 30.0, demurrage_rate = 0.02, account_fee_person = 0.5, account_fee_enterprise = 1.5, instalment_purchases = true, land_price_rent_multiple = 50.0)
MARKET = (; ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital)
GREEDY = (; MARKET..., greed = true, greed_share = 1.0)
experiments = Dict(
 "share_market" => [("cash only, no spread", (; MARKET..., required_yield_dispersion = 0.0)), ("cash only", MARKET), ("cash only, resale +0.5%", (; MARKET..., expected_price_growth = 0.005)),
                    ("deferred payment", (; MARKET..., deferred_payment = true)), ("deferred payment, resale +0.5%", (; MARKET..., deferred_payment = true, expected_price_growth = 0.005))],
 "coops" => (COOP = (; MARKET..., number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed);
             WORKFOOD = (; cooperative_form_farms = :worker, cooperative_form_bakeries = :worker);
             [("member co-ops (13 Sept rule)", COOP),
              ("member co-ops + co-op theatre", (; COOP..., cooperative_theatres = 1)),
              ("worker food chain", (; COOP..., WORKFOOD...)),
              ("worker food chain + worker theatre", (; COOP..., WORKFOOD..., cooperative_theatres = 1, cooperative_form_theatres = :worker)),
              ("worker food chain + consumer theatre", (; COOP..., WORKFOOD..., cooperative_theatres = 1, cooperative_form_theatres = :consumer)),
              ("consumer bakeries + consumer theatre", (; COOP..., cooperative_farms = 0, cooperative_form_bakeries = :consumer, cooperative_theatres = 1, cooperative_form_theatres = :consumer)),
              ("worker + consumer, no members-first", (; COOP..., WORKFOOD..., cooperative_theatres = 1, cooperative_form_theatres = :consumer, members_first_hiring = false)),
              ("worker + consumer, symmetric founding", (; COOP..., WORKFOOD..., cooperative_theatres = 1, cooperative_form_theatres = :consumer, cooperative_founding = :symmetric))]),
 "capacity" => (MIX = (; GREEDY..., greed_hoarding = 0.5);
                [("mixed greed, capacity 4", MIX),
                 ("mixed greed, capacity 5", (; MIX..., maximum_capacity = 5.0)),
                 ("mixed greed, capacity 6", (; MIX..., maximum_capacity = 6.0)),
                 ("mixed greed, land 2", (; MIX..., land_per_person = 2.0)),
                 ("mixed greed, land 2 + capacity 5", (; MIX..., land_per_person = 2.0, maximum_capacity = 5.0)),
                 ("mixed greed, bread ceiling 2.0", (; MIX..., bread_bid_base_multiplier = 2.0)),
                 ("mixed greed, bread ceiling 2.0 + capacity 5", (; MIX..., bread_bid_base_multiplier = 2.0, maximum_capacity = 5.0)),
                 ("no greed, capacity 5", (; MARKET..., maximum_capacity = 5.0))]),
 "shows" => (MIX = (; GREEDY..., greed_hoarding = 0.5);
             [("mixed greed, 1 show", (; MIX..., shows_per_round = 1)), ("mixed greed, 2 shows", (; MIX..., shows_per_round = 2)),
              ("mixed greed, 3 shows", (; MIX..., shows_per_round = 3)), ("mixed greed, 4 shows", (; MIX..., shows_per_round = 4)),
              ("mixed greed, unlimited", MIX),
              ("greedy rich 25 %, 1 show", (; MARKET..., greed = true, greed_share = 0.25, shows_per_round = 1)),
              ("no greed, 1 show", (; MARKET..., shows_per_round = 1))]),
 "floor" => (MIX = (; GREEDY..., greed_hoarding = 0.5); RESP = (; ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05);
             [("mixed greed, 1 show, cost floor", (; MIX..., shows_per_round = 1, ask_floor = :cost)),
              ("mixed greed, 1 show, responsive", (; MIX..., shows_per_round = 1, RESP...)),
              ("mixed greed, 2 shows, responsive", (; MIX..., shows_per_round = 2, RESP...)),
              ("mixed greed, unlimited, responsive", (; MIX..., RESP...)),
              ("mixed greed, unlimited, cost floor", (; MIX..., ask_floor = :cost)),
              ("greedy rich 25 %, 2 shows, responsive", (; MARKET..., greed = true, greed_share = 0.25, shows_per_round = 2, RESP...)),
              ("no greed, responsive", (; MARKET..., RESP...))]),
 "responsive" => (MIX = (; GREEDY..., greed_hoarding = 0.5);
                  RESP = (; ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, bread_bid_base_multiplier = 2.0);
                  EQ = (; start_at_saturation = :equilibrium, initial_price_multiplier = 1.35);
                  [("mixed greed, 2 shows, fully responsive", (; MIX..., shows_per_round = 2, RESP...)),
                   ("mixed greed, 1 show, fully responsive", (; MIX..., shows_per_round = 1, RESP...)),
                   ("mixed greed, unlimited, fully responsive", (; MIX..., RESP...)),
                   ("mixed greed, 2 shows, responsive, equilibrium start", (; MIX..., shows_per_round = 2, RESP..., EQ...)),
                   ("mixed greed, 1 show, floor + thresholds, equilibrium start", (; MIX..., shows_per_round = 1, ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, EQ...)),
                   ("mixed greed, unlimited, equilibrium start", (; MIX..., EQ...)),
                   ("no greed, equilibrium start", (; MARKET..., EQ...)),
                   ("greedy rich 25 %, 2 shows, fully responsive, equilibrium start", (; MARKET..., greed = true, greed_share = 0.25, shows_per_round = 2, RESP..., EQ...)),
                   ("no greed, fully responsive", (; MARKET..., RESP...))]),
 "reserve" => (RES = (; government_reserve_in_rounds = 3); MIX = (; GREEDY..., greed_hoarding = 0.5);
               RESP = (; ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, bread_bid_base_multiplier = 2.0);
               EQ = (; start_at_saturation = :equilibrium, initial_price_multiplier = 1.35);
               [("no greed, surplus redistributed", (; MARKET..., RES..., surplus_redistribution_share = 1.0)),
                ("no greed, surplus lowers taxes", (; MARKET..., RES..., surplus_tax_reduction_share = 1.0)),
                ("no greed, half and half", (; MARKET..., RES..., surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5)),
                ("mixed greed, responsive, surplus redistributed", (; MIX..., RESP..., RES..., surplus_redistribution_share = 1.0)),
                ("mixed greed, responsive, surplus lowers taxes", (; MIX..., RESP..., RES..., surplus_tax_reduction_share = 1.0)),
                ("mixed greed, responsive, equilibrium start, half and half", (; MIX..., RESP..., EQ..., RES..., surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5)),
                ("greedy rich 25 %, equilibrium start, half and half", (; MARKET..., greed = true, greed_share = 0.25, EQ..., RES..., surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5)),
                ("greedy rich 25 %, equilibrium start, no reserve rule", (; MARKET..., greed = true, greed_share = 0.25, EQ...))]),
 "fiscal" => (RES = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0); PROG = (; income_tax_schedule = :progressive);
              [("no policy", (; MARKET..., RES...)),
               ("scale, cover 25 %, step 2 %", (; MARKET..., RES..., tax_policy = :scale, tax_response_coverage = 0.25, tax_response_step = 0.02)),
               ("scale, cover 50 %, step 2 %", (; MARKET..., RES..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02)),
               ("scale, cover 100 %, step 2 %", (; MARKET..., RES..., tax_policy = :scale, tax_response_coverage = 1.0, tax_response_step = 0.02)),
               ("scale, cover 50 %, step 5 %", (; MARKET..., RES..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.05)),
               ("progressive, no policy", (; MARKET..., RES..., PROG...)),
               ("brackets, cover 50 %, step 2 %", (; MARKET..., RES..., PROG..., tax_policy = :brackets, tax_response_coverage = 0.5, tax_response_step = 0.02)),
               ("brackets, cover 50 %, step 2 %, +0.5 pt fixed", (; MARKET..., RES..., PROG..., tax_policy = :brackets, tax_response_coverage = 0.5, tax_response_step = 0.02, bracket_fixed_rise = 0.005)),
               ("brackets, cover 100 %, step 2 %", (; MARKET..., RES..., PROG..., tax_policy = :brackets, tax_response_coverage = 1.0, tax_response_step = 0.02))]),
 "ceiling" => (RES = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0, tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02);
               [("ceiling 1.2 (18 %)", (; MARKET..., RES..., tax_scale_maximum = 1.2)),
                ("ceiling 1.33 (20 %)", (; MARKET..., RES..., tax_scale_maximum = 4/3)),
                ("ceiling 1.5 (22.5 %)", (; MARKET..., RES..., tax_scale_maximum = 1.5)),
                ("ceiling 1.67 (25 %)", (; MARKET..., RES..., tax_scale_maximum = 5/3)),
                ("ceiling 2.0 (30 %)", (; MARKET..., RES..., tax_scale_maximum = 2.0)),
                ("ceiling 2.33 (35 %)", (; MARKET..., RES..., tax_scale_maximum = 7/3))]),
 "vat" => (RES = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0); POL = (; RES..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0);
           MIX = (; GREEDY..., greed_hoarding = 0.5); RESP = (; ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, bread_bid_base_multiplier = 2.0);
           [# debt village: can a consumption tax close the deficit, and which mix bears it?
            ("VAT 6 %, no policy", (; MARKET..., RES..., consumption_tax_rate = 0.06)),
            ("VAT 12 %, no policy", (; MARKET..., RES..., consumption_tax_rate = 0.12)),
            ("VAT 6 %, policy, one scale", (; MARKET..., POL..., consumption_tax_rate = 0.06)),
            ("VAT 6 %, policy, levers 1:-1:0", (; MARKET..., POL..., consumption_tax_rate = 0.06, tax_levers = (income = 1.0, consumption = -1.0, wealth = 0.0))),
            ("VAT 6 %, policy, levers 0:0:0", (; MARKET..., POL..., consumption_tax_rate = 0.06)),
            ("VAT 6 %, policy, levers -2:1:0", (; MARKET..., POL..., consumption_tax_rate = 0.06, tax_levers = (income = -2.0, consumption = 1.0, wealth = 0.0))),
            ("VAT 6 %, policy, levers -3:1:0", (; MARKET..., POL..., consumption_tax_rate = 0.06, tax_levers = (income = -3.0, consumption = 1.0, wealth = 0.0))),
            # SuMSy: does a consumption tax do anything to the greedy village?
            ("mixed greed, VAT 6 %", (; MIX..., RES..., consumption_tax_rate = 0.06)),
            ("mixed greed, VAT 20 %", (; MIX..., RES..., consumption_tax_rate = 0.20)),
            ("mixed greed, responsive, VAT 6 %", (; MIX..., RESP..., RES..., consumption_tax_rate = 0.06)),
            ("mixed greed, responsive, VAT 20 %", (; MIX..., RESP..., RES..., consumption_tax_rate = 0.20)),
            ("greedy rich 25 %, VAT 6 %", (; MARKET..., greed = true, greed_share = 0.25, RES..., consumption_tax_rate = 0.06)),
            ("greedy rich 25 %, VAT 20 %", (; MARKET..., greed = true, greed_share = 0.25, RES..., consumption_tax_rate = 0.20)),
            ("no greed, VAT 6 %", (; MARKET..., RES..., consumption_tax_rate = 0.06)),
            # the reserve rule's tax-cut disposal scales a SuMSy VAT away (the government over-collects); these keep the VAT by paying the surplus out instead
            ("mixed greed, VAT 20 %, surplus paid out", (; MIX..., government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0, consumption_tax_rate = 0.20)),
            ("mixed greed, responsive, VAT 20 %, surplus paid out", (; MIX..., RESP..., government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0, consumption_tax_rate = 0.20)),
            ("greedy rich 25 %, VAT 20 %, surplus paid out", (; MARKET..., greed = true, greed_share = 0.25, government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0, consumption_tax_rate = 0.20)),
            ("greedy rich 25 %, VAT 40 %, surplus paid out", (; MARKET..., greed = true, greed_share = 0.25, government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0, consumption_tax_rate = 0.40)),
            ("no greed, VAT 20 %, surplus paid out", (; MARKET..., government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0, consumption_tax_rate = 0.20))]),
 "wealth" => (RES = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0);
              BEST = (; RES..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0, consumption_tax_rate = 0.06, tax_levers = (income = -2.0, consumption = 1.0, wealth = 0.0));
              MIX = (; GREEDY..., greed_hoarding = 0.5); RESP = (; ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, bread_bid_base_multiplier = 2.0);
              vcat([("wealth tax $(Int(100r)) %, debt baseline", (; MARKET..., RES..., wealth_tax_rate = r)) for r in (0.01, 0.02, 0.05, 0.10, 0.25)],
                   [("wealth tax $(Int(100r)) %, best debt scenario", (; MARKET..., BEST..., wealth_tax_rate = r)) for r in (0.02, 0.05, 0.10, 0.25)],
                   [("mixed greed, wealth tax $(Int(100r)) %", (; MIX..., wealth_tax_rate = r)) for r in (0.02, 0.10, 0.25)],
                   [("mixed greed, responsive, wealth tax $(Int(100r)) %", (; MIX..., RESP..., wealth_tax_rate = r)) for r in (0.02, 0.10, 0.25)],
                   [("greedy rich 25 %, wealth tax $(Int(100r)) %", (; MARKET..., greed = true, greed_share = 0.25, wealth_tax_rate = r)) for r in (0.02, 0.10, 0.25)],
                   [("no greed, wealth tax $(Int(100r)) %", (; MARKET..., wealth_tax_rate = r)) for r in (0.05, 0.25)])),
 "mix" => (POL = (; government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0, tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02, tax_scale_maximum = 2.0,
                    consumption_tax_rate = 0.06, wealth_tax_rate = 0.05);
           [("levers i:c:w = $(l[1]):$(l[2]):$(l[3])", (; MARKET..., POL..., tax_levers = (income = Float64(l[1]), consumption = Float64(l[2]), wealth = Float64(l[3]))))
            for l in ((0, 0, 0), (-1, 0, 0), (-2, 0, 0), (-3, 0, 0), (-1, 1, 0), (-2, 1, 0), (-3, 1, 0), (-2, 2, 0), (-2, 1, 1), (-2, 0, 2), (-3, 2, 1), (-1, -1, 2), (1, -1, -1), (-1, 1, -1))]),
 "clearing" => (MIX = (; GREEDY..., greed_hoarding = 0.5);
                [("no greed, clearing off", (; MARKET..., clearing = false)),
                 ("mixed greed, clearing off", (; MIX..., clearing = false)),
                 ("greedy rich 25 %, clearing off", (; MARKET..., greed = true, greed_share = 0.25, clearing = false)),
                 ("mixed greed, 2 shows, fully responsive, clearing off", (; MIX..., shows_per_round = 2, ask_floor = :cost, unsold_share = 0.05, unmet_demand_share = 0.05, bread_bid_base_multiplier = 2.0, clearing = false))]),
 "threshold" => [("no greed, unmet 5 %", (; MARKET..., unmet_demand_share = 0.05)), ("no greed, unmet 10 %", (; MARKET..., unmet_demand_share = 0.10)),
                 ("greedy rich 25 %, unmet 5 %", (; MARKET..., greed = true, greed_share = 0.25, unmet_demand_share = 0.05)),
                 ("greedy rich 25 %, unmet 10 %", (; MARKET..., greed = true, greed_share = 0.25, unmet_demand_share = 0.10)),
                 ("hoarding 0.5, unmet 5 %", (; GREEDY..., greed_hoarding = 0.5, unmet_demand_share = 0.05)),
                 ("hoarding 0.5 + wage ceiling 4, unmet 5 %", (; GREEDY..., greed_hoarding = 0.5, wage_ceiling_in_breads = 4.0, unmet_demand_share = 0.05))],
 "contribution" => (COOP = (; MARKET..., number_of_farms = 4, number_of_bakeries = 4, ownership = :mixed, cooperative_theatres = 1,
                            cooperative_form_farms = :worker, cooperative_form_bakeries = :worker, cooperative_form_theatres = :consumer);
                    [("money only", COOP),
                     ("buffer pledge only", (; COOP..., membership_contribution = :buffer)),
                     ("mixed, both fixed", (; COOP..., membership_contribution = :mixed_fixed)),
                     ("mixed, member chooses", (; COOP..., membership_contribution = :mixed_flexible)),
                     ("mixed, member chooses, buffer at 2x", (; COOP..., membership_contribution = :mixed_flexible, buffer_contribution_value = 2.0)),
                     ("buffer pledge only, half buffer", (; COOP..., membership_contribution = :buffer, membership_buffer_pledge = 15.0))]),
 "greed" => [("no greed", MARKET), ("greedy rich 25 %", (; MARKET..., greed = true, greed_share = 0.25)), ("hoarding 0.0", (; GREEDY..., greed_hoarding = 0.0)), ("hoarding 0.25", (; GREEDY..., greed_hoarding = 0.25)), ("hoarding 0.5", (; GREEDY..., greed_hoarding = 0.5)), ("hoarding 0.75", (; GREEDY..., greed_hoarding = 0.75)), ("hoarding 1.0", (; GREEDY..., greed_hoarding = 1.0))],
 "measures" => [("hoarding 0.0 + rationing", (; GREEDY..., greed_hoarding = 0.0, bread_rationing = true)), ("hoarding 0.5 + rationing", (; GREEDY..., greed_hoarding = 0.5, bread_rationing = true)),
                ("hoarding 0.0 + tiered price", (; GREEDY..., greed_hoarding = 0.0, tiered_bread_price = true)), ("hoarding 0.5 + tiered price", (; GREEDY..., greed_hoarding = 0.5, tiered_bread_price = true)),
                ("hoarding 0.0 + land 2 + capacity 5 + ration", (; GREEDY..., greed_hoarding = 0.0, land_per_person = 2.0, maximum_capacity = 5.0, bread_rationing = true)),
                ("hoarding 0.5 + wage ceiling 4", (; GREEDY..., greed_hoarding = 0.5, wage_ceiling_in_breads = 4.0)), ("hoarding 0.0 + wage ceiling 4", (; GREEDY..., greed_hoarding = 0.0, wage_ceiling_in_breads = 4.0)),
                ("no greed, no self-service", (; MARKET..., no_self_service = true))],
 "indexed" => [("no greed, indexed income", (; MARKET..., guaranteed_income_in_breads = 1.0)), ("hoarding 0.0, indexed income", (; GREEDY..., greed_hoarding = 0.0, guaranteed_income_in_breads = 1.0)), ("hoarding 0.5, indexed income", (; GREEDY..., greed_hoarding = 0.5, guaranteed_income_in_breads = 1.0))],
 "saturation" => [("no greed, saturated upper", (; MARKET..., start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("no greed, saturated lower", (; MARKET..., start_at_saturation = :lower, initial_price_multiplier = 0.63)),
                  ("hoarding 0.0, saturated upper", (; GREEDY..., greed_hoarding = 0.0, start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("hoarding 0.5, saturated upper", (; GREEDY..., greed_hoarding = 0.5, start_at_saturation = :upper, initial_price_multiplier = 0.63)), ("hoarding 1.0, saturated upper", (; GREEDY..., greed_hoarding = 1.0, start_at_saturation = :upper, initial_price_multiplier = 0.63)),
                  ("hoarding 0.0, saturated lower", (; GREEDY..., greed_hoarding = 0.0, start_at_saturation = :lower, initial_price_multiplier = 0.63)), ("hoarding 0.5, saturated lower", (; GREEDY..., greed_hoarding = 0.5, start_at_saturation = :lower, initial_price_multiplier = 0.63))],
 "prices" => [("no greed ×0.5", (; MARKET..., initial_price_multiplier = 0.5)), ("no greed ×2", (; MARKET..., initial_price_multiplier = 2.0)),
              ("hoarding 0.0 ×0.5", (; GREEDY..., greed_hoarding = 0.0, initial_price_multiplier = 0.5)), ("hoarding 0.0 ×2", (; GREEDY..., greed_hoarding = 0.0, initial_price_multiplier = 2.0)),
              ("hoarding 0.5 ×0.5", (; GREEDY..., greed_hoarding = 0.5, initial_price_multiplier = 0.5)), ("hoarding 0.5 ×2", (; GREEDY..., greed_hoarding = 0.5, initial_price_multiplier = 2.0))])
order = length(ARGS) >= 1 ? split(ARGS[1], ",") : ["greed", "measures", "indexed", "share_market", "coops", "contribution", "capacity", "threshold", "shows", "floor", "responsive", "clearing", "reserve", "fiscal", "ceiling", "vat", "wealth", "mix", "saturation", "prices"]
# Resumable (20 September 2026): every run is appended to results/all64_<block>_rounds.csv as soon as it finishes, and a
# (variant, system, seed) already in that file is skipped, so an interrupted block picks up where it stopped. Delete the
# file to rerun a block from scratch.
# Starting prices and wages are one vector for both villages (`initial_prices`, scaled by the same `initial_price_multiplier`
# in every variant), so price levels can be compared across systems. Anything that sets them per system is a bug: checked here.
for (name, kw) in vcat(values(experiments)...)
    haskey(kw, :initial_prices) && error("variant '$name' sets its own initial prices: keep one vector for both systems")
    (haskey(DEBT, :initial_prices) || haskey(SUMSY, :initial_prices) || haskey(DEBT, :initial_price_multiplier) || haskey(SUMSY, :initial_price_multiplier)) &&
        error("DEBT / SUMSY may not set initial prices: they must be identical across systems")
end
# SuMSy never taxes income (its public money is the demurrage tax); a SuMSy run with a wage or capital tax is an error
# unless the variant is an explicit comparison (name it "(comparison)").
for (name, kw) in vcat(values(experiments)...)
    occursin("comparison", name) && continue
    full = (; BASE..., SUMSY..., kw...)
    (full.wage_tax_rate == 0 && full.capital_tax_rate == 0) || error("variant '$name' would tax income under SuMSy")
end
for exp in order
    path = joinpath(@__DIR__, "..", "results", "all64_$(exp)_rounds.csv")
    done = isfile(path) ? Set(Tuple.(eachrow(unique(CSV.read(path, DataFrame; select = [:variant, :system, :seed]))))) : Set()
    systems = length(ARGS) >= 3 ? split(ARGS[3], ",") : ["debt", "sumsy"]        # 3rd argument restricts the systems run
    for (name, kw) in experiments[exp], (system, base) in (("debt", DEBT), ("sumsy", SUMSY)), s in 1:nseeds
        system in systems || continue
        (exp in ("indexed", "saturation") && system == "debt") && continue           # SuMSy-only experiments
        (exp == "contribution" && system == "debt" && name != "money only") && continue  # a buffer pledge is worth nothing without demurrage
        (exp in ("fiscal", "ceiling", "mix") && system == "sumsy") && continue
        (exp == "vat" && system == "sumsy" && startswith(name, "VAT")) && continue   # the deficit question is the debt village's
        (exp == "vat" && system == "debt" && !startswith(name, "VAT")) && continue   # the greed question is SuMSy's
        (exp == "wealth" && system == "sumsy" && startswith(name, "wealth tax")) && continue   # the debt-village cells
        (exp == "wealth" && system == "debt" && !startswith(name, "wealth tax")) && continue   # the SuMSy cells                             # a debt-village policy: SuMSy funds itself from the demurrage tax
        (name, system, s) in done && continue
        t = @elapsed m = run_simulation(SimulationParameters(; seed = s, BASE..., base..., kw...)); d = round_data(m)
        d.variant .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m); d.seconds .= t
        CSV.write(path, d; append = isfile(path), header = !isfile(path))      # append, never rewrite (21 September: a rewrite crash truncated a file)
        println(exp, " | ", name, " ", system, " seed ", s, " ", round(t, digits = 1), "s alive ", d.persons_alive[end], " rounds ", nrow(d)); flush(stdout)
    end
end
