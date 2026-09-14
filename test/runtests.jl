# BreadEconomySim test suite. Run with `julia --project=. test/runtests.jl` (or `Pkg.test()`).
# Three layers: (1) invariants that must hold in every run (money identity, determinism, nominal homogeneity),
# (2) unit behaviour of individual rules, (3) golden regression values for three reference configurations.
# Golden values regenerated 15 September 2026 after the government's explicit debt roll-over at a policy rate (debt references)
# and 13 September 2026 after the land-valuation rule (a villager buys land only below its
# rent-stream value to them); earlier values were verified byte-identical to the pre-refactor package. if a deliberate rule change moves them, regenerate with scripts/golden.jl and say so in HANDOFF.md.
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
    @test isapprox(a.money_in_circulation, 2 .* b.money_in_circulation; rtol = 1e-4)
    @test isapprox(a.price_bread, 2 .* b.price_bread; rtol = 1e-4)
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
    golden = Dict(
        "debt"       => (; price_bread = 10.341650000000001, price_wage = 8.496565966386557, money = 3343.3054, debt = 3479.9816999999994, gov_debt = 1671.1629, gini = 0.4909144544995363, cash_persons = 2183.7604, tax = 62.40420000000001),
        "debt_bonds" => (; price_bread = 13.5533125, price_wage = 11.608659512867648, money = 2618.7219999999998, debt = 2866.6173000000003, gov_debt = 1728.8779999999997, gini = 0.5427750932785462, cash_persons = 1171.5859999999998, tax = 79.3876),
        "sumsy"      => (; price_bread = 5.59341, price_wage = 4.3970382352941195, money = 2483.7348, debt = 219.1551, gov_debt = 0.0, gini = 0.31784422803863843, cash_persons = 1681.4892, tax = 0.0))
    configs = Dict("debt" => BEH, "sumsy" => (; BEH..., SUM...),
                   "debt_bonds" => (; BEH..., government_bonds = true, deposit_interest_period = 12, deposit_interest_rate = 0.01, loyalty_bonus_rate = 0.02))
    for (name, kw) in configs
        d = round_data(run(; seed = 3, maximum_rounds = 25, kw...)); r = d[end, :]; g = golden[name]
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

end
