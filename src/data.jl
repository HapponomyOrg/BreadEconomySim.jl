function gini(values)
    x = sort(max.(Float64.(values), 0.0)); n = length(x)
    n == 0 && return 0.0
    s = sum(x); s <= 0 && return 0.0
    return (2 * sum(i * x[i] for i in 1:n) / (n * s)) - (n + 1) / n
end

net_wealth(model, a::Agent) = cash(a) + a.land * land_price(model) - debt_of(a) - peer_debt_of(model, a) + peer_claims(model, a) + bond_holdings(model, a) +
                              (a isa Person ? share_wealth(model, a) : (a isa Enterprise && a.ownership != :none) ? -book_value(model, a) : 0.0) +
                              (a isa Person ? a.buffer_lent : 0.0) - (is_bank(a) ? a.buffer_received : 0.0) +

                              (is_bank(a) ? loans_held(a) - deposits_created(a) + a.retained_interest : 0.0)
group_of(a::Agent) = a isa Person ? (a.land > 0 ? :landowners : :workers) : a.kind
function group_wealth(model, g::Symbol)
    as = [a for a in alive_agents(model) if group_of(a) == g]
    return (length(as), sum(net_wealth(model, a) for a in as; init = 0.0), sum(cash(a) for a in as; init = 0.0), sum(a.land for a in as; init = 0))
end
mean_or_nan(x) = isempty(x) ? NaN : sum(x) / length(x)

function average_price(model, good::Symbol)
    t = model.transactions[good]
    isempty(t) && return NaN
    return sum(pr * u for (pr, u) in t) / sum(u for (_, u) in t)
end

function update_expected_prices!(model)
    p = parameters(model)
    old_bread = model.expected_prices[:bread]
    for g in GOODS
        avg = average_price(model, g)
        if !isnan(avg)
            model.expected_prices[g] = avg
        elseif p.expected_price_from_asks
            asks = [max(a.ask[g], seller_reservation(model, a, g)) for a in alive_agents(model) if g in sells(a)]
            isempty(asks) || (model.expected_prices[g] = sum(asks) / length(asks))
        end
    end
    if p.indexed_pricing && old_bread > 0
        factor = model.expected_prices[:bread] / old_bread
        if abs(factor - 1) > 1e-9
            for a in alive_agents(model), g in (:wage, :grain, :rent)
                haskey(a.ask, g) && (a.ask[g] *= factor)
                haskey(a.bid, g) && (a.bid[g] *= factor)
            end
            for g in (:wage, :grain, :rent)
                model.expected_prices[g] *= factor
            end
        end
    end
    return nothing
end

function record!(model)
    ps = persons(model); alive = alive_agents(model)
    banks = enterprises(model, :bank); gov = government(model)
    r = current_round(model)
    ev = @view model.events[model.event_start:end]
    row = (
        round = r,
        persons_alive = length(ps),
        farms_open = length(enterprises(model, :farm)),
        bakeries_open = length(enterprises(model, :bakery)),
        money_in_circulation = sum(cash(a) for a in alive; init = 0.0),
        money_in_dead_balances = sum(cash(a) for a in allagents(model) if !a.alive; init = 0.0),
        outstanding_debt = sum(debt_of(a) + peer_debt_of(model, a) for a in alive; init = 0.0),
        peer_lent = model.peer_lent_this_round,
        government_debt = debt_of(gov) + government_rest_interest(model) + bonds_outstanding(model) + government_trade_arrears(model), government_bank_debt = debt_of(gov) + government_rest_interest(model), bonds_outstanding = bonds_outstanding(model), government_arrears = government_trade_arrears(model),
        bonds_issued = model.bonds_issued_this_round, coupons = model.coupons_this_round, bond_rate = bond_coupon_rate(model),
        government_cash = cash(gov),
        bank_retained_interest = sum(b.retained_interest for b in banks; init = 0.0),
        cumulative_interest_paid = model.cumulative_interest_paid,
        cumulative_write_offs = model.cumulative_write_offs,
        cumulative_credit_refusals = model.cumulative_credit_refusals,
        money_created = model.money_created_this_round,
        money_destroyed = model.money_destroyed_this_round,
        credit_demand = model.credit_demand_this_round,
        tax = model.tax_this_round,
        enterprise_tax = model.enterprise_tax_this_round,
        deposit_interest = model.deposit_interest_this_round,
        buffer_pool = sum(b.buffer_received for b in banks; init = 0.0), insurance_premiums = sum(b.insurance_premiums for b in banks; init = 0.0),
        insurance_payouts = sum(b.insurance_payouts for b in banks; init = 0.0), missed_payments = count(e -> e.kind == :missed_payment, ev),
        cash_banks = sum(cash(b) for b in banks; init = 0.0),
        gi_created = model.gi_this_round, demurrage_destroyed = model.demurrage_this_round, demurrage_tax = model.demurrage_tax_this_round, account_fees = model.account_fees_this_round,
        fees = model.fees_this_round,
        trade_arrears = sum(pr.amount for pr in model.trade_arrears; init = 0.0),
        interest_rate = mean_or_nan([b.interest_rate for b in banks]),
        price_bread = average_price(model, :bread), price_grain = average_price(model, :grain), price_ticket = average_price(model, :ticket),
        price_rent = average_price(model, :rent), price_wage = average_price(model, :wage),
        wage_bid_producers = mean_or_nan([e.bid[:wage] for e in alive if is_producer(e)]),
        bread_baked = sum(get(e, :bread, 0.0) for e in ev if e.kind == :bake; init = 0.0),
        bread_sold = sum(t[2] for t in model.transactions[:bread]; init = 0.0),
        grain_harvested = sum(get(e, :grain, 0.0) for e in ev if e.kind == :harvest; init = 0.0),
        labour_offered = sum(w.labour_offered for w in ps; init = 0.0),
        labour_sold = sum(w.labour_sold for w in ps; init = 0.0),
        government_labour = sum(c.units for c in model.wage_contracts if c.stage == :government; init = 0.0),
        unemployed = count(unemployed, ps),
        hungry = count(a -> a.hunger > 0, ps),
        without_bread = count(a -> a.ate_this_round == :none, ps),
        half_meals = count(a -> a.ate_this_round == :half, ps),
        gluttons = count(a -> a.glutton, ps),
        bread_stocked = sum(bread_units(a) for a in ps; init = 0.0),
        total_capacity = sum(a.capacity for a in ps; init = 0.0),
        cash_persons = sum(cash(a) for a in ps; init = 0.0),
        cash_farms = sum(cash(a) for a in enterprises(model, :farm); init = 0.0),
        cash_bakeries = sum(cash(a) for a in enterprises(model, :bakery); init = 0.0),
        land_persons = sum(a.land for a in ps; init = 0), land_farms = sum(a.land for a in enterprises(model, :farm); init = 0),
        land_banks = sum(a.land for a in banks; init = 0),
        landholders = count(a -> a.land > 0, ps),
        gini_cash_persons = gini([cash(a) for a in ps]),
        gini_net_wealth_persons = gini([net_wealth(model, a) for a in ps]),
        gini_income_persons = gini([a.labour_income + a.rent_income + a.fee_received for a in ps]),
        persons_below_meal = count(a -> cash(a) < meal_price(model), ps),
        persons_income = sum(a.labour_income + a.rent_income + a.fee_received for a in ps; init = 0.0) + model.gi_this_round + model.deposit_interest_this_round - model.demurrage_persons_this_round,
        bread_bill = sum(t[1] * t[2] for t in model.transactions[:bread]; init = 0.0),
        gluttony_attempted = model.gluttony_attempted_this_round, gluttony_refused = model.gluttony_refused_this_round,
        tickets_sold = sum(t[2] for t in model.transactions[:ticket]; init = 0.0),
        n_greedy = count(w -> w.greed != :none, ps), hungry_greedy = count(w -> w.greed != :none && w.hunger > 0, ps), hungry_others = count(w -> w.greed == :none && w.hunger > 0, ps),
        cash_greedy = sum(cash(w) for w in ps if w.greed != :none; init = 0.0), land_greedy = sum(w.land for w in ps if w.greed != :none; init = 0),
        wealth_greedy = sum(net_wealth(model, w) for w in ps if w.greed != :none; init = 0.0), wealth_persons = sum(net_wealth(model, w) for w in ps; init = 0.0),
        bread_greedy = sum(bread_units(w) for w in ps if w.greed == :greedy; init = 0.0),
        greedy_loaves = model.greedy_loaves_this_round, greedy_tickets = model.greedy_tickets_this_round, ration = model.ration_this_round,
        tier_multiplier = mean_or_nan([e.tier_multiplier for e in alive if is_bakery(e)]), tier_sold = sum(e.tier_sold for e in alive if is_bakery(e); init = 0), tier_revenue = model.tier_revenue_this_round,
        n_consumers = count(w -> w.greed == :greedy, ps), n_hoarders = count(w -> w.greed == :greedy, ps),
        wealth_hoarders = sum(net_wealth(model, w) for w in ps if w.greed == :greedy; init = 0.0), land_hoarders = sum(w.land for w in ps if w.greed == :greedy; init = 0),
        shares_hoarders = sum(get(e.shares, w.id, 0.0) for e in alive if e isa Enterprise && e.ownership == :shareholders for w in ps if w.greed == :greedy; init = 0.0),
        greedy_land = model.greedy_land_this_round, greedy_shares = model.greedy_shares_this_round, ticket_revenue = sum(t[1] * t[2] for t in model.transactions[:ticket]; init = 0.0),
        theatre_labour = sum(e.hired_labour for e in alive if is_theatre(e); init = 0.0), cash_theatres = sum(cash(e) for e in alive if is_theatre(e); init = 0.0),
        theatres_open = count(is_theatre, alive),
        dividends = sum(e.dividend_history[end] for e in alive if e isa Enterprise && e.ownership != :none && !isempty(e.dividend_history); init = 0.0),
        dividend_income_persons = sum(w.dividend_income for w in ps; init = 0.0),
        share_price_mean = mean_or_nan([e.share_price for e in alive if e isa Enterprise && e.ownership == :shareholders && e.share_price > 0]),   # NaN until a share has traded
        share_units_per_firm = total_share_units(model), founders_stake_pct = mean_or_nan([100 * founders_stake(e) / total_share_units(model) for e in alive if e isa Enterprise && e.ownership == :shareholders]),
        book_per_unit_mean = mean_or_nan([book_per_unit(model, e) for e in alive if e isa Enterprise && e.ownership == :shareholders]),
        share_trades = count(x -> x.kind == :share_trade, ev), share_trades_deferred = count(x -> x.kind == :share_trade && get(x, :deferred, false) == true, ev),
        share_contracts_outstanding = sum(l.outstanding for l in model.peer_loans if !l.settled && haskey(model.share_collateral, l.id); init = 0.0),
        share_seizures = count(x -> x.kind == :seizure && get(x, :collateral, :land) == :shares, ev), share_volume = sum(x.units * x.price for x in ev if x.kind == :share_trade; init = 0.0),
        founders_stake_mean = mean_or_nan([founders_stake(e) for e in alive if e isa Enterprise && e.ownership == :shareholders]),
        outside_holders = length(unique(h for e in alive if e isa Enterprise && e.ownership == :shareholders for (h, u) in e.shares if u > 1e-6 && !(h in e.founder_ids))),
        forward_value_mean = mean_or_nan([forward_value_per_unit(model, e, parameters(model).required_yield) for e in alive if e isa Enterprise && e.ownership == :shareholders]),
        coop_open = count(e -> e isa Enterprise && e.ownership == :cooperative, alive), forprofit_open = count(e -> e isa Enterprise && e.ownership == :shareholders, alive),
        cash_coops = sum(cash(e) for e in alive if e isa Enterprise && e.ownership == :cooperative; init = 0.0),
        coop_members = sum(length(e.members) for e in alive if e isa Enterprise && e.ownership == :cooperative; init = 0),
        coop_capital = sum(e.paid_in_capital for e in alive if e isa Enterprise && e.ownership == :cooperative; init = 0.0),
        founder_capital = sum(e.paid_in_capital for e in alive if e isa Enterprise && e.ownership == :shareholders; init = 0.0),
        founder_debt = sum(debt_of(w) + peer_debt_of(model, w) for w in ps if any(e -> e isa Enterprise && e.ownership == :shareholders && haskey(e.shares, w.id), alive); init = 0.0),
        reserve_shortfall_owned = sum(max(reserve_target(model, e) - cash(e), 0.0) for e in alive if e isa Enterprise && e.ownership != :none; init = 0.0),
        reserve_shortfall_coops = sum(max(reserve_target(model, e) - cash(e), 0.0) for e in alive if e isa Enterprise && e.ownership == :cooperative; init = 0.0),
        reserve_shortfall_forprofit = sum(max(reserve_target(model, e) - cash(e), 0.0) for e in alive if e isa Enterprise && e.ownership == :shareholders; init = 0.0),
        dividends_coops = sum(e.dividend_history[end] for e in alive if e isa Enterprise && e.ownership == :cooperative && !isempty(e.dividend_history); init = 0.0),
        dividends_forprofit = sum(e.dividend_history[end] for e in alive if e isa Enterprise && e.ownership == :shareholders && !isempty(e.dividend_history); init = 0.0),
        founders_cash = sum(cash(w) for w in ps if any(e -> e isa Enterprise && e.ownership == :shareholders && haskey(e.shares, w.id), alive); init = 0.0), cash_forprofit = sum(cash(e) for e in alive if e isa Enterprise && e.ownership == :shareholders; init = 0.0),
        gini_net_wealth_all = gini([net_wealth(model, a) for a in alive if !is_government(a) && !is_authority(a)]),
        n_workers = group_wealth(model, :workers)[1], wealth_workers = group_wealth(model, :workers)[2],
        n_landowners = group_wealth(model, :landowners)[1], wealth_landowners = group_wealth(model, :landowners)[2],
        n_farms = group_wealth(model, :farm)[1], wealth_farms = group_wealth(model, :farm)[2],
        n_bakeries = group_wealth(model, :bakery)[1], wealth_bakeries = group_wealth(model, :bakery)[2],
        n_banks = group_wealth(model, :bank)[1], wealth_banks = group_wealth(model, :bank)[2],
        wealth_government = group_wealth(model, :government)[2],
        land_price = land_price(model),
        deaths = count(a -> a isa Person && !a.alive && a.death_round == r, allagents(model)),
        closures = model.closures,
        production_target_farms = sum(a.production_target for a in enterprises(model, :farm); init = 0),
        production_target_bakeries = sum(a.production_target for a in enterprises(model, :bakery); init = 0),
    )
    push!(model.data, row)
    return nothing
end

function check_termination!(model)
    p = parameters(model); d = model.data; row = d[end]
    if p.stop_when_half_dead && row.persons_alive <= model.initial_person_count / 2
        model.finished = true; model.termination_reason = "half of the persons are dead"; return true
    end
    if row.persons_alive == 0
        model.finished = true; model.termination_reason = "everyone is dead"; return true
    end
    if row.farms_open == 0 || row.bakeries_open == 0
        model.finished = true; model.termination_reason = "no farm or no bakery left"; return true
    end
    if row.round >= p.maximum_rounds
        model.finished = true; model.termination_reason = "maximum rounds reached"; return true
    end
    stationary = false
    if length(d) >= 2
        prev = d[end - 1]
        rel(a, b) = (isnan(a) || isnan(b)) ? 0.0 : abs(a - b) / max(abs(b), 1e-9)
        stationary = row.hungry == 0 &&
            rel(row.money_in_circulation, prev.money_in_circulation) < p.stationary_tolerance &&
            rel(row.outstanding_debt, prev.outstanding_debt) < p.stationary_tolerance &&
            all(rel(getproperty(row, k), getproperty(prev, k)) < p.stationary_tolerance for k in (:price_bread, :price_grain, :price_rent, :price_wage))
    end
    model.stationary_counter = stationary ? model.stationary_counter + 1 : 0
    if p.stop_when_stationary && model.stationary_counter >= p.stationary_rounds
        model.finished = true; model.termination_reason = "stationary for $(p.stationary_rounds) rounds"; return true
    end
    return false
end

function record_and_adapt!(model)
    record!(model)
    adapt_prices!(model)
    adapt_targets!(model)
    absorb_surplus!(model)
    update_expected_prices!(model)
    model.credit_demand_previous_round = model.credit_demand_this_round
    check_termination!(model)
    return nothing
end

function run_simulation!(model)
    while !model.finished
        econo_step!(model, 1)
    end
    return model
end
run_simulation(parameters::SimulationParameters = SimulationParameters()) = run_simulation!(create_bread_economy(parameters))

round_data(model) = DataFrame(model.data)

function event_log(model)
    ks = Symbol[]
    for e in model.events, k in keys(e)
        k in ks || push!(ks, k)
    end
    return DataFrame([k => Any[get(e, k, missing) for e in model.events] for k in ks])
end

function agent_end_state(model)
    rows = [(id = a.id, kind = kind_of(a), alive = a.alive, cash = cash(a), debt = debt_of(a), land = a.land, net_wealth = net_wealth(model, a),
             capacity = a isa Person ? a.capacity : NaN, hunger = a isa Person ? a.hunger : 0,
             production_target = a isa Enterprise ? a.production_target : 0, interest_rate = a isa Enterprise ? a.interest_rate : NaN,
             retained_interest = a isa Enterprise ? a.retained_interest : NaN,
             ask_wage = get(a.ask, :wage, NaN), bid_wage = get(a.bid, :wage, NaN), ask_bread = get(a.ask, :bread, NaN), ask_grain = get(a.ask, :grain, NaN), ask_rent = get(a.ask, :rent, NaN))
            for a in sort(collect(allagents(model)); by = a -> a.id)]
    return DataFrame(rows)
end

government_rest_interest(model) = sum(Float64(l.debt.rest_interest) for l in debtor_loans(model, government(model)); init = 0.0)
government_trade_arrears(model) = sum(pr.amount for pr in model.promises if pr.from_id == government(model).id && pr.priority == 0; init = 0.0)

"""Σ deposit assets − Σ bank deposit liabilities + money lost (should be 0)."""
function money_identity_gap(model)
    assets = sum(cash(a) for a in allagents(model); init = 0.0)
    liabilities = sum(deposits_created(a) for a in allagents(model); init = 0.0)
    return assets - liabilities + model.cumulative_money_lost
end
