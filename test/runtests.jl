# BreadEconomySim test suite. Run with `julia --project=. test/runtests.jl` (or `Pkg.test()`).
# Three layers: (1) invariants that must hold in every run (money identity, determinism, nominal homogeneity),
# (2) unit behaviour of individual rules, (3) golden regression values for three reference configurations.
# Golden values: two sets since 18 September 2026 (per-subsystem random streams; the single-stream set is the 15 September one). Regenerated 15 September 2026 after the government's explicit debt roll-over at a policy rate (debt references)
# and 13 September 2026 after the land-valuation rule (a villager buys land only below its
# rent-stream value to them); earlier values were verified byte-identical to the pre-refactor package. if a deliberate rule change moves them, regenerate both sets with scripts/golden.jl and say so in HANDOFF.md.
using Test, BreadEconomySim, DataFrames, Statistics
const B = BreadEconomySim

# The behavioural rule set used in the report (random tie-breaking off so runs are reproducible across refactors).
const BEH = (; demand_based_targets = true, wage_ceiling_from_own_ask = true, expected_price_from_asks = true,
              ask_increase_only_on_unmet_demand = true, random_hiring_ties = false, no_labour_tolerance = true,
              offer_full_capacity = true, credit_for_bread = true, spoilage_aware_stocking = true, distress_land_sales = true,
              maximum_capacity = 4.0, number_of_landowners = 4, land_units_per_landowner_override = 6,
              wage_reservation_net_of_tax = true, minimum_fee_in_breads = 2.0, partial_unemployment_fee = true,
              initial_endowment = :norm, startup_loan_term = 50, land_sales = :reservation, plan_for_gluttony = true,
              stop_when_half_dead = false, stop_when_stationary = false)
const SUM = (; monetary_system = :sumsy, wage_tax_rate = 0.0, capital_tax_rate = 0.0, unemployment_fee_in_breads = 0.0,
              minimum_fee_in_breads = 0.0, partial_unemployment_fee = false, government_employment_share = 0.0,
              account_fee_person = 0.5, account_fee_enterprise = 1.5, demurrage_rate = 0.02,
              instalment_purchases = true, land_price_rent_multiple = 50.0)
run(; kw...) = run_simulation(SimulationParameters(; kw...))
const TH = (; BEH..., entertainment = true, planning_margin = 0.1, plan_for_gluttony = true)
const OWN = (; TH..., ownership = :mixed, number_of_farms = 4, number_of_bakeries = 4, share_market = true, startup_financing = :paid_in_capital)
const SUMSY_OWN = (; OWN..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01)

@testset "BreadEconomySim" begin

@testset "money identity holds in every system" begin
    for (name, kw) in [("debt", BEH), ("sumsy", (; BEH..., SUM...)),
                       ("debt+bonds+deposits", (; BEH..., government_bonds = true, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02)),
                       ("sumsy+pool+insurance+shock", (; BEH..., SUM..., buffer_lending = true, default_insurance = true, harvest_shock_start = 5))]
        m = run(; seed = 1, maximum_rounds = 12, kw...)
        @test abs(money_identity_gap(m)) < 1e-8
    end
    # repayments to a closed bank, or with deposits another bank created, book as a negative deposit liability of the
    # creditor (its interbank claim) instead of leaking: the bank balance allows it (see create_bread_economy)
    for kw in [(; BEH..., startup_loan_term = 8, entertainment = true, planning_margin = 0.1), (; BEH..., startup_loan_term = 8)]
        m = run(; seed = 2, maximum_rounds = 12, kw...)
        @test abs(money_identity_gap(m)) < 1e-6
    end

# ---------------------------------------------------------------------------------------------------
# Features added 13 September 2026: theatre, ownership and dividends, share market, paid-in founding,
# cooperative membership, clearing switch, greed, rationing, tiered bread price, self-service rule.
# ---------------------------------------------------------------------------------------------------

@testset "money identity survives every new feature" begin
    for kw in [TH, OWN, SUMSY_OWN, (; TH..., clearing = false), (; SUMSY_OWN..., clearing = false),
               (; OWN..., greed = true, greed_share = 1.0), (; SUMSY_OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0, bread_rationing = true, tiered_bread_price = true),
               (; OWN..., greed = true, no_self_service = true, number_of_theatres = 2)]
        m = run(; seed = 4, maximum_rounds = 15, kw...)
        @test abs(money_identity_gap(m)) < 1e-6
    end
end

@testset "theatre: pure service, tickets consumed, staff rule" begin
    d = round_data(run(; seed = 1, maximum_rounds = 15, TH...))
    @test d.theatres_open[end] == 1 && sum(d.tickets_sold) > 0 && sum(d.ticket_revenue) > 0
    @test all(d.theatre_labour .<= 4 * 16)                              # never more labour than the village has
    m = run(; seed = 1, maximum_rounds = 8, TH...)
    @test all(isempty(e.bread) for e in B.enterprises(m, :theatre))     # a theatre holds no goods
    a = sum(round_data(run(; seed = 2, maximum_rounds = 20, TH...)).tickets_sold)
    b = sum(round_data(run(; seed = 2, maximum_rounds = 20, TH..., no_self_service = true)).tickets_sold)
    @test b <= a                                                         # excluding staff cannot raise sales
end

@testset "ownership: dividends only above the reserve, co-ops per member, founders per share" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, OWN...))
    coop = first(e for e in B.enterprises(m, :farm) if e.ownership == :cooperative); firm = first(e for e in B.enterprises(m, :farm) if e.ownership == :shareholders)
    @test isempty(coop.members) && sum(values(firm.shares)) ≈ 100.0      # paid-in founding: no members yet, founders hold all shares
    # a firm exactly at its reserve pays nothing; one above it pays out over dividend_build_rounds
    B.book_asset!(firm.balance, B.DEPOSIT, B.reserve_target(m, firm) - B.cash(firm))
    B.pay_dividends!(m); @test firm.dividend_history[end] == 0.0
    B.book_asset!(firm.balance, B.DEPOSIT, 100.0); B.pay_dividends!(m)
    @test firm.dividend_history[end] ≈ 100.0 / B.parameters(m).dividend_build_rounds atol = 1e-6
    holders = [m[h] for h in keys(firm.shares)]
    @test sum(h.dividend_income for h in holders) ≈ firm.dividend_history[end] * (1 - B.parameters(m).dividend_tax_rate) atol = 1e-6
    # cooperative: two members with unequal shares get equal dividends
    nonfounders = [w for w in B.persons(m) if !any(e -> e isa Enterprise && haskey(e.shares, w.id), B.alive_agents(m))]
    w1, w2 = nonfounders[1], nonfounders[2]; coop.members[w1.id] = 3; coop.members[w2.id] = 1
    B.book_asset!(coop.balance, B.DEPOSIT, B.reserve_target(m, coop) - B.cash(coop) + 50.0)
    w1.dividend_income = 0.0; w2.dividend_income = 0.0; B.pay_dividends!(m)
    @test w1.dividend_income ≈ w2.dividend_income atol = 1e-6
    @test w1.dividend_income > 0
end

@testset "paid-in founding: businesses start empty, founders carry the debt, capital arrives" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, OWN...))
    @test all(B.cash(e) ≈ 0 for e in B.alive_agents(m) if B.is_producer(e))
    founders = [w for w in B.persons(m) if any(e -> e isa Enterprise && e.ownership == :shareholders && haskey(e.shares, w.id), B.alive_agents(m))]
    @test length(founders) == 2 && all(B.debt_of(f) > 0 for f in founders)                       # they borrowed the villagers' starting cash
    @test all(isapprox(B.cash(w), B.savings_buffer(m); atol = 1e-3) for w in B.persons(m) if !(w in founders))
    d = round_data(run(; seed = 1, maximum_rounds = 30, OWN...))
    @test d.founder_capital[end] > 0 && d.reserve_shortfall_forprofit[end] < d.reserve_shortfall_forprofit[1]   # capital paid in, shortfall shrinks
    ds = round_data(run(; seed = 1, maximum_rounds = 30, SUMSY_OWN...))
    @test ds.founder_capital[end] > 0 && ds.founder_debt[end] > 0 && ds.government_debt[end] == 0            # SuMSy founders borrow from villagers
end

@testset "cooperative membership: join at par above the buffer, redeem at par in distress" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, SUMSY_OWN..., cooperative_join_probability = 1.0))
    coop = first(e for e in B.alive_agents(m) if e isa Enterprise && e.ownership == :cooperative)
    w = B.persons(m)[1]; B.book_asset!(w.balance, B.DEPOSIT, 100.0); c0 = B.cash(w); cap0 = B.cash(coop)
    B.join_cooperatives!(m)
    par = B.parameters(m).membership_share_price
    @test sum(get(c.members, w.id, 0) for c in B.alive_agents(m) if c isa Enterprise && c.ownership == :cooperative) == 1   # one cooperative per round
    @test c0 - B.cash(w) ≈ par atol = 1e-6
    # distress: cash below a meal → one share redeemed at par by a cooperative that can pay
    c = first(cc for cc in B.alive_agents(m) if cc isa Enterprise && cc.ownership == :cooperative && get(cc.members, w.id, 0) > 0)
    B.book_asset!(w.balance, B.DEPOSIT, -B.cash(w)); B.book_asset!(c.balance, B.DEPOSIT, par); B.join_cooperatives!(m)
    @test B.cash(w) ≈ par atol = 1e-6
    @test get(c.members, w.id, 0) == 0
end

@testset "share market: distressed founders sell, price bounded by the buyer's ceiling" begin
    d = round_data(run(; seed = 2, maximum_rounds = 40, OWN...))
    @test sum(d.share_trades) > 0
    ds = round_data(run(; seed = 2, maximum_rounds = 40, SUMSY_OWN...))
    @test sum(ds.share_trades) == 0                                       # founders never short of a meal under SuMSy
    @test all(0 .<= filter(!isnan, d.share_price_mean))
end

@testset "clearing switch: immediate settlement keeps the accounting, leaves SuMSy nearly unchanged" begin
    a = round_data(run(; seed = 3, maximum_rounds = 20, SUMSY_OWN...)); b = round_data(run(; seed = 3, maximum_rounds = 20, SUMSY_OWN..., clearing = false))
    @test a.persons_alive[end] == b.persons_alive[end] && abs(sum(a.tickets_sold) - sum(b.tickets_sold)) < 0.35 * sum(a.tickets_sold)
    c = round_data(run(; seed = 3, maximum_rounds = 20, TH..., clearing = false))
    @test c.trade_arrears[end] >= 0 && c.persons_alive[end] >= 12
end

@testset "greed: assignment to the rich, the slider, caps, most-profitable-first capital" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, OWN..., greed = true, greed_share = 0.25))
    g = [w for w in B.persons(m) if w.greed == :greedy]
    @test length(g) == 4
    @test all(w.initial_landowner || any(e -> e isa Enterprise && haskey(e.shares, w.id), B.alive_agents(m)) for w in g)   # the rich
    m2 = create_bread_economy(SimulationParameters(; seed = 1, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0, greedy_max_breads_per_round = 4))
    w = first(B.persons(m2)); B.book_asset!(w.balance, B.DEPOSIT, 500.0)
    for f in B.ROUND_BEHAVIORS[1:findfirst(f -> f === B.greed_spending!, B.ROUND_BEHAVIORS)]; f(m2); end
    @test B.bread_units(w) <= 4                                           # greedy cap respected
    d1 = round_data(run(; seed = 1, maximum_rounds = 12, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 1.0))
    @test sum(d1.greedy_loaves) == 0 && sum(d1.greedy_tickets) == 0     # all-capital greed buys no extras
    d1s = round_data(run(; seed = 1, maximum_rounds = 20, SUMSY_OWN..., greed = true, greed_share = 1.0, greed_hoarding = 1.0))
    @test sum(d1s.greedy_land) == 0                                       # ... and never buys land at exactly its value (no distress → no seller below it)
    d0 = round_data(run(; seed = 1, maximum_rounds = 12, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0))
    @test sum(d0.greedy_land) + sum(d0.greedy_shares) == 0 && sum(d0.greedy_loaves) + sum(d0.greedy_tickets) > 0
    # capital yields: under SuMSy cash yields −demurrage and is never chosen while land or shares are on offer and affordable
    ms = create_bread_economy(SimulationParameters(; seed = 1, SUMSY_OWN..., greed = true, greed_share = 1.0, greed_hoarding = 1.0))
    w = first(B.persons(ms)); B.book_asset!(w.balance, B.DEPOSIT, 1000.0)
    bought = B.greedy_capital_act!(ms, w, B.cash(w) - B.buffer_target(ms, w))
    @test !bought                                                          # land is on offer at exactly its value to the buyer: not a purchase; cash is the fallthrough
end

@testset "land_per_person" begin
    p = SimulationParameters(; number_of_persons = 16, number_of_landowners = 4, land_per_person = 2.0)
    @test B.land_units_per_landowner(p) * 4 == 32                         # four loaves a head on the land side
    m = create_bread_economy(p); @test sum(w.land for w in B.persons(m)) == 32
end

@testset "rationing and tiered price" begin
    d = round_data(run(; seed = 1, maximum_rounds = 12, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0, bread_rationing = true))
    @test all(2 .<= d.ration .<= 4)                                       # never below a meal, never above the ration
    m = create_bread_economy(SimulationParameters(; seed = 1, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0, tiered_bread_price = true))
    B.econo_step!(m, 1)                                                   # a round of trading, so the bakery has a market record
    e = first(B.enterprises(m, :bakery)); e.tier_multiplier = 1.0; e.tier_unmet = true
    p0 = B.expected_price(m, :bread); B.adapt_prices!(m)
    @test e.tier_multiplier ≈ 1 + B.parameters(m).tier_step atol = 1e-9   # rises on unmet greed
    @test B.expected_price(m, :bread) ≈ p0                                # ordinary price untouched by the tier
    dt = round_data(run(; seed = 1, maximum_rounds = 20, OWN..., greed = true, greed_share = 1.0, greed_hoarding = 0.0, tiered_bread_price = true))
    @test all(dt.tier_multiplier .>= 1.0) && sum(dt.tier_revenue) >= 0
end

end

@testset "random streams are isolated per subsystem (18 September 2026)" begin
    # Burning draws from a stream that the run never uses must leave the run untouched...
    a = round_data(run(; seed = 5, maximum_rounds = 12, BEH...))
    m = create_bread_economy(SimulationParameters(; seed = 5, maximum_rounds = 12, BEH...))
    rand(B.stream(m, :cooperatives), 1_000); rand(B.stream(m, :shares), 1_000)      # no co-ops, no share market in BEH
    b = round_data(B.run_simulation!(m))
    @test a.money_in_circulation == b.money_in_circulation && a.price_bread == b.price_bread && a.price_wage == b.price_wage
    # ...and burning draws from a stream it does use must change it (so the test above is not vacuous)
    m2 = create_bread_economy(SimulationParameters(; seed = 5, maximum_rounds = 12, BEH...))
    rand(B.stream(m2, :negotiation), 1)
    c = round_data(B.run_simulation!(m2))
    @test c.price_bread != a.price_bread || c.price_wage != a.price_wage
    # with the single shared stream, the unrelated draws do change the run: this is the defect the streams remove
    s0 = round_data(run(; seed = 5, maximum_rounds = 12, BEH..., random_streams = false))
    m3 = create_bread_economy(SimulationParameters(; seed = 5, maximum_rounds = 12, BEH..., random_streams = false))
    rand(B.stream(m3, :cooperatives), 1_000)
    s1 = round_data(B.run_simulation!(m3))
    @test s0.price_bread != s1.price_bread || s0.price_wage != s1.price_wage
    # a switch that only adds draws in one subsystem leaves the others alone: greed drawn at random at the founding,
    # but with nobody greedy, changes nothing but the greed stream
    g0 = round_data(run(; seed = 5, maximum_rounds = 12, BEH..., greed = true, greed_share = 0.0, greed_selection = :rich))
    g1 = round_data(run(; seed = 5, maximum_rounds = 12, BEH..., greed = true, greed_share = 0.0, greed_selection = :random))
    @test g0.money_in_circulation == g1.money_in_circulation && g0.price_bread == g1.price_bread
    # every stream exists and is seeded from the run seed and its own name
    @test Set(keys(m.streams)) == Set(B.RANDOM_STREAMS)
    x = create_bread_economy(SimulationParameters(; seed = 5, BEH...)); y = create_bread_economy(SimulationParameters(; seed = 6, BEH...))
    @test rand(B.stream(x, :labour)) != rand(B.stream(y, :labour))
    @test rand(B.stream(x, :labour)) != rand(B.stream(x, :land))
end

@testset "determinism: same seed, same run" begin
    a = round_data(run(; seed = 7, maximum_rounds = 10, BEH...)); b = round_data(run(; seed = 7, maximum_rounds = 10, BEH...))
    @test a.money_in_circulation == b.money_in_circulation && a.price_bread == b.price_bread
    c = round_data(run(; seed = 8, maximum_rounds = 10, BEH...))
    @test a.money_in_circulation != c.money_in_circulation
end

@testset "nominal homogeneity: scaling every nominal quantity leaves the real economy unchanged" begin
    nominal(f) = (; guaranteed_income = 5.0 * f, demurrage_free_buffer = 30.0 * f, initial_money_per_person = 30.0 * f,
                    initial_prices = Dict(:bread => 5.0 * f, :grain => 5.2 * f, :rent => 0.75 * f, :wage => 3.92 * f),
                    account_fee_person = 0.5 * f, account_fee_enterprise = 1.5 * f)
    base = (; BEH..., SUM..., initial_endowment = :none, instalment_purchases = false, land_price_rent_multiple = 15.0, maximum_rounds = 15, seed = 2)
    a = round_data(run(; base..., nominal(1.0)...)); b = round_data(run(; base..., nominal(0.5)...))
    @test a.persons_alive == b.persons_alive && a.bread_baked == b.bread_baked && a.hungry == b.hungry
    # payments are rounded to 4 decimals, so the invariant holds to ~1e-5 relative, not exactly
    # element-wise, with NaN (a round without a bread trade) treated as equal to NaN
    @test all(isapprox.(a.money_in_circulation, 2 .* b.money_in_circulation; rtol = 1e-4, nans = true))
    @test all(isapprox.(a.price_bread, 2 .* b.price_bread; rtol = 1e-4, nans = true))
end

@testset "endowment at norm terminates and sums for awkward village sizes" begin
    for n in (16, 100, 400)
        m = create_bread_economy(SimulationParameters(; seed = 1, initial_endowment = :norm, number_of_persons = n, number_of_landowners = max(n ÷ 10, 2),
                                                        land_units_per_landowner_override = 12, initial_production_target = max(n ÷ 4, 6),
                                                        number_of_farms = 5, number_of_bakeries = 4, number_of_banks = 3))
        @test all(isapprox(B.cash(w), B.savings_buffer(m); atol = 1e-3) for w in B.persons(m))
        @test all(B.cash(e) >= B.reserve_target(m, e) - 1e-3 for e in B.alive_agents(m) if B.is_producer(e))
        @test abs(money_identity_gap(m)) < 1e-8
    end
end

@testset "Gini" begin
    @test B.gini([1.0, 1.0, 1.0, 1.0]) ≈ 0.0
    @test B.gini([0.0, 0.0, 0.0, 4.0]) ≈ 0.75 atol = 1e-9
    @test 0.0 < B.gini([1.0, 2.0, 3.0, 4.0]) < 0.5
end

@testset "demand-based planning allots exactly the population's meals" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, BEH...))
    B.plan_targets!(m)
    bakeries = B.enterprises(m, :bakery)
    need_grain = ceil(Int, (sum(max(2 - B.bread_units(w), 0.0) for w in B.persons(m)) - sum(B.bread_units(b) for b in bakeries)) / 2)
    @test sum(b.production_target for b in bakeries) == max(need_grain, length(bakeries))
    @test maximum(b.production_target for b in bakeries) - minimum(b.production_target for b in bakeries) <= 1
end

@testset "gluttons eat three loaves, others two, stock ages" begin
    m = create_bread_economy(SimulationParameters(; seed = 1))
    w = first(B.persons(m)); empty!(w.bread); push!(w.bread, B.StockItem(5.0, 0))
    w.glutton = true; B.eat!(m); @test B.bread_units(w) == 2.0 && w.ate_this_round == :whole
    m = create_bread_economy(SimulationParameters(; seed = 1))
    w = first(B.persons(m)); empty!(w.bread); push!(w.bread, B.StockItem(5.0, 0))
    w.glutton = false; B.eat!(m); @test B.bread_units(w) == 3.0
end

@testset "Belgian income tax schedule" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, income_tax_schedule = :belgian, maximum_capacity = 4.0))
    ref = 4.0 * B.expected_price(m, :wage)
    eff(x) = B.wage_tax_amount(m, x * ref) / (x * ref)
    @test 0.25 < eff(0.5) < 0.27          # half-time worker: 13 % contributions plus ≈ 13 % income tax
    @test 0.38 < eff(1.0) < 0.40          # full-time: ≈ 39 % of gross
    @test 0.48 < eff(2.0) < 0.50          # twice the reference: ≈ 49 %
    @test eff(0.5) < eff(1.0) < eff(2.0)  # progressive
    @test B.wage_tax_amount(m, 0.0) == 0.0
    # marginal application over several hires in a round adds up to the schedule on the total
    w = first(B.persons(m)); e = first(B.enterprises(m, :bakery)); total = 0.0
    for g in (ref / 4, ref / 4, ref / 2)
        before = w.gross_wage_this_round
        B.pay_income!(m, e, w, g, :wage)
        total += B.wage_tax_amount(m, before + g) - B.wage_tax_amount(m, before)
    end
    @test total ≈ B.wage_tax_amount(m, ref) atol = 1e-6
end

@testset "peer loan servicing: negative interest, spread, arrears" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, BEH..., SUM...))
    lender = B.persons(m)[1]; borrower = B.persons(m)[2]; bank = first(B.enterprises(m, :bank))
    c0 = (B.cash(lender), B.cash(borrower), B.cash(bank))
    l = B.PeerLoan(1, lender.id, borrower.id, bank.id, 100.0, 100.0, 10.0, -0.01, -0.015, false, 0, 0, false, false, 0.0)
    push!(m.peer_loans, l)
    B.service_peer_loans!(m)
    @test l.outstanding ≈ 90.0 atol = 1e-6
    @test B.cash(borrower) ≈ c0[2] - (10.0 - 1.0) atol = 1e-6       # instalment 10, interest −1
    @test B.cash(lender) ≈ c0[1] + (10.0 - 1.5) atol = 1e-6         # receives rate minus spread
    @test B.cash(bank) ≈ c0[3] + 0.5 atol = 1e-6                    # keeps the spread
    @test !l.in_arrears
    B.book_asset!(borrower.balance, B.DEPOSIT, -B.cash(borrower))     # drain the borrower
    B.service_peer_loans!(m)
    @test l.in_arrears && l.arrears_rounds == 1
end

@testset "bonds take the government's borrowing before the bank" begin
    d = round_data(run(; seed = 1, maximum_rounds = 15, BEH..., government_bonds = true))
    @test d.bonds_outstanding[end] > 0 && d.government_bank_debt[end] < 0.2 * d.government_debt[end]
    @test d.government_debt[end] ≈ d.bonds_outstanding[end] + d.government_bank_debt[end]
end

@testset "buffer pool conserves the demurrage exemption" begin
    m = create_bread_economy(SimulationParameters(; seed = 1, BEH..., SUM..., buffer_lending = true, buffer_lending_participation = 1.0))
    B.begin_round!(m); B.pay_guaranteed_income!(m); B.manage_buffer_pool!(m)
    p = B.parameters(m)
    exempt = sum(B.demurrage_buffer(m, a) for a in B.alive_agents(m))
    @test exempt ≈ p.demurrage_free_buffer * length(B.persons(m)) atol = 1e-6
    @test sum(b.buffer_received for b in B.enterprises(m, :bank)) ≈ sum(w.buffer_lent for w in B.persons(m)) atol = 1e-6
    @test sum(w.buffer_lent for w in B.persons(m)) > 0
end

@testset "deposit interest is paid to persons only by default" begin
    d = round_data(run(; seed = 1, maximum_rounds = 13, BEH..., deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02))
    @test d.deposit_interest[12] > 0 && all(d.deposit_interest[[1:11; 13]] .== 0)
end

@testset "golden regression: three reference configurations, seed 3, round 25" begin
    # Two sets. `single` are the 15 September values, reproduced with the single shared random stream
    # (`random_streams = false`) — they pin every rule of the model. `streams` are the same configurations under
    # the per-subsystem streams introduced on 18 September (scripts/golden.jl regenerates both).
    golden = Dict(
        ("single", "debt")       => (; price_bread = 10.341650000000001, price_wage = 8.496565966386557, money = 3343.3054, debt = 3479.9816999999994, gov_debt = 1671.1629, gini = 0.4909144544995363, cash_persons = 2183.7604, tax = 62.40420000000001),
        ("single", "debt_bonds") => (; price_bread = 13.5533125, price_wage = 11.608659512867648, money = 2618.7219999999998, debt = 2866.6173000000003, gov_debt = 1728.8779999999997, gini = 0.5427750932785462, cash_persons = 1171.5859999999998, tax = 79.3876),
        ("single", "sumsy")      => (; price_bread = 5.59341, price_wage = 4.3970382352941195, money = 2483.7348, debt = 219.1551, gov_debt = 0.0, gini = 0.31784422803863843, cash_persons = 1681.4892, tax = 0.0),
        ("streams", "debt")       => (; price_bread = 9.182139393939394, price_wage = 7.509551369485296, money = 2990.4571999999994, debt = 3104.4931, gov_debt = 1589.7893, gini = 0.4779300422969981, cash_persons = 2041.6322, tax = 53.0059),
        ("streams", "debt_bonds") => (; price_bread = 12.89620303030303, price_wage = 10.99115597426471, money = 2580.9275000000002, debt = 2815.4759000000004, gov_debt = 1694.9814999999999, gini = 0.4982773624362766, cash_persons = 1136.9422, tax = 76.24039999999994),
        ("streams", "sumsy")      => (; price_bread = 4.8844666666666665, price_wage = 3.8839382352941185, money = 2483.682599999999, debt = 190.53699999999998, gov_debt = 0.0, gini = 0.29290288733073977, cash_persons = 1720.3856, tax = 0.0))
    configs = Dict("debt" => BEH, "sumsy" => (; BEH..., SUM...),
                   "debt_bonds" => (; BEH..., government_bonds = true, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02))
    for (mode, streams) in (("single", false), ("streams", true)), (name, kw) in configs
        d = round_data(run(; seed = 3, maximum_rounds = 25, random_streams = streams, kw...)); r = d[end, :]; g = golden[(mode, name)]
        @test r.persons_alive == 16 && 32.0 <= r.bread_baked <= 36.0      # everyone alive; the bakeries plan the population's meals plus at most a small surplus
        @test r.price_bread ≈ g.price_bread rtol = 1e-9
        @test r.price_wage ≈ g.price_wage rtol = 1e-9
        @test r.money_in_circulation ≈ g.money rtol = 1e-9
        @test r.outstanding_debt ≈ g.debt rtol = 1e-9
        @test r.government_debt ≈ g.gov_debt atol = 1e-6
        @test r.gini_net_wealth_persons ≈ g.gini rtol = 1e-9
        @test r.cash_persons ≈ g.cash_persons rtol = 1e-9
        @test r.tax ≈ g.tax rtol = 1e-9
    end
end

@testset "share market: forward valuation, yield spread, control floor, debt retirement" begin
    MK = (; OWN..., forward_valuation = true)
    m = create_bread_economy(SimulationParameters(; seed = 1, MK...))
    e = first(x for x in B.enterprises(m, :farm) if x.ownership == :shareholders)
    @test B.forward_value_per_unit(m, e, 0.01) >= 0                       # never negative, even for a firm in debt
    for _ in 1:12; B.econo_step!(m, 1); end
    v_low = B.forward_value_per_unit(m, e, 0.005); v_high = B.forward_value_per_unit(m, e, 0.02)
    @test v_low >= v_high                                                 # a lower required yield values the same firm higher
    @test B.forward_value_per_unit(m, e, 0.01; growth = 0.005) >= B.forward_value_per_unit(m, e, 0.01)   # the resale term raises it
    # no spread → identical valuations → no voluntary trades under SuMSy (debt founders still sell to retire dearer loans)
    ds = round_data(run(; seed = 2, maximum_rounds = 25, MK..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01))
    @test sum(ds.share_trades) == 0
    dd = round_data(run(; seed = 2, maximum_rounds = 25, MK...))
    @test sum(dd.share_trades) > 0 && dd.founder_debt[end] < dd.founder_debt[1]
    # a spread makes a market, and the founders never fall below the control floor
    for kw in [(; MK..., required_yield_dispersion = 0.003), (; MK..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01, required_yield_dispersion = 0.003)]
        m2 = run(; seed = 3, maximum_rounds = 30, kw...); d2 = round_data(m2)
        @test sum(d2.share_trades) > 0
        @test abs(money_identity_gap(m2)) < 1e-6
        @test all(abs(sum(values(x.shares)) - 100) < 1e-6 for x in B.alive_agents(m2) if x isa Enterprise && x.ownership == :shareholders)   # shares are conserved
        @test abs(money_identity_gap(m2)) < 1e-6
    end
    # the control floor: one market call with a keen, cash-rich buyer and founders above the floor sells down to 51 and no further
    m4 = create_bread_economy(SimulationParameters(; seed = 4, MK..., required_yield_dispersion = 0.003)); for _ in 1:20; B.econo_step!(m4, 1); end
    firms4 = [x for x in B.alive_agents(m4) if x isa Enterprise && x.ownership == :shareholders && B.forward_value_per_unit(m4, x, 0.01) > 0]
    e4 = firms4[argmax([B.forward_value_per_unit(m4, x, 0.01) for x in firms4])]     # the firm worth the most: a keen buyer will want it
    for f in e4.founder_ids; e4.shares[f] = 50.0; end; for k in collect(keys(e4.shares)); k in e4.founder_ids || delete!(e4.shares, k); end   # founders back at 100 for a clean test
    buyer = first(w for w in B.persons(m4) if !(w.id in e4.founder_ids)); buyer.required_yield = 0.002; B.book_asset!(buyer.balance, B.DEPOSIT, 5000.0)
    B.share_market!(m4)
    @test 51 - 1e-6 <= B.founders_stake(e4) < 100                        # sold, but never below the floor
    B.share_market!(m4); @test B.founders_stake(e4) >= 51 - 1e-6           # and a second call adds nothing below it
    # yields are drawn only when a spread exists, so the random stream of a run without one is untouched
    m3 = create_bread_economy(SimulationParameters(; seed = 5, MK...)); @test all(w.required_yield == 0.01 for w in B.persons(m3))
end

@testset "deferred share payment: contract, collateral, seizure" begin
    DP = (; OWN..., forward_valuation = true, required_yield_dispersion = 0.003, deferred_payment = true)
    m = run(; seed = 1, maximum_rounds = 30, DP...); d = round_data(m)
    @test sum(d.share_trades_deferred) > 0                                # some purchases were financed by the seller
    @test all(haskey(m.share_collateral, l.id) for l in m.peer_loans if !l.settled && haskey(m.share_collateral, l.id))
    @test abs(money_identity_gap(m)) < 1e-6                               # no money is created by a deferred purchase
    # a hand-built contract in default: the pledged shares return to the seller in proportion to what is owed
    m2 = create_bread_economy(SimulationParameters(; seed = 1, DP...))
    e = first(x for x in B.enterprises(m2, :farm) if x.ownership == :shareholders)
    seller = B.persons(m2)[1]; buyer = B.persons(m2)[5]; bank = first(B.enterprises(m2, :bank))
    e.shares[seller.id] = 60.0; e.shares[buyer.id] = 40.0
    l = B.PeerLoan(length(m2.peer_loans) + 1, seller.id, buyer.id, bank.id, 100.0, 50.0, 5.0, 0.0, 0.0, false, 0, 2, true, false, 0.0)
    push!(m2.peer_loans, l); m2.share_collateral[l.id] = (e.id, 40.0)
    B.seize_shares_peer!(m2, l)
    @test l.settled && e.shares[seller.id] ≈ 80.0 && e.shares[buyer.id] ≈ 20.0   # half owed → half the pledged units go back
    @test !haskey(m2.share_collateral, l.id)
    # the rate: −1 % under SuMSy, +0.5 % under debt money unless set
    @test B.deferred_rate(m2) == 0.005
    ms = create_bread_economy(SimulationParameters(; seed = 1, DP..., SUM...)); @test B.deferred_rate(ms) == -0.01
end



@testset "shares scaled to the population; a 64-person village" begin
    V64 = (; BEH..., number_of_persons = 64, number_of_landowners = 16, land_per_person = 1.5, initial_production_target = 10, shares_per_person = 10,
             ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital, shareholder_count = 4)
    m = create_bread_economy(SimulationParameters(; seed = 1, V64...))
    @test B.total_share_units(m) == 640 && sum(w.land for w in B.persons(m)) == 96
    firms = [x for x in B.alive_agents(m) if x isa Enterprise && x.ownership == :shareholders]
    @test all(abs(sum(values(x.shares)) - 640) < 1e-6 for x in firms) && all(B.founders_stake(x) == 640 for x in firms)
    @test length(B.persons(m)) == 64 && count(w -> w.initial_landowner, B.persons(m)) == 16
    d = round_data(run(; seed = 1, maximum_rounds = 20, V64...))
    @test d.persons_alive[end] >= 60 && sum(d.share_trades) > 0 && d.founders_stake_pct[end] >= 51 - 1e-6
    @test abs(money_identity_gap(run(; seed = 2, maximum_rounds = 15, V64..., greed = true, greed_share = 0.5, greed_hoarding = 0.5))) < 1e-6   # greedy buyers use the same valuation and floor
end


@testset "unmet demand: a threshold, not a single miss (19 September 2026)" begin
    # a helper that builds a bakery market state directly
    function bakery_state(; share, sold, unmet)
        m = create_bread_economy(SimulationParameters(; seed = 1, BEH..., unmet_demand_share = share, maximum_rounds = 1))
        bs = B.enterprises(m, :bakery)
        for b in bs
            b.market[:bread].offered = sold / length(bs); b.market[:bread].sold = sold / length(bs)   # sold out
            b.market[:bread].unmet_demand = unmet > 0; b.market[:bread].unmet_units = unmet
        end
        return m, first(bs)
    end
    m, b = bakery_state(share = 0.0, sold = 100.0, unmet = 1.0)
    @test B.demand_unmet(m, b, :bread)                     # the original rule: one miss is enough
    m, b = bakery_state(share = 0.05, sold = 100.0, unmet = 1.0)
    @test !B.demand_unmet(m, b, :bread)                    # one in a hundred is noise at 5 %
    m, b = bakery_state(share = 0.05, sold = 100.0, unmet = 10.0)
    @test B.demand_unmet(m, b, :bread)                     # ten in a hundred and ten is not
    m, b = bakery_state(share = 0.10, sold = 100.0, unmet = 10.0)
    @test !B.demand_unmet(m, b, :bread)                    # 10 / 110 < 10 %
    m, b = bakery_state(share = 0.10, sold = 90.0, unmet = 10.0)
    @test B.demand_unmet(m, b, :bread)                     # exactly 10 %
    m, b = bakery_state(share = 0.05, sold = 100.0, unmet = 0.0)
    @test !B.demand_unmet(m, b, :bread)
    # wages keep the original rule whatever the threshold
    w = first(B.persons(m)); w.market[:wage].unmet_demand = true; w.market[:wage].unmet_units = 0.0
    @test B.demand_unmet(m, w, :wage)
    # the ask reacts through the same test
    m, b = bakery_state(share = 0.05, sold = 100.0, unmet = 1.0)
    ask0 = b.ask[:bread]; B.adapt_prices!(m)
    @test b.ask[:bread] == ask0
    m, b = bakery_state(share = 0.05, sold = 100.0, unmet = 10.0)
    ask0 = b.ask[:bread]; B.adapt_prices!(m)
    @test b.ask[:bread] > ask0
    # the shortfall is counted in units: in a run the units recorded are never less than the misses that set the flag
    m = run(; seed = 1, maximum_rounds = 10, BEH..., unmet_demand_share = 0.05)
    @test abs(money_identity_gap(m)) < 1e-6
    # the default reproduces the previous behaviour exactly
    a = round_data(run(; seed = 3, maximum_rounds = 20, BEH...))
    b0 = round_data(run(; seed = 3, maximum_rounds = 20, BEH..., unmet_demand_share = 0.0))
    @test a.price_bread == b0.price_bread && a.money_in_circulation == b0.money_in_circulation
end


@testset "theatre capacity: shows and seats (20 September 2026)" begin
    ENT = (; BEH..., entertainment = true, number_of_theatres = 2)
    m = create_bread_economy(SimulationParameters(; seed = 1, ENT..., maximum_rounds = 1))
    t = first(B.enterprises(m, :theatre))
    @test B.ticket_capacity(m, t) == Inf                                   # default: unlimited, as before
    m1 = create_bread_economy(SimulationParameters(; seed = 1, ENT..., shows_per_round = 1, maximum_rounds = 1))
    t1 = first(B.enterprises(m1, :theatre))
    @test B.ticket_capacity(m1, t1) == 16.0                                # one show, a seat for everyone
    @test B.theatre_labour_cap(m1, t1) == ceil(16 / B.parameters(m1).customers_per_labour_unit)
    m2 = create_bread_economy(SimulationParameters(; seed = 1, ENT..., shows_per_round = 3, seats_per_show = 10, maximum_rounds = 1))
    @test B.ticket_capacity(m2, first(B.enterprises(m2, :theatre))) == 30.0
    # in a run the cap binds: no theatre ever offers more tickets or plans more labour than its seats take
    m3 = run(; seed = 1, maximum_rounds = 30, ENT..., shows_per_round = 1, greed = true, greed_share = 1.0, greed_hoarding = 0.5)
    for t in B.enterprises(m3, :theatre)
        @test t.production_target <= B.theatre_labour_cap(m3, t)
        @test t.market[:ticket].offered <= B.ticket_capacity(m3, t) + 1e-9
    end
    d = round_data(m3)
    @test maximum(d.theatre_labour) <= 2 * ceil(16 / B.parameters(m3).customers_per_labour_unit) + 1e-9   # both theatres may have closed by then
    @test abs(money_identity_gap(m3)) < 1e-6
    # the default reproduces the previous behaviour exactly
    a = round_data(run(; seed = 3, maximum_rounds = 20, ENT...))
    b = round_data(run(; seed = 3, maximum_rounds = 20, ENT..., shows_per_round = 0, seats_per_show = 0))
    @test a.tickets_sold == b.tickets_sold && a.price_bread == b.price_bread
end


@testset "ask floor at cost and the unsold share (20 September 2026)" begin
    give!(a, amount) = B.book_asset!(a.balance, B.DEPOSIT, amount)
    m = create_bread_economy(SimulationParameters(; seed = 1, BEH..., ask_floor = :cost, maximum_rounds = 1))
    b = first(B.enterprises(m, :bakery))
    cost = B.seller_reservation(m, b, :bread)
    @test cost > 0
    # the floor is the cost, plus the markup while the reserve is not full
    give!(b, 1.0 - B.cash(b))                                  # reserve not full: the markup applies
    @test B.cash(b) < B.reserve_target(m, b)
    @test isapprox(B.ask_floor(m, b, :bread), cost * (1 + B.parameters(m).ask_floor_markup_when_short); rtol = 1e-9)
    give!(b, 10_000.0)
    @test isapprox(B.ask_floor(m, b, :bread), cost; rtol = 1e-9)
    # a decayed ask is lifted back to the floor after adaptation, and never below it in a run
    b.ask[:bread] = 0.1; b.market[:bread].offered = 10.0; b.market[:bread].sold = 5.0
    B.adapt_prices!(m)
    @test b.ask[:bread] >= cost - 1e-9
    mr = run(; seed = 1, maximum_rounds = 30, BEH..., entertainment = true, number_of_theatres = 2, greed = true, greed_share = 1.0, greed_hoarding = 0.5, shows_per_round = 1, ask_floor = :cost)
    for bk in B.enterprises(mr, :bakery)
        @test bk.ask[:bread] >= B.seller_reservation(mr, bk, :bread) - 1e-6
    end
    @test abs(money_identity_gap(mr)) < 1e-6
    # unsold share: two loaves of two hundred no longer cut the ask at 5 %; twenty do
    function bakery_unsold(share, offered, sold)
        mm = create_bread_economy(SimulationParameters(; seed = 1, BEH..., unsold_share = share, maximum_rounds = 1))
        bb = first(B.enterprises(mm, :bakery)); give!(bb, 10_000.0)
        bb.market[:bread].offered = offered; bb.market[:bread].sold = sold
        a0 = bb.ask[:bread]; B.adapt_prices!(mm); return bb.ask[:bread] / a0
    end
    @test bakery_unsold(0.0, 200.0, 197.0) < 1.0          # the old rule: 3 unsold > 2 units → cut
    @test bakery_unsold(0.05, 200.0, 197.0) == 1.0        # 1.5 % unsold: no cut at 5 %
    @test bakery_unsold(0.05, 200.0, 180.0) < 1.0         # 10 % unsold: cut
    @test bakery_unsold(0.10, 200.0, 181.0) == 1.0        # 9.5 %: no cut at 10 %
    # defaults reproduce the previous behaviour exactly
    a = round_data(run(; seed = 3, maximum_rounds = 20, BEH...))
    b0 = round_data(run(; seed = 3, maximum_rounds = 20, BEH..., ask_floor = :none, unsold_share = 0.0))
    @test a.price_bread == b0.price_bread && a.money_in_circulation == b0.money_in_circulation
end


@testset "equilibrium start: the stock begins inside its bounds and stays there (20 September 2026)" begin
    SU = (; BEH..., SUM..., demurrage_tax_rate = 0.01)
    p = SimulationParameters(; seed = 1, SU..., start_at_saturation = :equilibrium, initial_price_multiplier = 1.35, maximum_rounds = 40)
    m = create_bread_economy(p)
    per = p.demurrage_free_buffer + p.guaranteed_income / (p.demurrage_rate + p.demurrage_tax_rate)
    @test all(B.cash(w) >= per - 1e-6 for w in B.persons(m)) && allequal(round.(B.cash(w) for w in B.persons(m); digits = 6))
    d = round_data(B.run_simulation!(m))
    # no transient: the stock stays within a quarter of its starting level, where a norm start rises by more than half
    @test all(0.75 .* d.money_in_circulation[1] .<= d.money_in_circulation .<= 1.25 .* d.money_in_circulation[1])
    dn = round_data(run(; seed = 1, SU..., maximum_rounds = 40))
    @test dn.money_in_circulation[end] > 1.5 * dn.money_in_circulation[1]
    @test abs(money_identity_gap(m)) < 1e-6
    # the equilibrium stock is below :upper, above :lower
    mu = create_bread_economy(SimulationParameters(; seed = 1, SU..., start_at_saturation = :upper, maximum_rounds = 1))
    @test sum(B.cash(w) for w in B.persons(m)) < sum(B.cash(w) for w in B.persons(mu))
end


@testset "government reserve: n rounds of expected spending, surplus redistributed or taxed away (20 September 2026)" begin
    SU = (; BEH..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01)
    # off: the government hoards (the rule until now)
    d0 = round_data(run(; seed = 1, maximum_rounds = 60, SU...))
    @test d0.government_cash[end] > 10 * d0.government_outlay[end]
    @test all(d0.tax_scale .== 1.0) && sum(d0.surplus_redistributed) == 0.0
    # redistribution only: the reserve tracks the target, the surplus reaches the villagers
    d1 = round_data(run(; seed = 1, maximum_rounds = 60, SU..., government_reserve_in_rounds = 3, surplus_redistribution_share = 1.0))
    late = d1[d1.round .> 20, :]
    @test all(late.government_cash .<= late.government_reserve_target .+ late.government_outlay .* 1.5 .+ 1e-6)   # never far above target
    @test sum(d1.surplus_redistributed) > 0 && all(d1.tax_scale .== 1.0)
    @test d1.government_cash[end] < 0.5 * d0.government_cash[end]
    # tax reduction only: the scale falls, the reserve still tracks the target
    d2 = round_data(run(; seed = 1, maximum_rounds = 60, SU..., government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0))
    @test minimum(d2.tax_scale) < 1.0 && sum(d2.surplus_redistributed) == 0.0
    @test d2.government_cash[end] < 0.5 * d0.government_cash[end]
    # both halves: still bounded
    d3 = round_data(run(; seed = 1, maximum_rounds = 60, SU..., government_reserve_in_rounds = 3, surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5))
    @test d3.government_cash[end] < 0.5 * d0.government_cash[end] && sum(d3.surplus_redistributed) > 0 && minimum(d3.tax_scale) < 1.0
    # the mechanics on a prepared state: 100 above target, half redistributed equally to the living
    m = create_bread_economy(SimulationParameters(; seed = 1, SU..., government_reserve_in_rounds = 1, surplus_redistribution_share = 0.5, maximum_rounds = 1))
    gov = B.government(m); B.book_asset!(gov.balance, B.DEPOSIT, 100.0)
    m.government_outlay_this_round = 0.0                                # no spending on record: target 0, surplus 100
    before = [B.cash(w) for w in B.persons(m)]
    B.manage_government_reserve!(m)
    gains = [B.cash(w) for w in B.persons(m)] .- before
    @test isapprox(sum(gains), 50.0; atol = 1e-3) && allequal(round.(gains; digits = 4))
    @test isapprox(B.cash(gov), 50.0; atol = 1e-3)
    # the scale lowers every tax: wage, capital and demurrage tax
    md = create_bread_economy(SimulationParameters(; seed = 1, BEH..., wage_tax_rate = 0.2, capital_tax_rate = 0.2, maximum_rounds = 1))
    @test isapprox(B.wage_tax_amount(md, 100.0), 20.0; atol = 1e-9)
    md.tax_scale = 0.5
    @test isapprox(B.wage_tax_amount(md, 100.0), 10.0; atol = 1e-9)
    # identity, both systems
    @test abs(money_identity_gap(run(; seed = 1, maximum_rounds = 20, SU..., government_reserve_in_rounds = 3, surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5))) < 1e-6
    @test abs(money_identity_gap(run(; seed = 1, maximum_rounds = 20, BEH..., government_reserve_in_rounds = 3, surplus_redistribution_share = 0.5, surplus_tax_reduction_share = 0.5))) < 1e-6
    # default reproduces the previous behaviour exactly
    a = round_data(run(; seed = 3, maximum_rounds = 20, SU...)); b = round_data(run(; seed = 3, maximum_rounds = 20, SU..., government_reserve_in_rounds = 0))
    @test a.money_in_circulation == b.money_in_circulation && a.government_cash == b.government_cash
end


@testset "fiscal policy: incremental raises on a shortfall, cuts on a surplus, scale or brackets (20 September 2026)" begin
    give!(a, amount) = B.book_asset!(a.balance, B.DEPOSIT, amount)
    POL = (; BEH..., government_employment_share = 0.1, government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0)
    # a prepared state: revenue 50 a round against outlays 100 and no reserve → a shortfall; the scale rises, by at most the step
    m = create_bread_economy(SimulationParameters(; seed = 1, POL..., tax_policy = :scale, tax_response_coverage = 1.0, tax_response_step = 0.02, maximum_rounds = 1))
    m.government_outlay_this_round = 100.0; m.tax_this_round = 50.0
    B.manage_government_reserve!(m)
    @test isapprox(m.tax_scale, 1.02; atol = 1e-9)                        # wanted +100 % of revenue, allowed 2 %
    @test m.tax_shortfall > 0 && m.tax_policy_step == 0.02
    # a surplus cuts, also step-limited
    m2 = create_bread_economy(SimulationParameters(; seed = 1, POL..., tax_policy = :scale, tax_response_step = 0.05, maximum_rounds = 1))
    give!(B.government(m2), 5_000.0); m2.government_outlay_this_round = 10.0; m2.tax_this_round = 10.0
    B.manage_government_reserve!(m2)
    @test isapprox(m2.tax_scale, 0.95; atol = 1e-9) && m2.tax_policy_step == -0.05
    # coverage sizes the raise when the step does not bind
    m3 = create_bread_economy(SimulationParameters(; seed = 1, POL..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 1.0, maximum_rounds = 1))
    m3.government_outlay_this_round = 100.0; m3.tax_this_round = 80.0      # shortfall 20 + reserve gap 300/3 = 120; half = 60 = 75 % of revenue
    B.manage_government_reserve!(m3)
    @test isapprox(m3.tax_scale, 1.75; atol = 1e-6)
    # brackets: proportional, so the 50 % bracket moves five times the 10 % one; plus the fixed points
    mb = create_bread_economy(SimulationParameters(; seed = 1, POL..., income_tax_schedule = :progressive, tax_bracket_rates = [0.10, 0.20, 0.50],
                                                    tax_policy = :brackets, tax_response_coverage = 1.0, tax_response_step = 0.10, bracket_fixed_rise = 0.01, maximum_rounds = 1))
    mb.government_outlay_this_round = 100.0; mb.tax_this_round = 50.0
    B.manage_government_reserve!(mb)
    @test all(isapprox.(mb.bracket_rates, [0.10 * 1.1 + 0.01, 0.20 * 1.1 + 0.01, 0.50 * 1.1 + 0.01]; atol = 1e-9))
    @test isapprox(mb.bracket_rates[3] - 0.50 - 0.01, 5 * (mb.bracket_rates[1] - 0.10 - 0.01); atol = 1e-9)
    # ... and the schedule is not scaled a second time under :brackets: the scale moved, the wage tax follows the brackets only
    @test mb.tax_scale > 1.0
    mb_ref = create_bread_economy(SimulationParameters(; seed = 1, POL..., income_tax_schedule = :progressive, tax_bracket_rates = copy(mb.bracket_rates), maximum_rounds = 1))
    @test isapprox(B.wage_tax_amount(mb, 100.0), B.wage_tax_amount(mb_ref, 100.0); rtol = 1e-9)
    # a cut moves the brackets down, never below zero, and the statutory rates are untouched
    mb.tax_this_round = 10.0; mb.government_outlay_this_round = 0.0; give!(B.government(mb), 5_000.0)
    before = copy(mb.bracket_rates); B.manage_government_reserve!(mb)
    @test all(mb.bracket_rates .< before) && all(mb.bracket_rates .>= 0.0)
    @test B.parameters(mb).tax_bracket_rates == [0.10, 0.20, 0.50]
    # the multiplier reaches the wage tax withheld at source (flat schedule) and the effective rate workers reason with
    mf = create_bread_economy(SimulationParameters(; seed = 1, BEH..., wage_tax_rate = 0.15, clearing = false, maximum_rounds = 1))   # immediate settlement: the tax is booked at once
    e = first(B.enterprises(mf, :bakery)); w = first(B.persons(mf)); B.book_asset!(e.balance, B.DEPOSIT, 1_000.0)
    t0 = B.government(mf).tax_collected; B.pay_income!(mf, e, w, 100.0, :wage); t1 = B.government(mf).tax_collected
    mf.tax_scale = 2.0; w2 = B.persons(mf)[2]
    B.pay_income!(mf, e, w2, 100.0, :wage); t2 = B.government(mf).tax_collected
    @test isapprox(t1 - t0, 15.0; atol = 1e-6) && isapprox(t2 - t1, 30.0; atol = 1e-6)
    @test isapprox(B.effective_wage_tax_rate(mf), 0.30; atol = 1e-9)
    # in the debt village a run with the policy on raises the scale and shrinks the deficit; identity holds
    d0 = round_data(run(; seed = 1, maximum_rounds = 60, POL...))
    d1 = round_data(run(; seed = 1, maximum_rounds = 60, POL..., tax_policy = :scale, tax_response_coverage = 0.5, tax_response_step = 0.02))
    @test d1.tax_scale[end] > 1.0
    @test sum(d1.tax[end-9:end]) > sum(d0.tax[end-9:end])          # more revenue; whether the deficit shrinks is a result, not an invariant
    @test all(abs.(diff(d1.tax_scale) ./ d1.tax_scale[1:end-1]) .<= 0.02 + 1e-9)     # never more than the step in a round
    m4 = run(; seed = 1, maximum_rounds = 30, POL..., income_tax_schedule = :progressive, tax_policy = :brackets, tax_response_coverage = 0.5, tax_response_step = 0.02)
    @test abs(money_identity_gap(m4)) < 1e-6 && round_data(m4).bracket_top_rate[end] > B.parameters(m4).tax_bracket_rates[end]
    # default: nothing moves
    dd = round_data(run(; seed = 3, maximum_rounds = 20, BEH...))
    @test all(dd.tax_scale .== 1.0) && all(dd.tax_policy_step .== 0.0)
end


@testset "the operating result exists without clearing, so the share market can trade (20 September 2026)" begin
    MK = (; BEH..., ownership = :shareholders, share_market = true, forward_valuation = true, required_yield_dispersion = 0.002, startup_financing = :paid_in_capital)
    on = round_data(run(; seed = 1, maximum_rounds = 30, MK...))
    off = round_data(run(; seed = 1, maximum_rounds = 30, MK..., clearing = false))
    @test sum(on.share_trades) > 0
    @test sum(off.share_trades) > 0                       # was 0 in every round: net_history stayed at zero without clearing
    m = run(; seed = 1, maximum_rounds = 10, MK..., clearing = false)                 # net_history is kept for owned firms
    @test any(e -> e isa Enterprise && any(!=(0.0), e.net_history), B.alive_agents(m))
    @test abs(money_identity_gap(m)) < 1e-6
end


@testset "consumption tax: paid by the buyer, booked as revenue, scaled by the policy, mixed by share (20 September 2026)" begin
    give!(a, amount) = B.book_asset!(a.balance, B.DEPOSIT, amount)
    # the buyer pays price plus tax; the seller gets the price; the government the tax (immediate settlement to see it at once)
    m = create_bread_economy(SimulationParameters(; seed = 1, BEH..., consumption_tax_rate = 0.06, clearing = false, maximum_rounds = 1))
    w = first(B.persons(m)); s = first(B.enterprises(m, :bakery)); gov = B.government(m)
    give!(w, 100.0); c0 = (B.cash(w), B.cash(s), B.cash(gov), gov.tax_collected)
    paid = B.pay_consumption!(m, w, s, 10.0, :bread)
    @test isapprox(paid, 10.6; atol = 1e-9)
    @test isapprox(c0[1] - B.cash(w), 10.6; atol = 1e-6) && isapprox(B.cash(s) - c0[2], 10.0; atol = 1e-6) && isapprox(B.cash(gov) - c0[3], 0.6; atol = 1e-6)
    @test isapprox(gov.tax_collected - c0[4], 0.6; atol = 1e-6) && isapprox(m.consumption_tax_this_round, 0.6; atol = 1e-9)
    # an enterprise buying is not taxed; a zero rate changes nothing
    b = first(B.enterprises(m, :bakery)); f = first(B.enterprises(m, :farm)); give!(b, 100.0)
    @test B.pay_consumption!(m, b, f, 10.0, :grain) == 10.0
    @test B.gross_price(m, w, 10.0) == 10.6 && B.gross_price(m, b, 10.0) == 10.0
    # willingness to pay is gross: the ceiling handed to the seller is divided by 1 + rate
    m0 = create_bread_economy(SimulationParameters(; seed = 1, BEH..., maximum_rounds = 1))
    @test isapprox(B.buyer_reservation(m, w, :bread) * 1.06, B.buyer_reservation(m0, first(B.persons(m0)), :bread); rtol = 1e-9)
    # the policy scales it with the same triggers; without a mix target it follows the income scale
    mp = create_bread_economy(SimulationParameters(; seed = 1, BEH..., consumption_tax_rate = 0.06, government_reserve_in_rounds = 3,
                                                    tax_policy = :scale, tax_response_coverage = 1.0, tax_response_step = 0.02, maximum_rounds = 1))
    mp.government_outlay_this_round = 100.0; mp.tax_this_round = 50.0; mp.consumption_tax_this_round = 10.0
    B.manage_government_reserve!(mp)
    @test isapprox(mp.tax_scale, 1.02; atol = 1e-9) && isapprox(mp.consumption_tax_scale, 1.02; atol = 1e-9)
    @test isapprox(B.consumption_tax_rate(mp), 0.06 * 1.02; atol = 1e-9)
    # the mix: shift by r × lever, then move by r. Revenue 50, outlay 100 → r = +0.02 (step)
    function mix_state(levers)
        mm = create_bread_economy(SimulationParameters(; seed = 1, BEH..., consumption_tax_rate = 0.06, wealth_tax_rate = 0.05, government_reserve_in_rounds = 3,
                                                        tax_policy = :scale, tax_response_coverage = 1.0, tax_response_step = 0.02, tax_levers = levers, maximum_rounds = 1))
        mm.government_outlay_this_round = 100.0; mm.tax_this_round = 50.0; mm.consumption_tax_this_round = 10.0; mm.wealth_tax_this_round = 5.0
        B.manage_government_reserve!(mm); return mm
    end
    me = mix_state((income = 0.0, consumption = 0.0, wealth = 0.0))                    # no levers: one scale
    @test isapprox(me.tax_scale, 1.02; atol = 1e-9) && isapprox(me.consumption_tax_scale, 1.02; atol = 1e-9) && isapprox(me.wealth_tax_scale, 1.02; atol = 1e-9)
    m1 = mix_state((income = 1.0, consumption = 0.0, wealth = 0.0))                    # income with the policy at the same rate: shift then move
    @test isapprox(m1.tax_scale, 1.02 * 1.02; atol = 1e-9) && isapprox(m1.consumption_tax_scale, 1.02; atol = 1e-9)
    mf = mix_state((income = -1.0, consumption = 0.0, wealth = 0.0))                   # −1 holds the family flat
    @test isapprox(mf.tax_scale, 0.98 * 1.02; atol = 1e-9)
    ms = mix_state((income = -2.0, consumption = 1.0, wealth = 0.0))                   # the burden shifts from income to consumption while the total rises
    @test isapprox(ms.tax_scale, 0.96 * 1.02; atol = 1e-9) && isapprox(ms.consumption_tax_scale, 1.02 * 1.02; atol = 1e-9) && isapprox(ms.wealth_tax_scale, 1.02; atol = 1e-9)
    @test ms.tax_scale < 1.0 < ms.consumption_tax_scale
    # on a surplus the policy cuts; the lever is a standing preference, so (−2, +1, 0) now cuts income hardest and consumption least
    mc = create_bread_economy(SimulationParameters(; seed = 1, BEH..., consumption_tax_rate = 0.06, wealth_tax_rate = 0.05, government_reserve_in_rounds = 3, surplus_tax_reduction_share = 1.0,
                                                    tax_policy = :scale, tax_response_step = 0.02, tax_levers = (income = -2.0, consumption = 1.0, wealth = 0.0), maximum_rounds = 1))
    give!(B.government(mc), 5_000.0); mc.government_outlay_this_round = 10.0; mc.tax_this_round = 50.0; mc.consumption_tax_this_round = 10.0; mc.wealth_tax_this_round = 5.0
    B.manage_government_reserve!(mc)
    @test mc.tax_policy_step == -0.02 && isapprox(mc.tax_scale, 0.96 * 0.98; atol = 1e-9) && isapprox(mc.consumption_tax_scale, 1.02 * 0.98; atol = 1e-9) && isapprox(mc.wealth_tax_scale, 0.98; atol = 1e-9)
    @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, BEH..., tax_levers = (income = NaN, consumption = 0.0, wealth = 0.0))
    # the wealth tax follows its own scale
    mwt = create_bread_economy(SimulationParameters(; seed = 1, BEH..., ownership = :shareholders, share_market = true, startup_financing = :paid_in_capital, wealth_tax_rate = 0.12, maximum_rounds = 1))
    for w in B.persons(mwt); give!(w, 1_000.0); end
    mwt.wealth_tax_scale = 2.0; base = sum(B.taxable_wealth(mwt, w) for w in B.persons(mwt)); g0 = B.cash(B.government(mwt))
    B.collect_wealth_tax!(mwt)
    @test isapprox(B.cash(B.government(mwt)) - g0, 0.02 * base; rtol = 1e-6)
    # runs: revenue appears, the identity holds, both systems; the default is bit-identical
    for kw in ((; BEH...), (; BEH..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01))
        d = round_data(run(; seed = 1, maximum_rounds = 20, kw..., consumption_tax_rate = 0.06))
        @test sum(d.consumption_tax) > 0 && all(d.consumption_tax_rate_now .== 0.06)
        mr = run(; seed = 1, maximum_rounds = 20, kw..., consumption_tax_rate = 0.06); @test abs(money_identity_gap(mr)) < 1e-6
    end
    a = round_data(run(; seed = 3, maximum_rounds = 20, BEH...)); c = round_data(run(; seed = 3, maximum_rounds = 20, BEH..., consumption_tax_rate = 0.0))
    @test a.price_bread == c.price_bread && a.money_in_circulation == c.money_in_circulation && sum(a.consumption_tax) == 0.0
    @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, BEH..., tax_levers = (income = Inf, consumption = 0.0, wealth = 0.0))
end


@testset "wealth tax on land and shares at book value (20 September 2026)" begin
    give!(a, amount) = B.book_asset!(a.balance, B.DEPOSIT, amount)
    MK = (; BEH..., ownership = :shareholders, share_market = true, startup_financing = :paid_in_capital)
    m = create_bread_economy(SimulationParameters(; seed = 1, MK..., wealth_tax_rate = 0.12, maximum_rounds = 1))   # 1 % a round
    holder = first(w for w in B.persons(m) if any(e -> e isa Enterprise && e.ownership == :shareholders && get(e.shares, w.id, 0.0) > 0, B.alive_agents(m)))
    landowner = first(w for w in B.persons(m) if w.land > 0)
    # the base is land at the land price plus shares at book value per unit
    land_part = landowner.land * B.land_price(m)
    @test B.taxable_wealth(m, landowner) >= land_part - 1e-9
    e = first(x for x in B.alive_agents(m) if x isa Enterprise && x.ownership == :shareholders && get(x.shares, holder.id, 0.0) > 0)
    give!(e, 1_000.0)                                                       # book value up, so the holder's base rises with it
    before = B.taxable_wealth(m, holder)
    give!(e, 1_000.0)
    @test isapprox(B.taxable_wealth(m, holder) - before, 1_000.0 * get(e.shares, holder.id, 0.0) / B.total_share_units(m); rtol = 1e-9)
    # collection: one twelfth of 12 % on the base, in cash, to the government
    for w in B.persons(m); give!(w, 1_000.0); end
    gov = B.government(m); g0 = B.cash(gov); base = sum(B.taxable_wealth(m, w) for w in B.persons(m))
    B.collect_wealth_tax!(m)
    @test isapprox(B.cash(gov) - g0, 0.01 * base; rtol = 1e-6) && isapprox(m.wealth_tax_this_round, 0.01 * base; rtol = 1e-6)
    @test all(w.wealth_tax_arrears == 0.0 for w in B.persons(m))
    # arrears: a person without cash owes it next round and pays it first when cash arrives
    m2 = create_bread_economy(SimulationParameters(; seed = 1, MK..., wealth_tax_rate = 0.12, maximum_rounds = 1))
    w2 = first(w for w in B.persons(m2) if w.land > 0); give!(w2, -B.cash(w2))
    B.collect_wealth_tax!(m2)
    owed = w2.wealth_tax_arrears; @test owed > 0
    give!(w2, 1_000.0); B.collect_wealth_tax!(m2)
    @test w2.wealth_tax_arrears == 0.0
    # the income scale does not move it; only its own scale does (see the mix tests)
    m3 = create_bread_economy(SimulationParameters(; seed = 1, MK..., wealth_tax_rate = 0.12, maximum_rounds = 1))
    for w in B.persons(m3); give!(w, 1_000.0); end
    m3.tax_scale = 2.0; base3 = sum(B.taxable_wealth(m3, w) for w in B.persons(m3)); g3 = B.cash(B.government(m3))
    B.collect_wealth_tax!(m3)
    @test isapprox(B.cash(B.government(m3)) - g3, 0.01 * base3; rtol = 1e-6)
    # runs in both systems: revenue, identity; default bit-identical
    for kw in ((; MK...), (; MK..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01))
        mr = run(; seed = 1, maximum_rounds = 20, kw..., wealth_tax_rate = 0.05)
        @test sum(round_data(mr).wealth_tax) > 0 && abs(money_identity_gap(mr)) < 1e-6
    end
    a = round_data(run(; seed = 3, maximum_rounds = 20, MK...)); c = round_data(run(; seed = 3, maximum_rounds = 20, MK..., wealth_tax_rate = 0.0))
    @test a.price_bread == c.price_bread && a.money_in_circulation == c.money_in_circulation
end

@testset "cooperative forms (14 September 2026)" begin
    give!(a, amount) = B.book_asset!(a.balance, B.DEPOSIT, amount)
    params(m) = B.parameters(m)
    events(m) = [e for e in B.abmproperties(m)[:events]]
    WORK = (; OWN..., cooperative_form_farms = :worker, cooperative_form_bakeries = :worker)
    CONS = (; OWN..., cooperative_form_bakeries = :consumer, cooperative_farms = 0)
    THEA = (; OWN..., number_of_theatres = 2, cooperative_theatres = 1)

    @testset "parameters are validated, not silently ignored" begin
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., cooperative_form_farms = :consumer)
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., cooperative_form_bakeries = :syndicate)
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., number_of_theatres = 1, cooperative_theatres = 2)
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., retained_surplus_share = 1.0)
    end

    @testset "the form is set per kind, and theatres can now be cooperatives" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, THEA..., cooperative_form_theatres = :consumer))
        ts = B.enterprises(m, :theatre)
        @test count(t -> t.ownership == :cooperative, ts) == 1 && count(t -> t.ownership == :shareholders, ts) == 1
        @test B.coop_form(m, first(t for t in ts if t.ownership == :cooperative)) == :consumer
        @test B.coop_form(m, first(t for t in ts if t.ownership == :shareholders)) == :none
        # the default leaves every theatre for profit, as before 14 September
        m0 = create_bread_economy(SimulationParameters(; seed = 1, OWN..., number_of_theatres = 2))
        @test all(t.ownership == :shareholders for t in B.enterprises(m0, :theatre))
    end

    @testset "worker cooperative: membership follows employment, capital out of wages" begin
        m = run(; seed = 1, maximum_rounds = 25, WORK...)
        coops = [e for e in B.alive_agents(m) if e isa Enterprise && B.coop_form(m, e) == :worker]
        @test !isempty(coops)
        @test any(!isempty(e.members) for e in coops)
        # nobody is a member without having worked there, and every member has an admission round
        for e in coops, id in keys(e.members)
            @test haskey(e.member_since, id)
            @test B.patronage_total(e, id) > 0 || e.member_since[id] >= B.current_round(m) - params(m).patronage_window
        end
        # the share is collected out of wages: capital paid in, and never more than par per member
        par = params(m).membership_share_price
        @test sum(e.paid_in_capital for e in coops) > 0
        for e in coops
            @test e.paid_in_capital <= par * length(e.members) + 1e-6
            @test all(0.0 <= u <= par + 1e-9 for u in values(e.membership_unpaid))
        end
        d = round_data(m)
        @test sum(d.membership_capital) > 0 && sum(d.coop_worker_hours) > 0
    end

    @testset "worker cooperative: members are served first and the work is spread over them" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, WORK..., maximum_rounds = 1))
        # run a few rounds so that memberships exist, then inspect one allocation
        m = run(; seed = 1, maximum_rounds = 12, WORK...)
        coops = [e for e in B.alive_agents(m) if e isa Enterprise && B.coop_form(m, e) == :worker && length(e.members) >= 2]
        @test !isempty(coops)
        e = first(coops)
        working = [id for (id, u) in e.patronage_this_round if u > 1e-9]
        # spreading: when the cooperative needs less than its members' total capacity, more than one member works
        capacity = sum(model_person.capacity for model_person in B.persons(m) if haskey(e.members, model_person.id))
        if B.labour_need(e) < capacity - 1e-9 && length(e.members) >= 2 && !isempty(working)
            @test length(working) >= 2
        end
        # no member works more than their own capacity through the cooperative
        for (id, u) in e.patronage_this_round
            @test u <= m[id].capacity + 1e-6
        end
        # the switch turns the whole stage off
        m2 = run(; seed = 1, maximum_rounds = 12, WORK..., members_first_hiring = false)
        d2 = round_data(m2)
        @test d2.reserved_labour[end] == 0.0
    end

    @testset "worker cooperative: bakery members reserve capacity for the later stage" begin
        d = round_data(run(; seed = 1, maximum_rounds = 20, WORK...))
        @test sum(d.reserved_labour) > 0                      # bakeries hire after the grain market
        dfarm = round_data(run(; seed = 1, maximum_rounds = 20, WORK..., cooperative_form_bakeries = :member))
        @test sum(dfarm.reserved_labour) == 0                 # farms hire in the first stage: nothing to reserve
    end

    @testset "patronage: distribution proportional to hours, a share retained" begin
        p = SimulationParameters(; seed = 1, WORK..., maximum_rounds = 3)
        m = create_bread_economy(p)
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        ws = B.persons(m)[1:3]
        for (k, w) in enumerate(ws)                            # 1, 2 and 3 hours in the window
            e.members[w.id] = 1; e.member_since[w.id] = 1
            push!(e.patronage_log, Dict(w.id => Float64(k)))
        end
        give!(e, 1000.0)
        before = [B.cash(w) for w in ws]
        paid = B.distribute_patronage!(m, e, 100.0)
        @test isapprox(e.retained_reserve, 25.0; atol = 1e-6)  # retained_surplus_share = 0.25
        @test isapprox(paid, 75.0; atol = 1e-3)
        gains = [B.cash(w) - b for (w, b) in zip(ws, before)]
        @test all(g > 0 for g in gains)
        @test isapprox(gains[3] / gains[1], 3.0; rtol = 1e-3)  # three hours against one
        @test isapprox(gains[2] / gains[1], 2.0; rtol = 1e-3)
        @test isapprox(e.rebate_per_unit, 0.5 * 75.0 / 6.0; atol = 1e-6)
    end

    @testset "worker patronage is wage income, consumer rebate is untaxed" begin
        pw = SimulationParameters(; seed = 1, WORK..., wage_tax_rate = 0.5, maximum_rounds = 3)
        mw = create_bread_economy(pw)
        ew = first(x for x in B.alive_agents(mw) if x isa Enterprise && B.coop_form(mw, x) == :worker)
        w = first(B.persons(mw)); ew.members[w.id] = 1; ew.member_since[w.id] = 1
        push!(ew.patronage_log, Dict(w.id => 1.0))
        give!(ew, 1000.0)
        gov_before = B.cash(B.government(mw)); before = B.cash(w)
        B.distribute_patronage!(mw, ew, 100.0)
        @test B.cash(B.government(mw)) - gov_before > 0          # taxed on the wage schedule
        @test isapprox((B.cash(w) - before) + (B.cash(B.government(mw)) - gov_before), 75.0; atol = 1e-3)
        @test w.labour_income > 0

        pc = SimulationParameters(; seed = 1, CONS..., wage_tax_rate = 0.5, maximum_rounds = 3)
        mc = create_bread_economy(pc)
        ec = first(x for x in B.alive_agents(mc) if x isa Enterprise && B.coop_form(mc, x) == :consumer)
        c = first(B.persons(mc)); ec.members[c.id] = 1; ec.member_since[c.id] = 1
        push!(ec.patronage_log, Dict(c.id => 1.0))
        give!(ec, 1000.0)
        gov_before = B.cash(B.government(mc)); before = B.cash(c)
        B.distribute_patronage!(mc, ec, 100.0)
        @test isapprox(B.cash(c) - before, 75.0; atol = 1e-3)    # a price reduction: no tax
        @test isapprox(B.cash(B.government(mc)), gov_before; atol = 1e-9)
        @test c.rebate_income > 0 && c.labour_income == 0.0
    end

    @testset "the indivisible reserve is never distributed" begin
        m = run(; seed = 1, maximum_rounds = 30, WORK...)
        d = round_data(m)
        @test d.coop_retained_reserve[end] > 0
        @test all(diff(d.coop_retained_reserve) .>= -1e-6)     # monotone while the cooperatives are open
        for e in B.alive_agents(m)
            (e isa Enterprise && B.coop_form(m, e) == :worker) || continue
            @test B.distributable_floor(m, e) >= B.reserve_target(m, e) + e.retained_reserve - 1e-9
        end
    end

    @testset "consumer cooperative: membership follows purchases, rebate proportional" begin
        m = run(; seed = 1, maximum_rounds = 30, CONS...)
        coops = [e for e in B.alive_agents(m) if e isa Enterprise && B.coop_form(m, e) == :consumer]
        @test !isempty(coops) && any(!isempty(e.members) for e in coops)
        d = round_data(m)
        @test sum(d.rebates) > 0 && sum(d.rebate_income_persons) > 0
        @test sum(d.patronage_wages) == 0.0                   # a consumer cooperative pays no wage patronage
        joins = [x for x in events(m) if x.kind == :membership && get(x, :route, :none) == :purchase]
        @test !isempty(joins)
    end

    @testset "member price awareness nets the rebate off the ask" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, CONS..., maximum_rounds = 1))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :consumer)
        other = first(x for x in B.enterprises(m, :bakery) if x.ownership == :shareholders)
        w = first(B.persons(m))
        e.ask[:bread] = 10.0; other.ask[:bread] = 9.5; e.rebate_per_unit = 1.0
        @test B.member_ask(m, e, w, :bread) == 10.0           # not a member: the posted price
        e.members[w.id] = 1
        @test B.member_ask(m, e, w, :bread) == 9.0            # a member: net of the expected rebate
        @test B.member_ask(m, e, w, :bread) < B.member_ask(m, other, w, :bread)
        m2 = create_bread_economy(SimulationParameters(; seed = 1, CONS..., member_price_awareness = false, maximum_rounds = 1))
        e2 = first(x for x in B.alive_agents(m2) if x isa Enterprise && B.coop_form(m2, x) == :consumer)
        w2 = first(B.persons(m2)); e2.members[w2.id] = 1; e2.ask[:bread] = 10.0; e2.rebate_per_unit = 1.0
        @test B.member_ask(m2, e2, w2, :bread) == 10.0        # the switch is off
    end

    @testset "membership lapses when the patronage dries up" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, WORK..., membership_lapse_rounds_worker = 2, patronage_window = 3, maximum_rounds = 5))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        idle = B.persons(m)[1]; busy = B.persons(m)[2]
        for w in (idle, busy)
            e.members[w.id] = 1; e.member_since[w.id] = -5; e.membership_unpaid[w.id] = 0.0
            give!(w, 100.0)                                    # not in hardship, so only the lapse rule can redeem them
        end
        e.paid_in_capital = 2 * params(m).membership_share_price
        give!(e, 5_000.0)                                     # enough to redeem out of cash above the reserve
        for _ in 1:3; push!(e.patronage_log, Dict(busy.id => 2.0)); end
        B.manage_new_form_membership!(m)
        @test !haskey(e.members, idle.id)                     # no hours over the window: redeemed
        @test haskey(e.members, busy.id)
        @test B.cash(idle) >= params(m).membership_share_price - 1e-6
    end

    @testset "the asset lock sends the reserve to the public purse, not to an heir" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, WORK..., maximum_rounds = 3))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        w = first(B.persons(m)); e.members[w.id] = 1; e.member_since[w.id] = 1; e.membership_unpaid[w.id] = 0.0
        e.paid_in_capital = params(m).membership_share_price
        give!(e, 500.0)
        gov_before = B.cash(B.government(m)); member_before = B.cash(w)
        B.close_enterprise!(m, e, :test)
        @test isapprox(B.cash(w) - member_before, params(m).membership_share_price; atol = 1e-6)   # redeemed at par
        @test B.cash(B.government(m)) - gov_before > 0          # the rest is locked, not inherited
        @test B.cash(e) < 1e-6
    end

    @testset "symmetric founding calls on members instead of refusing credit" begin
        m = create_bread_economy(SimulationParameters(; seed = 1, WORK..., cooperative_founding = :symmetric, maximum_rounds = 3))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        w = first(B.persons(m)); e.members[w.id] = 1; e.member_since[w.id] = 1; e.membership_unpaid[w.id] = 0.0
        give!(w, 400.0)
        before = B.cash(e)
        @test B.request_loan!(m, e, 100.0, :test)             # answered by a capital call, not by bank credit
        @test isapprox(B.cash(e) - before, 100.0; atol = 1e-6) && isapprox(e.paid_in_capital, 100.0; atol = 1e-6)
        @test B.debt_of(e) == 0.0
        # with the same configuration and no members to call on, the cooperative is on its own
        m2 = run(; seed = 1, maximum_rounds = 15, WORK..., cooperative_founding = :symmetric)
        @test abs(money_identity_gap(m2)) < 1e-6
    end


    @testset "membership contribution: money, buffer, or a mix" begin
        SU = (; WORK..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01)
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., membership_contribution = :barter)
        @test_throws ArgumentError run(; seed = 1, maximum_rounds = 1, OWN..., membership_contribution = :buffer, membership_buffer_pledge = 0.0)

        # what is required of a joining member
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :money, maximum_rounds = 1))
        @test B.membership_requirement(m) == (params(m).membership_share_price, 0.0)
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :buffer, maximum_rounds = 1))
        @test B.membership_requirement(m) == (0.0, params(m).membership_buffer_pledge)
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :mixed_fixed, maximum_rounds = 1))
        @test B.membership_requirement(m) == (params(m).membership_share_price, params(m).membership_buffer_pledge)

        # a pledge moves the exemption and no money
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :buffer, membership_buffer_pledge = 12.0, maximum_rounds = 1))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        w = first(B.persons(m)); buffer0 = B.demurrage_buffer(m, w); coop0 = B.demurrage_buffer(m, e)
        money0 = B.cash(w)
        @test B.contribute_membership!(m, w, e)
        @test isapprox(B.cash(w), money0; atol = 1e-9)                       # nothing was paid
        @test isapprox(B.demurrage_buffer(m, w), buffer0 - 12.0; atol = 1e-6)
        @test isapprox(B.demurrage_buffer(m, e), coop0 + 12.0; atol = 1e-6)
        @test isapprox(e.buffer_pledged, 12.0; atol = 1e-6) && isapprox(w.buffer_pledged, 12.0; atol = 1e-6)
        # and it is given back on redemption
        give!(e, 500.0); B.redeem_membership!(m, e, w, :test)
        @test isapprox(B.demurrage_buffer(m, w), buffer0; atol = 1e-6) && isapprox(e.buffer_pledged, 0.0; atol = 1e-9)

        # the pledged exemption really does spare the cooperative demurrage
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :buffer, demurrage_free_buffer = 30.0, membership_buffer_pledge = 20.0, maximum_rounds = 1))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        other = first(x for x in B.enterprises(m, :bakery) if x.ownership == :shareholders)
        give!(e, 100.0); give!(other, 100.0)
        w = first(B.persons(m))
        @test B.contribute_membership!(m, w, e)
        B.apply_demurrage!(m)
        @test B.cash(e) > B.cash(other)                                       # same balance, less demurrage
        @test isapprox(100.0 - B.cash(other), (params(m).demurrage_rate + params(m).demurrage_tax_rate) * 100.0; atol = 1e-3)
        @test isapprox(100.0 - B.cash(e), (params(m).demurrage_rate + params(m).demurrage_tax_rate) * 80.0; atol = 1e-3)
        # a pledge bigger than the member's whole buffer cannot be given, so nobody joins on those terms
        m2 = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :buffer, demurrage_free_buffer = 30.0, membership_buffer_pledge = 40.0, maximum_rounds = 1))
        @test B.plan_contribution(m2, first(B.persons(m2))) === nothing

        # :mixed_fixed asks for both
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :mixed_fixed, maximum_rounds = 1))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        w = first(B.persons(m)); give!(w, 400.0); before = B.cash(w)
        @test B.contribute_membership!(m, w, e)
        @test isapprox(before - B.cash(w), params(m).membership_share_price; atol = 1e-6)
        @test isapprox(w.buffer_pledged, params(m).membership_buffer_pledge; atol = 1e-6)

        # :mixed_flexible — one total, the member chooses the split
        FLEX = (; SU..., membership_contribution = :mixed_flexible, membership_share_price = 10.0, membership_buffer_pledge = 10.0, demurrage_free_buffer = 30.0)
        m = create_bread_economy(SimulationParameters(; seed = 1, FLEX..., maximum_rounds = 1))
        w = first(B.persons(m))
        money, pledge = B.plan_contribution(m, w)                             # no cash: the idle buffer carries it
        @test isapprox(money + pledge * params(m).buffer_contribution_value, 20.0; atol = 1e-6)
        @test pledge > 0 && money == 0.0
        give!(w, 1_000.0)                                                     # cash-rich: the buffer is in use, so money carries it
        money2, pledge2 = B.plan_contribution(m, w)
        @test isapprox(money2 + pledge2 * params(m).buffer_contribution_value, 20.0; atol = 1e-6)
        @test money2 > money && pledge2 < pledge
        # the exchange rate is explicit, not assumed
        m2 = create_bread_economy(SimulationParameters(; seed = 1, FLEX..., buffer_contribution_value = 2.0, maximum_rounds = 1))
        w2 = first(B.persons(m2))
        money3, pledge3 = B.plan_contribution(m2, w2)
        @test isapprox(money3 + pledge3 * 2.0, 10.0 + 10.0 * 2.0; atol = 1e-6)

        # someone who can meet neither requirement does not join
        m = create_bread_economy(SimulationParameters(; seed = 1, SU..., membership_contribution = :mixed_fixed, membership_buffer_pledge = 1e6, maximum_rounds = 1))
        e = first(x for x in B.alive_agents(m) if x isa Enterprise && B.coop_form(m, x) == :worker)
        w = first(B.persons(m)); give!(w, 400.0)
        @test B.plan_contribution(m, w) === nothing
        @test !B.contribute_membership!(m, w, e) && isempty(e.members)

        # under debt money there is no demurrage to spare, so a pledge is worth nothing: none is collected and the
        # flexible requirement falls back to its money half alone (it is not converted into more money)
        m = create_bread_economy(SimulationParameters(; seed = 1, WORK..., membership_contribution = :mixed_flexible, maximum_rounds = 1))
        @test B.buffer_value(m) == 0.0
        w = first(B.persons(m)); give!(w, 400.0)
        money4, pledge4 = B.plan_contribution(m, w)
        @test pledge4 == 0.0 && isapprox(money4, params(m).membership_share_price; atol = 1e-6)
        m5 = create_bread_economy(SimulationParameters(; seed = 1, WORK..., membership_contribution = :buffer, maximum_rounds = 1))
        w5 = first(B.persons(m5))
        @test B.plan_contribution(m5, w5) == (0.0, 0.0)          # a buffer-only membership is free under debt money

        # whole runs: identity holds and members do turn up, in all four forms, in both systems
        for contribution in (:money, :buffer, :mixed_fixed, :mixed_flexible)
            m = run(; seed = 1, maximum_rounds = 20, SU..., membership_contribution = contribution)
            d = round_data(m)
            @test abs(money_identity_gap(m)) < 1e-6
            @test d.coop_members_worker[end] > 0
            @test (contribution == :money) == (d.coop_buffer_pledged[end] == 0.0)
            @test isapprox(d.coop_buffer_pledged[end], d.buffer_pledged_persons[end]; atol = 1e-6)   # the exemption is conserved
            @test abs(money_identity_gap(run(; seed = 1, maximum_rounds = 15, WORK..., membership_contribution = contribution))) < 1e-6
        end
    end

    @testset "money identity and survival hold in every new configuration" begin
        cases = [("worker, debt", (; WORK...)), ("worker, sumsy", (; WORK..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01)),
                 ("consumer, debt", (; CONS...)), ("consumer, sumsy", (; CONS..., SUM..., government_employment_share = 0.1, demurrage_tax_rate = 0.01)),
                 ("coop theatre", (; THEA..., cooperative_form_theatres = :consumer)),
                 ("worker + consumer + coop theatre", (; OWN..., number_of_theatres = 2, cooperative_theatres = 1,
                    cooperative_form_farms = :worker, cooperative_form_bakeries = :worker, cooperative_form_theatres = :consumer))]
        for (name, kw) in cases
            m = run(; seed = 1, maximum_rounds = 15, kw...)
            @test abs(money_identity_gap(m)) < 1e-6
            @test round_data(m).persons_alive[end] >= 14
        end
    end

    @testset "the :member form is untouched by the new machinery" begin
        a = round_data(run(; seed = 3, maximum_rounds = 20, OWN...))
        b = round_data(run(; seed = 3, maximum_rounds = 20, OWN..., patronage_window = 4, retained_surplus_share = 0.5,
                           capital_deduction_share = 0.5, members_first_hiring = false, member_price_awareness = false))
        @test a.money_in_circulation == b.money_in_circulation && a.gini_net_wealth_persons == b.gini_net_wealth_persons
        @test all(a.coop_retained_reserve .== 0.0) && sum(a.patronage_wages) == 0.0 && sum(a.rebates) == 0.0
    end
end

end
